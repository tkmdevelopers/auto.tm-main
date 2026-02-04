import { Brands } from "./brands.entity";

export const brandsProvider = [
  {
    provide: "BRANDS_REPOSITORY",
    useValue: Brands,
  },
];
