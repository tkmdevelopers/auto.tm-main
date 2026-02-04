import { Banners } from "./banners.entity";

export const BannersProvider = [
  {
    provide: "BANNERS_REPOSITORY",
    useValue: Banners,
  },
];
