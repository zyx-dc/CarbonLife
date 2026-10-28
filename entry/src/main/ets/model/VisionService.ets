import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { objectDetection, visionBase } from '@kit.CoreVisionKit';
import { camera, cameraPicker } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export interface VisionResult {
  ok: boolean;
  label: string;
  behaviorKey: string;
  score: number;
  message: ResourceStr;
  /** 失败时的原始错误码/描述，仅用于日志与排查，不展示给用户 */
  detail: string;
}

interface LabelMapping {
  labels: number[];
  name: string;
  behaviorKey: string;
  message: ResourceStr;
}

const DOMAIN: number = 0x0C05;
const TAG: string = 'VisionService';

/**
 * 端侧识图：两条入口，一条识别链路。
 *
 * - 拍照：走系统相机 `cameraPicker.pick()`，由系统相机应用代拍，
 *   **不需要 CAMERA 权限**，也不需要运行时授权。
 * - 相册：走系统选择器 `PhotoViewPicker`，同样不需要读相册权限。
 *
 * 两条入口拿到的都是图片 URI，之后统一进 `detectUri()`：
 * 打开文件 → 解码为 PixelMap → Core Vision Kit 物体检测 → 标签映射成低碳行为。
 * 识别只做「推荐」，真正写账仍由用户确认，避免误判污染数据。
 */
export class VisionService {
  // 低于该置信度的检测结果不参与推荐，避免误判
  private static readonly MIN_SCORE: number = 0.45;

  // 检测模型标签索引 → 低碳行为映射表（集中维护，便于扩展）。
  // 需要覆盖更多场景时，只需在此追加一条 {labels, name, behaviorKey, message}，
  // 判定逻辑无需改动；未命中的情况一律回退为「手动选择」。
  private static readonly LABEL_MAP: LabelMapping[] = [
    { labels: [11, 6], name: '食物 / 餐桌', behaviorKey: 'clean_plate', message: $r('app.string.vision_food') },
    { labels: [12], name: '车辆', behaviorKey: 'bus', message: $r('app.string.vision_vehicle') },
    { labels: [13, 8, 5], name: '人物', behaviorKey: 'walk', message: $r('app.string.vision_person') },
    { labels: [2], name: '植物', behaviorKey: 'veg_meal', message: $r('app.string.vision_plant') },
    { labels: [22, 21, 7], name: '纸张 / 文档', behaviorKey: 'recycle_paper', message: $r('app.string.vision_paper') }
  ];

  /** 相册入口 */
  static async pickAndDetect(): Promise<VisionResult> {
    let picker: photoAccessHelper.PhotoViewPicker | null = null;
    try {
      picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picked = await picker.select(options);
      if (picked.photoUris.length === 0) {
        return VisionService.fail($r('app.string.vision_cancelled'), 'album:no-uri');
      }
      return await VisionService.detectUri(picked.photoUris[0]);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, 'album picker failed: code=%{public}d msg=%{public}s',
        err.code ?? -1, err.message ?? '');
      return VisionService.fail($r('app.string.vision_pick_failed'), `album:${err.code ?? -1}`);
    }
  }

  /** 拍照入口（系统相机代拍，无需 CAMERA 权限） */
  static async captureAndDetect(ctx: common.Context): Promise<VisionResult> {
    try {
      const profile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      const res: cameraPicker.PickerResult = await cameraPicker.pick(
        ctx, [cameraPicker.PickerMediaType.PHOTO], profile);
      // resultCode: 0 成功，-1 失败/取消
      if (res.resultCode !== 0 || res.resultUri === undefined || res.resultUri === '') {
        return VisionService.fail($r('app.string.vision_cancelled'), `camera:result=${res.resultCode}`);
      }
      return await VisionService.detectUri(res.resultUri);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, 'camera picker failed: code=%{public}d msg=%{public}s',
        err.code ?? -1, err.message ?? '');
      return VisionService.fail($r('app.string.vision_camera_failed'), `camera:${err.code ?? -1}`);
    }
  }

  /** 统一识别链路：URI → PixelMap → 物体检测 → 行为推荐 */
  private static async detectUri(uri: string): Promise<VisionResult> {
    let file: fs.File | null = null;
    let source: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;
    let detector: objectDetection.ObjectDetector | null = null;
    let step: string = 'open';
    try {
      hilog.info(DOMAIN, TAG, 'detect start, uri=%{public}s', uri);
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      step = 'decode';
      source = image.createImageSource(file.fd);
      pixelMap = await source.createPixelMap();
      const info: image.ImageInfo = await source.getImageInfo();
      hilog.info(DOMAIN, TAG, 'decoded %{public}dx%{public}d fmt=%{public}d',
        info.size.width, info.size.height, info.pixelFormat);

      step = 'detector-create';
      detector = await objectDetection.ObjectDetector.create();
      step = 'process';
      // 注意：visionBase.Request 在 d.ts 里声明为 class，但运行时没有构造函数，
      // 用 new 会抛 TypeError: Constructor is false。官方样例用的是对象字面量。
      const req: visionBase.Request = {
        inputData: { pixelMap: pixelMap }
      };
      const resp = await detector.process(req);
      hilog.info(DOMAIN, TAG, 'objects=%{public}d', resp.objects.length);
      return VisionService.mapObjects(resp.objects);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, 'detect failed at %{public}s: code=%{public}d msg=%{public}s',
        step, err.code ?? -1, err.message ?? String(e));
      return VisionService.fail($r('app.string.vision_failed'),
        `detect:${step}:${err.code ?? -1}`);
    } finally {
      // 统一释放，失败路径也不泄漏：检测器进程 / 像素图 / 图片源 / 文件句柄
      if (detector !== null) {
        try {
          await detector.destroy();
        } catch (e) {
        }
      }
      if (pixelMap !== null) {
        try {
          pixelMap.release();
        } catch (e) {
        }
      }
      if (source !== null) {
        try {
          source.release();
        } catch (e) {
        }
      }
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch (e) {
        }
      }
    }
  }

  private static fail(message: ResourceStr, detail: string): VisionResult {
    return { ok: false, label: '', behaviorKey: '', score: 0, message: message, detail: detail };
  }

  // 遍历全部检测结果，返回第一个「置信度达标且命中映射表」的推荐
  private static mapObjects(objects: objectDetection.VisionObject[]): VisionResult {
    for (let i = 0; i < objects.length; i++) {
      const o = objects[i];
      if (o.score < VisionService.MIN_SCORE || o.labels.length === 0) {
        continue;
      }
      const mapped = VisionService.mapLabels(o.labels, o.score);
      if (mapped.ok) {
        return mapped;
      }
    }
    return VisionService.fail($r('app.string.vision_no_match'), 'map:no-match');
  }

  // 在候选标签中查找第一个可映射的行为
  static mapLabels(labels: number[], score: number): VisionResult {
    for (let i = 0; i < labels.length; i++) {
      const r = VisionService.mapLabel(labels[i], score);
      if (r.ok) {
        return r;
      }
    }
    return VisionService.fail($r('app.string.vision_no_match'), 'map:no-match');
  }

  static mapLabel(label: number, score: number): VisionResult {
    for (let i = 0; i < VisionService.LABEL_MAP.length; i++) {
      const m = VisionService.LABEL_MAP[i];
      if (m.labels.indexOf(label) >= 0) {
        return {
          ok: true, label: m.name, behaviorKey: m.behaviorKey,
          score: score, message: m.message, detail: ''
        };
      }
    }
    return VisionService.fail($r('app.string.vision_no_match'), 'map:no-match');
  }
}
