'use strict';

/**
 * Migration: Replace plaintext refreshToken with hashed storage
 *
 * - Adds refreshTokenHash column (stores bcrypt hash of refresh token)
 * - Removes old refreshToken column (plaintext — security risk)
 *
 * NOTE: This is a breaking change. All existing sessions are invalidated.
 * Users will need to re-login after this migration.
 */

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Add new hashed column
    await queryInterface.addColumn('users', 'refreshTokenHash', {
      type: Sequelize.TEXT,
      allowNull: true,
    });

    // Remove old plaintext column
    await queryInterface.removeColumn('users', 'refreshToken');
  },

  async down(queryInterface, Sequelize) {
    // Restore old plaintext column
    await queryInterface.addColumn('users', 'refreshToken', {
      type: Sequelize.TEXT,
      allowNull: true,
    });

    // Remove hashed column
    await queryInterface.removeColumn('users', 'refreshTokenHash');
  },
};
