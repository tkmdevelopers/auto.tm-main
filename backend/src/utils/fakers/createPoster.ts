import { faker } from "@faker-js/faker";
import { min } from "rxjs";

enum brandsId  {
    a = "0496bc79-e48d-4aa8-b236-5030f8005986",
    b = "12382d88-f66f-48dc-ba03-7ff634fc3b4d",
    c = "538b8d34-054b-4760-9d7a-26597454f2f6",
    d = "58922d7d-b075-4f25-9eef-b830dfde830b",
    e = "5a35d010-8cf4-479b-b924-fa841a20dff0",
    f = "5c08a46b-85f9-4989-acc5-499f18df3207",
    g = "6c060217-d532-4a0e-8319-1a17229fa1cd",
    h = "8bfee884-1561-4645-bc10-e9797439a257",
    i = "8e1948ea-bbd7-44ee-9b31-2c1e216e79ff",
}
enum modelId  {
    a = "0f7a5b2c-fede-48d0-874d-1a84a0f860d8",
    b = "4272c1af-1dad-4eba-b6be-c274a0d89d0a",
    c = "4db82b76-896c-4b4b-b6d2-c11996a65158",
    d = "7770cf25-7b98-4604-a451-cf1637dfc87c",
    e = "9a271ead-c294-41bd-b206-5f0b9c01b1de",
    f = "ba3fb69c-5c82-4a15-9ab6-de51c77c34b2",
    g = "c2b02b49-cc8b-4b01-b763-22abb6d723d6",
    h = "c8e8d5f2-dabd-4a74-83b8-1fe9be75a280",
}
enum condition {
  BRAND_NEW = "New",
  USED = "Used",
}
enum engineType {
  DIESEL = "Diesel",
  PETROL = "Petrol",
  HYBRID = "Hybrid",
}
enum transmission {
  AUTO = "Auto",
  MANUAL = "Manual",
  AUTOMATED_MANUAL = "Automated Manual",
}
enum currency {
  USD = "USD",
  TMT = "TMT",
  AED = "AED",
  CNY = "CNY",
}
export function createRandomPoster() {
  let date = faker.date.birthdate({ max: 20, min: 1, mode: "age" });

  return {
    uuid: faker.string.uuid(),
    brandsId: faker.helpers.enumValue(brandsId),
    modelsId: faker.helpers.enumValue(modelId), 
    condition: faker.helpers.enumValue(condition),
    engineType: faker.helpers.enumValue(engineType),
    transmission: faker.helpers.enumValue(transmission),
    enginePower: faker.number.int({ min: 0, max: 1500 }),
    year: date.getFullYear(),
    milleage: faker.number.int({ min: 0, max: 1500 }),
    vin: faker.vehicle.vin(),
    price: faker.number.int({ min: 0, max: 1500 }),
    currency: faker.helpers.enumValue(currency),
    personalInfo: {
      name: faker.person.fullName(),
      location: faker.location.country(),
      region: 'Local',
    },
    description: faker.lorem.sentence({min:3,max:10}),
  };
}
