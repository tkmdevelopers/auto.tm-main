import { Video } from "./video.entity";

export const VideoProvider = [
  {
    provide: "VIDEO_REPOSITORY",
    useValue: Video,
  },
];
