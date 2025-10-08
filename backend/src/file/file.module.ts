import { Module } from '@nestjs/common';
import { FileController } from './file.controller';
import { FileService } from './file.service';
import { UtilProviders } from 'src/utils/utilsProvider';

@Module({
  controllers: [FileController],
  providers: [FileService, ...UtilProviders],
})
export class FileModule {}
