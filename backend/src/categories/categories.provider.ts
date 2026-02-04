import { Categories } from "./categories.entity";

export const CategoriesProvider = [
  {
    provide: "CATEGORIES_REPOSITORY",
    useValue: Categories,
  },
];
