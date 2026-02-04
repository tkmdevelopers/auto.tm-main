'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
  await queryInterface.addColumn('vlogs', 'tag', {
      type: Sequelize.STRING,
      allowNull: true,
    });

  await queryInterface.addColumn('vlogs', 'videoUrl', {
      type: Sequelize.STRING,
      allowNull: true,
    });

  await queryInterface.addColumn('vlogs', 'isActive', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    });

  await queryInterface.addColumn('vlogs', 'thumbnail', {
      type: Sequelize.JSON,
      allowNull: true,
    });
  },

  down: async (queryInterface, Sequelize) => {
  await queryInterface.removeColumn('vlogs', 'tag');
  await queryInterface.removeColumn('vlogs', 'videoUrl');
  await queryInterface.removeColumn('vlogs', 'isActive');
  await queryInterface.removeColumn('vlogs', 'thumbnail');
  },
};
