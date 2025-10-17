'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Create comments table if not exists
    const tables = await queryInterface.showAllTables();
    if (!tables.includes('comments')) {
      await queryInterface.createTable('comments', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        message: {
          type: Sequelize.STRING(1000), // allow larger message body
          allowNull: false,
        },
        status: {
          type: Sequelize.BOOLEAN,
          allowNull: true,
        },
        userId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: {
            model: 'users',
            key: 'uuid',
          },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        sender: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        postId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: {
            model: 'posts',
            key: 'uuid',
          },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        replyTo: {
          type: Sequelize.STRING,
          allowNull: true,
          references: {
            model: 'comments',
            key: 'uuid',
          },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        createdAt: {
          allowNull: false,
          type: Sequelize.DATE,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          allowNull: false,
          type: Sequelize.DATE,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
    }
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('comments');
  },
};
