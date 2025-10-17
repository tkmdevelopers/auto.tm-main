'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('notification_history', {
      uuid: {
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
      },
      title: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      body: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      type: {
        type: Sequelize.ENUM(
          'all_users',
          'brand_subscribers',
          'specific_user',
          'topic',
        ),
        allowNull: false,
      },
      status: {
        type: Sequelize.ENUM('pending', 'sent', 'failed', 'partial'),
        allowNull: false,
        defaultValue: 'pending',
      },
      targetData: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      totalRecipients: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      successfulDeliveries: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      failedDeliveries: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      deliveryDetails: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      additionalData: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      sentBy: {
        type: Sequelize.STRING,
        allowNull: true,
        references: {
          model: 'users',
          key: 'uuid',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      scheduledFor: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      isScheduled: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      topic: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      errorMessage: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW,
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW,
      },
    });

    // Add indexes for better performance
    await queryInterface.addIndex('notification_history', ['type']);
    await queryInterface.addIndex('notification_history', ['status']);
    await queryInterface.addIndex('notification_history', ['sentBy']);
    await queryInterface.addIndex('notification_history', ['createdAt']);
    await queryInterface.addIndex('notification_history', ['scheduledFor']);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('notification_history');
  },
};
