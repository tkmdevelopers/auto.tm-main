'use strict';

/** Consolidated models migration (placed before posts) */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('models', {
      uuid: {
        type: Sequelize.STRING,
        allowNull: false,
        primaryKey: true,
      },
      brandId: {
        type: Sequelize.STRING,
        allowNull: true,
        references: {
          model: 'brands',
          key: 'uuid',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      createdAt: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updatedAt: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('models');
  },
};
