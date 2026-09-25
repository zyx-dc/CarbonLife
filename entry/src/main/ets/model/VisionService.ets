import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { objectDetection, visionBase } from '@kit.CoreVisionKit';

export interface VisionResult {
  ok: boolean;
  label: string;
  behaviorKey: string;
  score: number;
  message: string;
}

interface LabelMapping {
  labels: number[];
  name: string;
  behaviorKey: string;
  message: string;
}

export class VisionService {
  // 低于该置信度的检测结果不参与推荐，避免误判
  private static readonly MIN_SCORE: number = 0.45;

  // 检测模型标签索引 → 低碳行为映射表（集中维护，便于扩展）。
  // 需要覆盖更多场景时，只需在此追加一条 {labels, name, behaviorKey, message}，
  // 判定逻辑无需改动；未命中的情况一律回退为「手动选择」。
  private static readonly LABEL_MAP: LabelMapping[] = [
    { labels: [11, 6], name: '食物 / 餐桌', behaviorKey: 'clean_plate', message: '识别到食物，建议记录「光盘行动」' },
    { labels: [12], name: '车辆', behaviorKey: 'bus', message: '识别到车辆，建议记录「公交替代驾车」' },
    { labels: [13, 8, 5], name: '人物', behaviorKey: 'walk', message: '识别到人物，建议记录「步行替代驾车」' },
    { labels: [2], name: '植物', behaviorKey: 'veg_meal', message: '识别到植物，建议记录「素食一餐」' },
    { labels: [22, 21, 7], name: '纸张 / 文档', behaviorKey: 'recycle_paper', message: '识别到纸张类，建议记录「回收纸张」' }
  ];

  static async pickAndDetect(): Promise<VisionResult> {
    let file: fs.File | null = null;
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picked = await picker.select(options);
      if (picked.photoUris.length === 0) {
        return { ok: false, label: '', behaviorKey: '', score: 0, message: '未选择图片' };
      }
      const uri = picked.photoUris[0];
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const source = image.createImageSource(file.fd);
      const pixelMap = await source.createPixelMap();

      const detector = await objectDetection.ObjectDetector.create();
      const req = new visionBase.Request();
      const imgData: visionBase.ImageData = { pixelMap: pixelMap };
      req.inputData = imgData;
      const resp = await detector.process(req);

      // 解码完成后再释放 fd，避免个别机型在识别阶段仍依赖文件句柄
      fs.closeSync(file);
      file = null;

      const result = VisionService.mapObjects(resp.objects);
      pixelMap.release();
      return result;
    } catch (e) {
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch (err) {
        }
      }
      return { ok: false, label: '', behaviorKey: '', score: 0, message: '识别失败，请手动选择行为' };
    }
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
    return { ok: false, label: '', behaviorKey: '', score: 0, message: '未识别到匹配场景，请手动选择行为' };
  }

  // 在候选标签中查找第一个可映射的行为
  static mapLabels(labels: number[], score: number): VisionResult {
    for (let i = 0; i < labels.length; i++) {
      const r = VisionService.mapLabel(labels[i], score);
      if (r.ok) {
        return r;
      }
    }
    return { ok: false, label: '', behaviorKey: '', score: score, message: '未识别到匹配场景，请手动选择行为' };
  }

  static mapLabel(label: number, score: number): VisionResult {
    for (let i = 0; i < VisionService.LABEL_MAP.length; i++) {
      const m = VisionService.LABEL_MAP[i];
      if (m.labels.indexOf(label) >= 0) {
        return { ok: true, label: m.name, behaviorKey: m.behaviorKey, score: score, message: m.message };
      }
    }
    return { ok: false, label: '', behaviorKey: '', score: score, message: '未识别到匹配场景，请手动选择行为' };
  }
}
