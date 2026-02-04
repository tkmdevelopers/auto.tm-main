'use strict';

/**
 * Schema fix migration for drifted databases.
 *
 * Why this exists:
 * - Some environments already have `20260202000000-baseline.js` recorded in SequelizeMeta,
 *   but the physical schema may still be missing columns/constraints due to prior drift.
 * - Seed scripts rely on:
 *   - brands.createdAt / brands.updatedAt
 *   - convert_prices.label UNIQUE + label/rate NOT NULL (for ON CONFLICT(label) upserts)
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();

    // ------------------------------------------------------------
    // brands: ensure createdAt/updatedAt exist and are NOT NULL
    // ------------------------------------------------------------
    if (tables.includes('brands')) {
      const desc = await queryInterface.describeTable('brands');
      const existing = new Set(Object.keys(desc));

      if (!existing.has('createdAt')) {
        await queryInterface.addColumn('brands', 'createdAt', {
          type: Sequelize.DATE,
          allowNull: true,
        });
        await queryInterface.sequelize.query(
          `UPDATE brands SET "createdAt" = NOW() WHERE "createdAt" IS NULL;`,
        );
        await queryInterface.changeColumn('brands', 'createdAt', {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        });
      }

      if (!existing.has('updatedAt')) {
        await queryInterface.addColumn('brands', 'updatedAt', {
          type: Sequelize.DATE,
          allowNull: true,
        });
        await queryInterface.sequelize.query(
          `UPDATE brands SET "updatedAt" = NOW() WHERE "updatedAt" IS NULL;`,
        );
        await queryInterface.changeColumn('brands', 'updatedAt', {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        });
      }
    }

    // ------------------------------------------------------------
    // convert_prices: label UNIQUE + label/rate NOT NULL
    // ------------------------------------------------------------
    if (tables.includes('convert_prices')) {
      const desc = await queryInterface.describeTable('convert_prices');
      const existing = new Set(Object.keys(desc));

      // Backfill NULL labels/rates before tightening constraints
      if (existing.has('label')) {
        await queryInterface.sequelize.query(
          `UPDATE convert_prices SET label = CONCAT('UNKNOWN_', id) WHERE label IS NULL;`,
        );
      }
      if (existing.has('rate')) {
        await queryInterface.sequelize.query(
          `UPDATE convert_prices SET rate = 0 WHERE rate IS NULL;`,
        );
      }

      // De-duplicate labels so a UNIQUE index can be created.
      // Keep the smallest id per label and delete the rest.
      await queryInterface.sequelize.query(`
        DELETE FROM convert_prices a
        USING convert_prices b
        WHERE a.id > b.id
          AND a.label = b.label;
      `);

      // Enforce NOT NULLs (match baseline intent)
      if (existing.has('label')) {
        await queryInterface.changeColumn('convert_prices', 'label', {
          type: Sequelize.STRING,
          allowNull: false,
        });
      }
      if (existing.has('rate')) {
        await queryInterface.changeColumn('convert_prices', 'rate', {
          type: Sequelize.DECIMAL(18, 6),
          allowNull: false,
        });
      }

      // Ensure UNIQUE index on label exists (required for ON CONFLICT(label))
      try {
        const indexes = await queryInterface.showIndex('convert_prices');
        const hasUniqueLabel = indexes.some((idx) => {
          const fields = idx.fields?.map((f) => f.attribute) || [];
          return idx.unique && fields.length === 1 && fields[0] === 'label';
        });

        if (!hasUniqueLabel) {
          await queryInterface.addIndex('convert_prices', ['label'], {
            unique: true,
            name: 'convert_prices_label_unique',
          });
        }
      } catch (e) {
        // Fall back: try to add; ignore if it already exists
        try {
          await queryInterface.addIndex('convert_prices', ['label'], {
            unique: true,
            name: 'convert_prices_label_unique',
          });
        } catch (_) {
          // ignore
        }
      }
    }
  },

  async down(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();

    if (tables.includes('brands')) {
      try {
        await queryInterface.removeColumn('brands', 'createdAt');
      } catch (_) {
        // ignore
      }
      try {
        await queryInterface.removeColumn('brands', 'updatedAt');
      } catch (_) {
        // ignore
      }
    }

    if (tables.includes('convert_prices')) {
      try {
        await queryInterface.removeIndex('convert_prices', 'convert_prices_label_unique');
      } catch (_) {
        // ignore
      }
      try {
        await queryInterface.changeColumn('convert_prices', 'label', {
          type: Sequelize.STRING,
          allowNull: true,
        });
      } catch (_) {
        // ignore
      }
      try {
        await queryInterface.changeColumn('convert_prices', 'rate', {
          type: Sequelize.DECIMAL(18, 6),
          allowNull: true,
        });
      } catch (_) {
        // ignore
      }
    }
  },
};

