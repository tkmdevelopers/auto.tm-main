import { Posts } from "./post.entity";

export const postsProvider = [
  {
    provide: "POSTS_REPOSITORY",
    useValue: Posts,
  },
];
