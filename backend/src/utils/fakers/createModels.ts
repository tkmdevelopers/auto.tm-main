import { faker } from '@faker-js/faker';

export function createRandomModels() {
  return {
    uuid: faker.string.uuid(),
    name: faker.vehicle.model(),
  };
}
