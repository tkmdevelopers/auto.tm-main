import { Vlogs } from "./vlog.entity";

export const VlogProvider = [
  {
    provide: "VLOG_REPOSITORY",
    useValue: Vlogs,
  },
];
