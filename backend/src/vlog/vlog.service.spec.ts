import { Test, TestingModule } from '@nestjs/testing';
import { VlogService } from './vlog.service';

describe('VlogService', () => {
  let service: VlogService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [VlogService],
    }).compile();

    service = module.get<VlogService>(VlogService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
