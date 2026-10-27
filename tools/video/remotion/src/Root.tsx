import React from "react";
import { Composition } from "remotion";
import { CarbonLife } from "./Film";
import { FPS, H, W } from "./theme";
import { totalFrames } from "./shots";

export const Root: React.FC = () => (
  <Composition
    id="CarbonLife"
    component={CarbonLife}
    durationInFrames={totalFrames}
    fps={FPS}
    width={W}
    height={H}
  />
);
