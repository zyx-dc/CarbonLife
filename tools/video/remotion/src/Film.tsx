import React from "react";
import {
  AbsoluteFill,
  Img,
  Sequence,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { Shot, SHOTS, Vec3 } from "./shots";
import {
  DARK, EASE_IO, EASE_OUT, FONT_FAMILY, H, INK, INK_SUB, LIGHT, LIME,
  PAPER, PAPER_SUB, W,
} from "./theme";

const SRC_W = 1320;
const SRC_H = 2232;

/** 字距随字号变化：大字收紧、小字放开 */
const tracking = (size: number): string => {
  if (size >= 72) return "-0.015em";
  if (size >= 34) return "0em";
  if (size >= 20) return "0.012em";
  return "-0.01em";
};

const Ground: React.FC<{ kind: "light" | "dark" }> = ({ kind }) => (
  <AbsoluteFill
    style={{
      background:
        kind === "light"
          ? "radial-gradient(120% 90% at 50% 42%, #F6F6F8 0%, #E9E9EC 58%, #DFDFE3 100%)"
          : "radial-gradient(120% 90% at 50% 46%, #1B2A10 0%, #0C1108 55%, #050704 100%)",
    }}
  />
);

/**
 * 亚像素运镜：坐标全是浮点，交给浏览器合成。
 * （之前的 zoompan 每帧位移不足一像素、取整后就是"一格一格"的抖动）
 */
const Crop: React.FC<{
  asset: string;
  a: Vec3;
  b: Vec3;
  dur: number;
  boxW: number;
  boxH: number;
}> = ({ asset, a, b, dur, boxW, boxH }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [0, Math.max(1, dur - 1)], [0, 1], {
    easing: EASE_IO,
    extrapolateRight: "clamp",
  });

  const cx = a[0] + (b[0] - a[0]) * t;
  const cy = a[1] + (b[1] - a[1]) * t;
  const cw = a[2] + (b[2] - a[2]) * t;
  const scale = boxW / cw;

  return (
    <Img
      src={staticFile(`shots/${asset}`)}
      style={{
        position: "absolute",
        width: SRC_W * scale,
        height: SRC_H * scale,
        left: boxW / 2 - cx * scale,
        top: boxH / 2 - cy * scale,
        maxWidth: "none",
      }}
    />
  );
};

const Caption: React.FC<{ text?: string; kind: "light" | "dark" }> = ({ text, kind }) => {
  const frame = useCurrentFrame();
  if (!text) return null;
  const p = interpolate(frame, [1, 15], [0, 1], {
    easing: EASE_OUT,
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: H * 0.945,
        textAlign: "center",
        fontFamily: FONT_FAMILY,
        fontSize: 23,
        fontWeight: 400,
        letterSpacing: tracking(23),
        color: kind === "light" ? INK_SUB : PAPER_SUB,
        opacity: p,
        transform: `translateY(${(1 - p) * 6}px)`,
      }}
    >
      {text}
    </div>
  );
};

/** 点击指示：青柠圆环，两轮扩散。位置按源图像素百分比落在手机图内。 */
const TapRing: React.FC<{ x: number; y: number; dur: number }> = ({ x, y, dur }) => {
  const frame = useCurrentFrame();
  const t = (frame - 10) / (dur * 0.5);
  if (t < 0 || t >= 2) return null;
  const pulse = t % 1;
  return (
    <div
      style={{
        position: "absolute",
        left: `${(x / SRC_W) * 100}%`,
        top: `${(y / SRC_H) * 100}%`,
        width: 64,
        height: 64,
        marginLeft: -32,
        marginTop: -32,
        borderRadius: 64,
        border: "3px solid #B6FF2E",
        boxShadow: "0 0 0 1px rgba(182,255,46,0.35), 0 0 26px rgba(182,255,46,0.6)",
        transform: `scale(${0.55 + pulse * 1.05})`,
        opacity: (1 - pulse) * 0.92,
      }}
    />
  );
};

const CloseShot: React.FC<{ shot: Extract<Shot, { kind: "close" }>; dur: number }> = ({
  shot, dur,
}) => {
  const ground = shot.ground ?? "light";
  const inset = shot.inset ?? false;
  const boxW = inset ? W * 0.815 : W;
  const boxH = inset ? H * 0.815 : H;

  return (
    <AbsoluteFill style={{ backgroundColor: ground === "light" ? LIGHT : DARK }}>
      <Ground kind={ground} />
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
        <div
          style={{
            width: boxW,
            height: boxH,
            position: "relative",
            overflow: "hidden",
            borderRadius: inset ? 20 : 0,
            boxShadow: inset
              ? "0 40px 90px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.07)"
              : undefined,
          }}
        >
          <Crop asset={shot.asset} a={shot.a} b={shot.b ?? shot.a} dur={dur}
                boxW={boxW} boxH={boxH} />
        </div>
      </AbsoluteFill>
      <Caption text={shot.caption} kind={ground} />
    </AbsoluteFill>
  );
};

const PhoneShot: React.FC<{ shot: Extract<Shot, { kind: "phone" }>; dur: number }> = ({
  shot, dur,
}) => {
  const frame = useCurrentFrame();
  const ground = shot.ground ?? "light";
  const height = shot.height ?? 720;
  const width = (SRC_W / SRC_H) * height;
  const drift = shot.drift ?? 0.02;
  const t = interpolate(frame, [0, Math.max(1, dur - 1)], [0, 1], {
    easing: EASE_IO,
    extrapolateRight: "clamp",
  });
  const scale = 1 + drift * t;
  const dx = (shot.dx ?? 0) * W;

  return (
    <AbsoluteFill style={{ backgroundColor: ground === "light" ? LIGHT : DARK }}>
      <Ground kind={ground} />
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
        <div
          style={{
            width,
            height,
            position: "relative",
            borderRadius: height * 0.042,
            overflow: "hidden",
            transform: `translateX(${dx}px) scale(${scale})`,
            boxShadow:
              ground === "light"
                ? "0 30px 60px rgba(16,24,10,0.22), 0 6px 16px rgba(16,24,10,0.12), 0 0 0 1px rgba(16,24,10,0.07)"
                : "0 40px 90px rgba(0,0,0,0.65), 0 0 0 1px rgba(255,255,255,0.10)",
          }}
        >
          <Img
            src={staticFile(`shots/${shot.asset}`)}
            style={{ width: "100%", height: "100%", objectFit: "cover" }}
          />
          {shot.tap ? <TapRing x={shot.tap[0]} y={shot.tap[1]} dur={dur} /> : null}
        </div>
      </AbsoluteFill>
      <Caption text={shot.caption} kind={ground} />
    </AbsoluteFill>
  );
};

const CardShot: React.FC<{ shot: Extract<Shot, { kind: "card" }> }> = ({ shot }) => {
  const frame = useCurrentFrame();
  const ground = shot.ground ?? "light";
  const p = interpolate(frame, [0, 30], [0, 1], {
    easing: EASE_OUT,
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ backgroundColor: ground === "light" ? LIGHT : DARK }}>
      <Ground kind={ground} />
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          flexDirection: "column",
          gap: 10,
          opacity: p,
          transform: `translateY(${(1 - p) * 20}px) scale(${0.985 + 0.015 * p})`,
          fontFamily: FONT_FAMILY,
        }}
      >
        {shot.lines.map((l, i) => (
          <div
            key={i}
            style={{
              fontSize: l.size,
              fontWeight: l.weight,
              letterSpacing: tracking(l.size),
              color: l.lime ? LIME : ground === "light" ? INK : PAPER,
              lineHeight: 1.05,
            }}
          >
            {l.text}
          </div>
        ))}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const CarbonLife: React.FC = () => {
  let from = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: LIGHT }}>
      <style>{`
        @font-face {
          font-family: 'CarbonSans';
          src: url('${staticFile("fonts/NotoSansSC-VF.ttf")}') format('truetype');
          font-weight: 100 900;
          font-display: block;
        }
      `}</style>
      {SHOTS.map((shot, i) => {
        const dur = shot.beats * 30;
        const node = (
          <Sequence key={i} from={from} durationInFrames={dur}>
            {shot.kind === "close" ? (
              <CloseShot shot={shot} dur={dur} />
            ) : shot.kind === "phone" ? (
              <PhoneShot shot={shot} dur={dur} />
            ) : (
              <CardShot shot={shot} />
            )}
          </Sequence>
        );
        from += dur;
        return node;
      })}
    </AbsoluteFill>
  );
};
