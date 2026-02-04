'use strict';
/**
 * Creates junction tables: brands_user, photo_posts, photo_vlogs
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();

    if (!tables.includes('brands_user')) {
      await queryInterface.createTable('brands_user', {
        id: { type: Sequelize.BIGINT, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.STRING, allowNull: true, references: { model: 'users', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        brandId: { type: Sequelize.STRING, allowNull: true, references: { model: 'brands', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
      });
      await queryInterface.addConstraint('brands_user', {
        fields: ['brandId', 'userId'],
        type: 'unique',
        name: 'uq_brands_user_brand_user',
      });
    }

    if (!tables.includes('photo_posts')) {
      await queryInterface.createTable('photo_posts', {
        id: { type: Sequelize.BIGINT, autoIncrement: true, primaryKey: true },
        postId: { type: Sequelize.STRING, allowNull: true, references: { model: 'posts', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        photoUuid: { type: Sequelize.STRING, allowNull: true, references: { model: 'photo', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
      });
      await queryInterface.addIndex('photo_posts', ['postId']);
    }

    if (!tables.includes('photo_vlogs')) {
      await queryInterface.createTable('photo_vlogs', {
        id: { type: Sequelize.BIGINT, autoIncrement: true, primaryKey: true },
        vlogId: { type: Sequelize.STRING, allowNull: true, references: { model: 'vlogs', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        photoUuid: { type: Sequelize.STRING, allowNull: true, references: { model: 'photo', key: 'uuid' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
      });
      await queryInterface.addIndex('photo_vlogs', ['vlogId']);
    }
  },
  async down(queryInterface) {
    await queryInterface.dropTable('photo_vlogs');
    await queryInterface.dropTable('photo_posts');
    await queryInterface.dropTable('brands_user');
  },
};
