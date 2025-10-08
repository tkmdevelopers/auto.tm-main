import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { VersioningType } from '@nestjs/common';
import * as morgan from 'morgan';
import * as cors from 'cors';
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = new DocumentBuilder()
    .setTitle('Alpha Motors Backend Server')
    .addSecurity('token', {
      type: 'apiKey',
      scheme: 'Bearer',
      in: 'header',
      name: 'authorization',
    })
    .setDescription('Alpha Motors')
    .setVersion('1')
    .build();

  app.setGlobalPrefix('api');
  app.use(morgan('dev'));
  app.use(cors({ origin: '*' }));
  const documentFactory = () => SwaggerModule.createDocument(app, config);
  app.enableVersioning({
    type: VersioningType.URI,
  });
  SwaggerModule.setup('api-docs', app, documentFactory);
  await app.listen(process.env.PORT ?? 3080);
}
bootstrap();
