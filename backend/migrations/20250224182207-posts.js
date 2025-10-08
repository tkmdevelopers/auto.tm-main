'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('posts', {
      uudi: {
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
      modelsId: {
        type: Sequelize.STRING,
        allowNull: true,
        references: {
          model: 'models',
          key: 'uuid',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      condition: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      engineType: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      enginePower: {
        type: Sequelize.INTEGER,
        allowNull: true,
      },
      year: {
        type: Sequelize.INTEGER,
        allowNull: true,
      },
      milleage: {
        type: Sequelize.INTEGER,
        allowNull: true,
      },
      vin: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      price: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: true,
      },
      currency: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      personalInfo: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      description: {
        type: Sequelize.TEXT,
        allowNull: true,
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

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('posts');
  },
};
