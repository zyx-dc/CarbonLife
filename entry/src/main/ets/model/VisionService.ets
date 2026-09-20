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

export class VisionService {
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
      fs.closeSync(file);
      file = null;

      const detector = await objectDetection.ObjectDetector.create();
      const req = new visionBase.Request();
      const imgData: visionBase.ImageData = { pixelMap: pixelMap };
      req.inputData = imgData;
      const resp = await detector.process(req);

      let bestLabel = -1;
      let bestScore = 0;
      resp.objects.forEach((o: objectDetection.VisionObject) => {
        if (o.score > bestScore && o.labels.length > 0) {
          bestScore = o.score;
          bestLabel = o.labels[0];
        }
      });
      return VisionService.mapLabel(bestLabel, bestScore);
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

  static mapLabel(label: number, score: number): VisionResult {
    if (label === 11 || label === 6) {
      return { ok: true, label: '食物 / 餐桌', behaviorKey: 'clean_plate', score: score, message: '识别到食物，建议记录「光盘行动」' };
    }
    if (label === 12) {
      return { ok: true, label: '车辆', behaviorKey: 'bus', score: score, message: '识别到车辆，建议记录「公交替代驾车」' };
    }
    if (label === 13 || label === 8 || label === 5) {
      return { ok: true, label: '人物', behaviorKey: 'walk', score: score, message: '识别到人物，建议记录「步行替代驾车」' };
    }
    if (label === 2) {
      return { ok: true, label: '植物', behaviorKey: 'veg_meal', score: score, message: '识别到植物，建议记录「素食一餐」' };
    }
    if (label === 22 || label === 21 || label === 7) {
      return { ok: true, label: '卡片 / 文档', behaviorKey: 'recycle_paper', score: score, message: '识别到纸张类，建议记录「回收纸张」' };
    }
    return { ok: false, label: '', behaviorKey: '', score: score, message: '未识别到匹配场景，请手动选择行为' };
  }
}
