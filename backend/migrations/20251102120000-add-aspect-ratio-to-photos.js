'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Add aspectRatio column (e.g., '16:9', '4:3', '1:1', '9:16', '3:4', 'custom')
    await queryInterface.addColumn('photo', 'aspectRatio', {
      type: Sequelize.STRING(20),
      allowNull: true,
      defaultValue: null,
      comment: 'Aspect ratio category (16:9, 4:3, 1:1, 9:16, 3:4, custom)',
    });

    // Add width column (original image width in pixels)
    await queryInterface.addColumn('photo', 'width', {
      type: Sequelize.INTEGER,
      allowNull: true,
      defaultValue: null,
      comment: 'Original image width in pixels',
    });

    // Add height column (original image height in pixels)
    await queryInterface.addColumn('photo', 'height', {
      type: Sequelize.INTEGER,
      allowNull: true,
      defaultValue: null,
      comment: 'Original image height in pixels',
    });

    // Add ratio column (decimal representation of aspect ratio, e.g., 1.78 for 16:9)
    await queryInterface.addColumn('photo', 'ratio', {
      type: Sequelize.FLOAT,
      allowNull: true,
      defaultValue: null,
      comment: 'Decimal aspect ratio (width/height)',
    });

    // Add orientation column ('landscape', 'portrait', 'square')
    await queryInterface.addColumn('photo', 'orientation', {
      type: Sequelize.STRING(20),
      allowNull: true,
      defaultValue: null,
      comment: 'Image orientation (landscape, portrait, square)',
    });

    // Add index on aspectRatio for efficient filtering
    await queryInterface.addIndex('photo', ['aspectRatio'], {
      name: 'idx_photo_aspect_ratio',
    });

    // Add index on orientation for efficient filtering
    await queryInterface.addIndex('photo', ['orientation'], {
      name: 'idx_photo_orientation',
    });

    // Add composite index for width and height (useful for size queries)
    await queryInterface.addIndex('photo', ['width', 'height'], {
      name: 'idx_photo_dimensions',
    });

    console.log('✅ Added aspect ratio columns to photo table');
  },

  async down(queryInterface) {
    // Remove indexes first
    await queryInterface.removeIndex('photo', 'idx_photo_dimensions');
    await queryInterface.removeIndex('photo', 'idx_photo_orientation');
    await queryInterface.removeIndex('photo', 'idx_photo_aspect_ratio');

    // Remove columns
    await queryInterface.removeColumn('photo', 'orientation');
    await queryInterface.removeColumn('photo', 'ratio');
    await queryInterface.removeColumn('photo', 'height');
    await queryInterface.removeColumn('photo', 'width');
    await queryInterface.removeColumn('photo', 'aspectRatio');

    console.log('✅ Removed aspect ratio columns from photo table');
  },
};
