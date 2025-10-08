import { Test, TestingModule } from '@nestjs/testing';
import { VlogController } from './vlog.controller';

describe('VlogController', () => {
  let controller: VlogController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [VlogController],
    }).compile();

    controller = module.get<VlogController>(VlogController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
