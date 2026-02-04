'use strict';
/**
 * Creates media related tables: photo, video, file, otp_temp, convert_prices
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();

    // photo
    if (!tables.includes('photo')) {
      await queryInterface.createTable('photo', {
        uuid: { type: Sequelize.STRING, primaryKey: true, allowNull: false },
        path: { type: Sequelize.JSONB, allowNull: true },
        originalPath: { type: Sequelize.STRING, allowNull: true },
        bannerId: { type: Sequelize.STRING, allowNull: true, references: { model: 'banners', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        categoryId: { type: Sequelize.STRING, allowNull: true, references: { model: 'categories', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        subscriptionId: { type: Sequelize.STRING, allowNull: true, references: { model: 'subscriptions', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        brandsId: { type: Sequelize.STRING, allowNull: true, references: { model: 'brands', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        modelsId: { type: Sequelize.STRING, allowNull: true, references: { model: 'models', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        userId: { type: Sequelize.STRING, allowNull: true, references: { model: 'users', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
      await queryInterface.addIndex('photo', ['userId']);
    }

    // video
    if (!tables.includes('video')) {
      await queryInterface.createTable('video', {
        id: { type: Sequelize.BIGINT, autoIncrement: true, primaryKey: true },
        url: { type: Sequelize.STRING, allowNull: true },
        postId: { type: Sequelize.STRING, allowNull: true, references: { model: 'posts', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
      await queryInterface.addIndex('video', ['postId']);
    }

    // file
    if (!tables.includes('file')) {
      // Ensure pgcrypto extension if you want gen_random_uuid (left to DBA) – here we store as TEXT per existing patterns.
      await queryInterface.createTable('file', {
        uuid: { type: Sequelize.STRING, primaryKey: true, allowNull: false },
        path: { type: Sequelize.STRING, allowNull: true },
        postId: { type: Sequelize.STRING, allowNull: true, references: { model: 'posts', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
      await queryInterface.addIndex('file', ['postId']);
    }

    // otp_temp
    if (!tables.includes('otp_temp')) {
      await queryInterface.createTable('otp_temp', {
        phone: { type: Sequelize.STRING, primaryKey: true, allowNull: false },
        otp: { type: Sequelize.STRING, allowNull: true },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
    }

    // convert_prices
    if (!tables.includes('convert_prices')) {
      await queryInterface.createTable('convert_prices', {
        id: { type: Sequelize.BIGINT, autoIncrement: true, primaryKey: true },
        label: { type: Sequelize.STRING, allowNull: true },
        rate: { type: Sequelize.DECIMAL(18, 6), allowNull: true },
      });
    }
  },
  async down(queryInterface) {
    await queryInterface.dropTable('convert_prices');
    await queryInterface.dropTable('otp_temp');
    await queryInterface.dropTable('file');
    await queryInterface.dropTable('video');
    await queryInterface.dropTable('photo');
  },
};
