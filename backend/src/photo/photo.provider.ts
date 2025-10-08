import { Photo } from './photo.entity';

export const PhotoProvider = [
  {
    provide: 'PHOTO_REPOSITORY',
    useValue: Photo,
  },
];
