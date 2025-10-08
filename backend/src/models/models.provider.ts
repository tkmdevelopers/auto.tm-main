import { Models } from './models.entity';

export const modelsProvider = [
  {
    provide: 'MODELS_REPOSITORY',
    useValue: Models,
  },
];
