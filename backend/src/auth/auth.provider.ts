import { User } from "./auth.entity";

export const authsProvider = [
  {
    provide: "USERS_REPOSITORY",
    useValue: User,
  },
];
