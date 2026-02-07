import { Test, TestingModule } from "@nestjs/testing";
import { INestApplication } from "@nestjs/common";
import * as request from "supertest";
import { App } from "supertest/types";
import { AppModule } from "./../src/app.module";
import { AuthGuard } from "../src/guards/auth.guard"; // Import AuthGuard
import { Sequelize } from "sequelize-typescript";

describe("AppController (e2e)", () => {
  let app: INestApplication<App>;
  let moduleFixture: TestingModule; // Declare moduleFixture here

  beforeEach(async () => {
    moduleFixture = await Test.createTestingModule({ // Assign to moduleFixture
      imports: [AppModule],
    })
    .overrideGuard(AuthGuard) // Override the AuthGuard
    .useValue({ canActivate: () => true }) // Provide a mock implementation
    .compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
    // Close the Sequelize connection
    const sequelize = moduleFixture.get<Sequelize>("SEQUELIZE");
    await sequelize.close();
  });

  it("/ (GET)", () => {
    return request(app.getHttpServer())
      .get("/")
      .expect(200)
      .expect("Hello World!");
  });
});