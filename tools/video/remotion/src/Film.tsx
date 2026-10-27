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
  if (size >= 72) return `${-0.015}em`;
  if (size >= 34) return "0em";
  if (size >= 20) return "0.012em";
  return "-0.01em";
};

const Ground: React.FC<{ kind: "light" | "dark" }> = ({ kind }) => (
  <AbsoluteFill
    style={{
      background:
        kind === "light"
          ? "radial-gradient(120% 90% at 50% 42%, #FFFFFF 0%, #F3F3F5 58%, #E9E9EC 100%)"
          : "radial-gradient(120% 90% at 50% 46%, #1B2A10 0%, #0C1108 55%, #050704 100%)",
    }}
  />
);

/**
 * 亚像素运镜：所有坐标都是浮点，交给浏览器合成——不会像 zoompan 那样
 * 每帧取整抖动。box 决定可用画布，便于暗场里做"内缩面板"。
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
            borderRadius: height * 0.042,
            overflow: "hidden",
            transform: `translateX(${dx}px) scale(${scale})`,
            boxShadow:
              ground === "light"
                ? "0 34px 70px rgba(16,24,10,0.20), 0 6px 18px rgba(16,24,10,0.10), 0 0 0 1px rgba(16,24,10,0.06)"
                : "0 40px 90px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.10)",
          }}
        >
          <Img
            src={staticFile(`shots/${shot.asset}`)}
            style={{ width: "100%", height: "100%", objectFit: "cover" }}
          />
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
