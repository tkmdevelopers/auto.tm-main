'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('vlog', 'tag', {
      type: Sequelize.STRING,
      allowNull: true,
    });

    await queryInterface.addColumn('vlog', 'videoUrl', {
      type: Sequelize.STRING,
      allowNull: true,
    });

    await queryInterface.addColumn('vlog', 'isActive', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    });

    await queryInterface.addColumn('vlog', 'thumbnail', {
      type: Sequelize.JSON,
      allowNull: true,
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('vlog', 'tag');
    await queryInterface.removeColumn('vlog', 'videoUrl');
    await queryInterface.removeColumn('vlog', 'isActive');
    await queryInterface.removeColumn('vlog', 'thumbnail');
  },
};
