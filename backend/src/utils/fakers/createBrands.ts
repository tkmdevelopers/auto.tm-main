import { faker } from "@faker-js/faker";

export function createRandomBrands() {
  return {
    uuid: faker.string.uuid(),
    name: faker.vehicle.manufacturer(),
  };
}
