import { User } from "../../src/auth/auth.entity";
import { v4 as uuidv4 } from "uuid";
import { faker } from "@faker-js/faker";

export class UserFactory {
  static async create(overrides: Partial<User> = {}): Promise<User> {
    return User.create({
      uuid: uuidv4(),
      phone: overrides.phone || `+9936${faker.string.numeric(7)}`,
      name: overrides.name || faker.person.fullName(),
      email: overrides.email || faker.internet.email(),
      role: overrides.role || "user",
      status: overrides.status ?? true,
      refreshTokenHash: overrides.refreshTokenHash || null,
      ...overrides,
    } as any);
  }
}
