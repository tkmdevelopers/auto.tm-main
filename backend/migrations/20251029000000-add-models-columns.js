'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Добавляем колонку yearstart
    await queryInterface.addColumn('models', 'yearstart', {
      type: Sequelize.INTEGER,
      allowNull: true,
    });

    // Добавляем колонку yearend
    await queryInterface.addColumn('models', 'yearend', {
      type: Sequelize.INTEGER,
      allowNull: true,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('models', 'yearstart');
    await queryInterface.removeColumn('models', 'yearend');
  },
};
