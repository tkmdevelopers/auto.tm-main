import { Test, TestingModule } from "@nestjs/testing";
import { PostService } from "./post.service";
import { ConfigModule } from "@nestjs/config";
import { SequelizeModule } from "@nestjs/sequelize";
import { User } from "../auth/auth.entity";
import { Posts, Convert } from "./post.entity";
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

dotenv.config({ path: '.env.test' });

describe("PostService (Integration)", () => {
  let service: PostService;
  let module: TestingModule;

  // Check if we have DB connection details, otherwise skip
  const runTests = process.env.DATABASE_HOST ? describe : describe.skip;

  runTests("Database Integration", () => {
    beforeAll(async () => {
      module = await Test.createTestingModule({
        imports: [
          ConfigModule.forRoot({
            envFilePath: ".env.test",
            isGlobal: true,
          }),
          SequelizeModule.forRoot({
            dialect: "postgres",
            dialectModule: pg, // Explicitly pass the pg module
            host: process.env.DATABASE_HOST || "localhost",
            port: parseInt(process.env.DATABASE_PORT || "5432"),
            username: process.env.DATABASE_USER || "auto_tm",
            password: process.env.DATABASE_PASSWORD || "auto_tm_pass",
            database: process.env.DATABASE_NAME || "auto_tm_test",
            autoLoadModels: true,
            synchronize: true, // Create tables automatically for tests
            logging: false,
            models: [
                Posts,
                User,
                Brands,
                Models,
                Categories,
                Subscriptions,
                SubscriptionOrder,
                Photo,
                Video,
                Comments,
                File,
                BrandsUser,
                PhotoPosts,
                PhotoVlog,
                Vlogs,
                Banners,
                NotificationHistory,
                OtpCode
            ]
          }),
          SequelizeModule.forFeature([
            Posts,
            Convert,
            User,
            Brands,
            Models,
            Categories,
            Subscriptions,
            SubscriptionOrder,
            Photo,
            Video,
            Comments,
            File,
            BrandsUser,
            PhotoPosts,
            PhotoVlog
          ]),
        ],
        providers: [
            PostService,
            ...UtilProviders
        ],
      }).compile();

      service = module.get<PostService>(PostService);
    });

    afterAll(async () => {
      if (module) {
        await module.close();
      }
    });

    beforeEach(async () => {
        // Clean up table before each test
        try {
            await Posts.destroy({ where: {}, truncate: true, cascade: true });
            await Brands.destroy({ where: {}, truncate: true, cascade: true });
            await User.destroy({ where: {}, truncate: true, cascade: true });
        } catch (e) {
            console.log("Cleanup skipped:", e.message);
        }
    });

    it("should create a post and find it", async () => {
      // 1. Setup Data
      const user = await User.create({
          uuid: uuidv4(),
          phone: "+99360000001",
          name: "Test User"
      });

      const brand = await Brands.create({
          uuid: uuidv4(),
          name: "Toyota_Test"
      });

      // 2. Execute Logic
      const post1 = await Posts.create({
          uuid: uuidv4(),
          userId: user.uuid,
          brandsId: brand.uuid,
          price: 10000,
          year: 2020,
          description: "Test Car 1",
          currency: "TMT",
          status: true // active
      });

      // 3. Verify
      const req: any = {}; 
      const res: any = {
          status: jest.fn().mockReturnThis(),
          json: jest.fn().mockImplementation((data) => data)
      };

      const result = await service.findAll({ limit: 10 } as any, req, res);
      
      expect(result).toHaveLength(1);
      expect(result[0].uuid).toBe(post1.uuid);
    });

    it("should filter posts by price range", async () => {
        const user = await User.create({ uuid: uuidv4(), phone: "+99360000002" });
        
        await Posts.create({ uuid: uuidv4(), userId: user.uuid, price: 5000, year: 2010, currency: "TMT" });
        await Posts.create({ uuid: uuidv4(), userId: user.uuid, price: 15000, year: 2015, currency: "TMT" });
        await Posts.create({ uuid: uuidv4(), userId: user.uuid, price: 25000, year: 2020, currency: "TMT" });
  
        const req: any = {}; 
        const res: any = { status: jest.fn().mockReturnThis(), json: (d) => d };
  
        // Filter 10k - 20k
        const result = await service.findAll({ minPrice: "10000", maxPrice: "20000" } as any, req, res);
        
        expect(result).toHaveLength(1);
        expect(result[0].price).toBe(15000);
      });

    it("should return empty list when no matches found", async () => {
        const user = await User.create({ uuid: uuidv4(), phone: "+99360000003" });
        await Posts.create({ uuid: uuidv4(), userId: user.uuid, price: 5000, description: "Toyota" });

        const req: any = {}; 
        const res: any = { status: jest.fn().mockReturnThis(), json: (d) => d };

        // Search for non-existent term
        // Note: PostService implementation requires 'model: true' to search against model names
        const result = await service.findAll({ search: "BMW", model: "true" } as any, req, res);
        
        expect(result).toHaveLength(0);
    });

    it("should paginate results correctly", async () => {
        const user = await User.create({ uuid: uuidv4(), phone: "+99360000004" });
        
        // Create 5 posts with increasing prices
        for(let i=1; i<=5; i++) {
            await Posts.create({ 
                uuid: uuidv4(), 
                userId: user.uuid, 
                price: i * 1000, 
                description: `Car ${i}`,
                createdAt: new Date(2023, 0, i) // Ensure deterministic sort order
            });
        }

        const req: any = {}; 
        const res: any = { status: jest.fn().mockReturnThis(), json: (d) => d };

        // Page 1: Limit 2, Offset 0 -> expect Car 5, Car 4 (desc sort default)
        const page1 = await service.findAll({ limit: 2, offset: 0, sortBy: 'createdAt', sortAs: 'desc' } as any, req, res);
        expect(page1).toHaveLength(2);
        expect(page1[0].description).toBe("Car 5");
        expect(page1[1].description).toBe("Car 4");

        // Page 2: Limit 2, Offset 2 -> expect Car 3, Car 2
        const page2 = await service.findAll({ limit: 2, offset: 2, sortBy: 'createdAt', sortAs: 'desc' } as any, req, res);
        expect(page2).toHaveLength(2);
        expect(page2[0].description).toBe("Car 3");
        expect(page2[1].description).toBe("Car 2");
    });
  });
});
