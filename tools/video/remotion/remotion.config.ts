import { Config } from "@remotion/cli/config";

// 60fps：帧数高一倍，"低帧"的观感直接消失
Config.setVideoImageFormat("jpeg");
Config.setConcurrency(4);
Config.setChromiumOpenGlRenderer("angle");
