import { Comments } from "./comments.entity";

export const commentsProvider = [
  {
    provide: "COMMENTS_REPOSITORY",
    useValue: Comments,
  },
];
