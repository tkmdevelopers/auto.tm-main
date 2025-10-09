'use strict';

/** Adds self-referencing replyTo column to comments table */
module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Guard so reruns or manual schema adjustments don't explode
    const table = await queryInterface.describeTable('comments');
    if (!table.replyTo) {
      await queryInterface.addColumn('comments', 'replyTo', {
        type: Sequelize.STRING,
        allowNull: true,
        references: { model: 'comments', key: 'uuid' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      });
      await queryInterface.addIndex('comments', ['replyTo']);
    } else {
      // Index might still be missing; attempt to add it defensively
      try {
        await queryInterface.addIndex('comments', ['replyTo']);
      } catch (e) {
        // Likely index already exists; swallow
      }
    }
  },

  down: async (queryInterface) => {
    // Only remove if actually present
    const table = await queryInterface.describeTable('comments');
    if (table.replyTo) {
      try { await queryInterface.removeIndex('comments', ['replyTo']); } catch (_) {}
      await queryInterface.removeColumn('comments', 'replyTo');
    }
  },
};
