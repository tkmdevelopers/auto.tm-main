'use strict';

/**
 * Creates taxonomy and subscription related tables that were previously only defined in models.
 * Tables: banners, categories, subscriptions, subscription_order
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();

    // banners
    if (!tables.includes('banners')) {
      await queryInterface.createTable('banners', {
        uuid: { type: Sequelize.STRING, primaryKey: true, allowNull: false },
        creator: { type: Sequelize.JSONB, allowNull: false },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
    }

    // categories
    if (!tables.includes('categories')) {
      await queryInterface.createTable('categories', {
        uuid: { type: Sequelize.STRING, primaryKey: true, allowNull: false },
        name: { type: Sequelize.JSONB, allowNull: false },
        creator: { type: Sequelize.JSONB, allowNull: false },
        priority: { type: Sequelize.INTEGER, allowNull: true, unique: true },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
    }

    // subscriptions
    if (!tables.includes('subscriptions')) {
      await queryInterface.createTable('subscriptions', {
        uuid: { type: Sequelize.STRING, primaryKey: true, allowNull: false },
        name: { type: Sequelize.JSONB, allowNull: false },
        priority: { type: Sequelize.INTEGER, allowNull: true, unique: true },
        price: { type: Sequelize.DECIMAL(14, 2), allowNull: true },
        color: { type: Sequelize.STRING, allowNull: true },
        description: { type: Sequelize.JSONB, allowNull: false },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
    }

    // subscription_order
    if (!tables.includes('subscription_order')) {
      await queryInterface.createTable('subscription_order', {
        uuid: { type: Sequelize.STRING, primaryKey: true, allowNull: false },
        location: { type: Sequelize.STRING, allowNull: true },
        phone: { type: Sequelize.STRING, allowNull: true },
        status: { type: Sequelize.STRING, allowNull: true },
        subscriptionId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'subscriptions', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        createdAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
        updatedAt: { allowNull: false, type: Sequelize.DATE, defaultValue: Sequelize.fn('NOW') },
      });
      await queryInterface.addIndex('subscription_order', ['subscriptionId']);
    }
  },
  async down(queryInterface) {
    await queryInterface.dropTable('subscription_order');
    await queryInterface.dropTable('subscriptions');
    await queryInterface.dropTable('categories');
    await queryInterface.dropTable('banners');
  },
};
