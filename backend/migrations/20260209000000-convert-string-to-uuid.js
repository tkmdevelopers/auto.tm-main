'use strict';

/**
 * MIGRATION: Convert ID columns from STRING to UUID (Native)
 * 
 * This migration upgrades the database schema to use native PostgreSQL UUID types
 * instead of VARCHAR strings for primary and foreign keys.
 * 
 * Steps:
 * 1. Identify and drop all Foreign Key constraints linking the affected tables.
 * 2. Convert all Primary Key and Foreign Key columns to UUID type.
 * 3. Re-establish the Foreign Key constraints.
 */

const TABLE_DEFINITIONS = [
  { 
    table: 'users', 
    pk: 'uuid', 
    fks: [] 
  },
  { 
    table: 'brands', 
    pk: 'uuid', 
    fks: [] 
  },
  { 
    table: 'models', 
    pk: 'uuid', 
    fks: [{ col: 'brandId', refTable: 'brands', refCol: 'uuid' }] 
  },
  { 
    table: 'categories', 
    pk: 'uuid', 
    fks: [] 
  },
  { 
    table: 'banners', 
    pk: 'uuid', 
    fks: [] 
  },
  { 
    table: 'subscriptions', 
    pk: 'uuid', 
    fks: [] 
  },
  { 
    table: 'subscription_order', 
    pk: 'uuid', 
    fks: [{ col: 'subscriptionId', refTable: 'subscriptions', refCol: 'uuid' }] 
  },
  { 
    table: 'posts', 
    pk: 'uuid', 
    fks: [
      { col: 'brandsId', refTable: 'brands', refCol: 'uuid' },
      { col: 'modelsId', refTable: 'models', refCol: 'uuid' },
      { col: 'categoryId', refTable: 'categories', refCol: 'uuid' },
      { col: 'subscriptionId', refTable: 'subscriptions', refCol: 'uuid' },
      { col: 'userId', refTable: 'users', refCol: 'uuid' }
    ]
  },
  { 
    table: 'vlogs', 
    pk: 'uuid', 
    fks: [{ col: 'userId', refTable: 'users', refCol: 'uuid' }] 
  },
  { 
    table: 'comments', 
    pk: 'uuid', 
    fks: [
      { col: 'userId', refTable: 'users', refCol: 'uuid' },
      { col: 'postId', refTable: 'posts', refCol: 'uuid' },
      { col: 'replyTo', refTable: 'comments', refCol: 'uuid' }
    ]
  },
  { 
    table: 'photo', 
    pk: 'uuid', 
    fks: [
      { col: 'bannerId', refTable: 'banners', refCol: 'uuid' },
      { col: 'categoryId', refTable: 'categories', refCol: 'uuid' },
      { col: 'subscriptionId', refTable: 'subscriptions', refCol: 'uuid' },
      { col: 'brandsId', refTable: 'brands', refCol: 'uuid' },
      { col: 'modelsId', refTable: 'models', refCol: 'uuid' },
      { col: 'userId', refTable: 'users', refCol: 'uuid' }
    ]
  },
  { 
    table: 'video', 
    pk: 'id', // Integer PK, skip
    fks: [{ col: 'postId', refTable: 'posts', refCol: 'uuid' }] 
  },
  { 
    table: 'file', 
    pk: 'uuid', 
    fks: [{ col: 'postId', refTable: 'posts', refCol: 'uuid' }] 
  },
  { 
    table: 'notification_history', 
    pk: 'uuid', 
    fks: [{ col: 'sentBy', refTable: 'users', refCol: 'uuid' }] 
  },
  // Junction Tables
  { 
    table: 'brands_user', 
    pk: 'id', // Integer PK
    fks: [
      { col: 'userId', refTable: 'users', refCol: 'uuid' },
      { col: 'brandId', refTable: 'brands', refCol: 'uuid' }
    ] 
  },
  { 
    table: 'photo_posts', 
    pk: 'id', // Integer PK
    fks: [
      { col: 'postId', refTable: 'posts', refCol: 'uuid' },
      { col: 'photoUuid', refTable: 'photo', refCol: 'uuid' }
    ] 
  },
  { 
    table: 'photo_vlogs', 
    pk: 'id', // Integer PK
    fks: [
      { col: 'vlogId', refTable: 'vlogs', refCol: 'uuid' },
      { col: 'photoUuid', refTable: 'photo', refCol: 'uuid' }
    ] 
  }
];

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      console.log('[Migration] Starting conversion to native UUIDs...');

      // 1. Drop Constraints
      for (const def of TABLE_DEFINITIONS) {
        // Drop FKs defined in our list
        for (const fk of def.fks) {
          // We need to find the actual constraint name
          const constraints = await queryInterface.sequelize.query(
            `SELECT conname FROM pg_constraint WHERE conrelid = '${def.table}'::regclass AND confrelid = '${fk.refTable}'::regclass AND contype = 'f';`,
            { type: queryInterface.sequelize.QueryTypes.SELECT, transaction }
          );
          
          for (const constraint of constraints) {
            console.log(`[Migration] Dropping constraint ${constraint.conname} on ${def.table}`);
            await queryInterface.removeConstraint(def.table, constraint.conname, { transaction });
          }
        }
      }

      // 2. Convert Columns
      for (const def of TABLE_DEFINITIONS) {
        // Convert PK if it's uuid
        if (def.pk === 'uuid') {
          console.log(`[Migration] Converting ${def.table}.${def.pk} to UUID`);
          await queryInterface.sequelize.query(
            `ALTER TABLE "${def.table}" ALTER COLUMN "${def.pk}" TYPE uuid USING "${def.pk}"::uuid`,
            { transaction }
          );
          
          // Set default value to gen_random_uuid() if available, or stay with app-generated
          // For now, let's strictly type it.
        }

        // Convert FK columns
        for (const fk of def.fks) {
          console.log(`[Migration] Converting ${def.table}.${fk.col} to UUID`);
           await queryInterface.sequelize.query(
            `ALTER TABLE "${def.table}" ALTER COLUMN "${fk.col}" TYPE uuid USING "${fk.col}"::uuid`,
            { transaction }
          );
        }
      }

      // 3. Re-add Constraints
      for (const def of TABLE_DEFINITIONS) {
        for (const fk of def.fks) {
          console.log(`[Migration] Re-adding constraint for ${def.table}.${fk.col}`);
          // Re-add with standard ON UPDATE CASCADE / ON DELETE SET NULL (or CASCADE)
          // Defaulting to SET NULL for most, CASCADE for junctions/ownership as inferred from baseline
          
          let onDelete = 'SET NULL';
          if (['comments', 'video', 'file', 'photo_posts', 'photo_vlogs', 'brands_user'].includes(def.table)) {
             // These usually cascade delete
             if (def.table === 'comments' && fk.col === 'postId') onDelete = 'CASCADE';
             if (def.table === 'video' && fk.col === 'postId') onDelete = 'CASCADE';
             if (def.table === 'file' && fk.col === 'postId') onDelete = 'CASCADE';
             if (def.table === 'photo_posts') onDelete = 'CASCADE';
             if (def.table === 'photo_vlogs') onDelete = 'CASCADE';
             if (def.table === 'brands_user') onDelete = 'CASCADE';
          }

          await queryInterface.addConstraint(def.table, {
            fields: [fk.col],
            type: 'foreign key',
            name: `fk_${def.table}_${fk.col}_${fk.refTable}`, // Custom name to ensure uniqueness
            references: {
              table: fk.refTable,
              field: fk.refCol
            },
            onDelete: onDelete,
            onUpdate: 'CASCADE',
            transaction
          });
        }
      }

      await transaction.commit();
      console.log('[Migration] Successfully converted to native UUIDs.');
    } catch (error) {
      await transaction.rollback();
      console.error('[Migration] Failed to convert to UUIDs:', error);
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    // Reverting is complex and risky (data loss if UUIDs aren't strings).
    // For now, we assume this is a one-way upgrade.
    console.error('Reverting UUID conversion is not implemented to prevent data corruption.');
  }
};
