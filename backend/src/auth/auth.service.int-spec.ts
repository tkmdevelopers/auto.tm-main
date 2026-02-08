import { Test, TestingModule } from "@nestjs/testing";
import { AuthService } from "./auth.service";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { SequelizeModule } from "@nestjs/sequelize";
import { JwtModule, JwtService } from "@nestjs/jwt";
import { User } from "./auth.entity";
import { Posts, Convert } from "../post/post.entity";
import { Brands } from "../brands/brands.entity";
import { Models } from "../models/models.entity";
import { Categories } from "../categories/categories.entity";
import { Subscriptions } from "../subscription/subscription.entity";
import { SubscriptionOrder } from "../subscription/subscription_order.entity";
import { Photo } from "../photo/photo.entity";
import { Video } from "../video/video.entity";
import { Comments } from "../comments/comments.entity";
import { File } from "../file/file.entity";
import { BrandsUser } from "../junction/brands_user";
import { PhotoPosts } from "../junction/photo_posts";
import { PhotoVlog } from "../junction/photo_vlog";
import { Vlogs } from "../vlog/vlog.entity";
import { Banners } from "../banners/banners.entity";
import { NotificationHistory } from "../notification/notification.entity";
import { OtpCode } from "../otp/otp-codes.entity";
import { UtilProviders } from "../utils/utilsProvider";
import { v4 as uuidv4 } from "uuid";
import * as dotenv from 'dotenv';
import * as pg from 'pg';
import * as bcrypt from 'bcryptjs';
import { hashToken, validateToken } from "../utils/token.utils";
import { UserFactory } from "../../test/factories/user.factory";

dotenv.config({ path: '.env.test' });

describe("AuthService (Integration)", () => {
  let service: AuthService;
  let module: TestingModule;
  let jwtService: JwtService;

  // Check if we have DB connection details, otherwise skip
  const runTests = process.env.DATABASE_HOST ? describe : describe.skip;

  runTests("Authentication Flow", () => {
    beforeAll(async () => {
      module = await Test.createTestingModule({
        imports: [
          ConfigModule.forRoot({
            envFilePath: ".env.test",
            isGlobal: true,
          }),
          JwtModule.register({
             secret: 'test_secret',
             signOptions: { expiresIn: '15m' },
          }),
          SequelizeModule.forRoot({
            dialect: "postgres",
            dialectModule: pg,
            host: process.env.DATABASE_HOST || "localhost",
            port: parseInt(process.env.DATABASE_PORT || "5432"),
            username: process.env.DATABASE_USER || "auto_tm",
            password: process.env.DATABASE_PASSWORD || "auto_tm_pass",
            database: process.env.DATABASE_NAME || "auto_tm_test",
            autoLoadModels: true,
            synchronize: true,
            logging: false,
            models: [User, Posts, Convert, Brands, Models, Categories, Subscriptions, SubscriptionOrder, Photo, Video, Comments, File, BrandsUser, PhotoPosts, PhotoVlog, Vlogs, Banners, NotificationHistory, OtpCode]
          }),
          SequelizeModule.forFeature([User, Photo]),
        ],
        providers: [
            AuthService,
            ConfigService,
            ...UtilProviders,
        ],
      }).compile();

      service = module.get<AuthService>(AuthService);
      jwtService = module.get<JwtService>(JwtService);
    });

    afterAll(async () => {
      if (module) await module.close();
    });

    beforeEach(async () => {
        try {
            await User.destroy({ where: {}, truncate: true, cascade: true });
        } catch (e) { console.log("Cleanup skipped"); }
    });

    it("should rotate tokens on refresh", async () => {
        // 1. Create User with a valid refresh token hash
        const oldRefreshToken = jwtService.sign({ uuid: 'ignore_this' }, { secret: process.env.REFRESH_TOKEN_SECRET_KEY || 'test_refresh_secret' });
        const oldHash = await hashToken(oldRefreshToken);

        const user = await UserFactory.create({
            refreshTokenHash: oldHash
        });
        const userId = user.uuid;

        // 2. Call Refresh
        const req: any = {
            uuid: userId,
            get: (header) => (header === 'authorization' ? `Bearer ${oldRefreshToken}` : ''),
        };

        const result = await service.refresh(req);

        // 3. Verify
        expect(result).toHaveProperty('accessToken');
        expect(result).toHaveProperty('refreshToken');
        expect(result.refreshToken).not.toBe(oldRefreshToken);

        // 4. Verify DB was updated
        const updatedUser = await User.findOne({ where: { uuid: userId } });
        expect(updatedUser).toBeDefined();
        if (!updatedUser) throw new Error("User not found");
        expect(updatedUser.refreshTokenHash).not.toBe(oldHash);
        
        // Verify new hash matches new token
        const isMatch = await validateToken(result.refreshToken, updatedUser.refreshTokenHash);
        expect(isMatch).toBe(true);
    });

    it("should revoke session on logout", async () => {
        const user = await UserFactory.create({
            refreshTokenHash: "some_hash"
        });
        const userId = user.uuid;

        const req: any = { uuid: userId };
        const res: any = { status: jest.fn().mockReturnThis(), json: (d) => d };

        await service.logout(req, res);

        const updatedUser = await User.findOne({ where: { uuid: userId } });
        expect(updatedUser).toBeDefined();
        if (!updatedUser) throw new Error("User not found");
        expect(updatedUser.refreshTokenHash).toBeNull();
    });

    it("should detect token reuse and revoke session", async () => {
        const userId = uuidv4();
        const initialToken = jwtService.sign({ uuid: userId }, { secret: process.env.REFRESH_TOKEN_SECRET_KEY || 'test_refresh_secret' });
        const initialHash = await hashToken(initialToken);

        // 1. Setup user with a valid token
        await UserFactory.create({
            uuid: userId,
            refreshTokenHash: initialHash
        });

        // Sleep to ensure new token has different IAT
        await new Promise(r => setTimeout(r, 1100));

        // 2. Simulate legitimate refresh (rotates token)
        const req1: any = {
            uuid: userId,
            get: (header) => (header === 'authorization' ? `Bearer ${initialToken}` : ''),
        };
        const result1 = await service.refresh(req1);
        const newToken = result1.refreshToken;

        // Verify hash changed after first refresh
        const userAfterRefresh = await User.findOne({ where: { uuid: userId } });
        expect(userAfterRefresh).toBeDefined();
        if (!userAfterRefresh) throw new Error("User not found");
        expect(userAfterRefresh.refreshTokenHash).not.toBe(initialHash);

        // 3. Attack: Attacker tries to use the OLD token (initialToken)
        // This simulates a replay attack or race condition
        const reqAttack: any = {
            uuid: userId,
            get: (header) => (header === 'authorization' ? `Bearer ${initialToken}` : ''),
        };

        // Expect it to fail
        await expect(service.refresh(reqAttack)).rejects.toThrow();

        // 4. Verify Consequence: Session should be revoked (hash set to null)
        // because the system detected reuse of a compromised token
        const compromisedUser = await User.findOne({ where: { uuid: userId } });
        expect(compromisedUser).toBeDefined();
        if (!compromisedUser) throw new Error("User not found");
        expect(compromisedUser.refreshTokenHash).toBeNull();
    });
  });
});
