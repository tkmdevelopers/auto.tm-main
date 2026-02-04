'use strict';

/**
 * BASELINE MIGRATION - Alpha Motors Backend
 * 
 * This migration creates the complete database schema from scratch.
 * It replaces all previous migrations and includes:
 * - Updated users table (no OTP column - OTP now in otp_codes)
 * - New unified otp_codes table for all OTP purposes
 * - All other domain tables
 * 
 * Run this on a fresh database only.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();

    // ============================================================
    // 1. USERS TABLE (no otp column - moved to otp_codes)
    // ============================================================
    if (!tables.includes('users')) {
      await queryInterface.createTable('users', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        name: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        email: {
          type: Sequelize.STRING,
          allowNull: true,
          unique: true,
        },
        password: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        phone: {
          type: Sequelize.STRING(20),
          allowNull: true,
          unique: true,
        },
        status: {
          type: Sequelize.BOOLEAN,
          defaultValue: false,
        },
        role: {
          type: Sequelize.ENUM('admin', 'owner', 'user'),
          allowNull: false,
          defaultValue: 'user',
        },
        refreshToken: {
          type: Sequelize.TEXT,
          allowNull: true,
        },
        location: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        access: {
          type: Sequelize.ARRAY(Sequelize.STRING),
          allowNull: true,
        },
        firebaseToken: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('users', ['phone']);
      await queryInterface.addIndex('users', ['email']);
    } else {
      // Table exists - check and add missing columns
      console.log('[Migration] users table exists, checking for missing columns...');
      let tableDescription;
      try {
        tableDescription = await queryInterface.describeTable('users');
      } catch (e) {
        console.error('[Migration] Failed to describe users table:', e.message);
        throw e;
      }
      
      const columnsToAdd = {};
      const existingColumns = Object.keys(tableDescription);

      // Fix email column constraint if it's NOT NULL (should be nullable for phone-only auth)
      if (tableDescription.email && tableDescription.email.allowNull === false) {
        console.log('[Migration] Fixing email column to allow NULL...');
        try {
          await queryInterface.changeColumn('users', 'email', {
            type: Sequelize.STRING,
            allowNull: true,
            unique: true,
          });
          console.log('[Migration] ✓ Fixed email column constraint');
        } catch (e) {
          console.error('[Migration] Failed to alter email column:', e.message);
          // Continue - might fail if there are duplicate NULLs, but that's okay
        }
      }

      // Note: Legacy 'otp' column exists but is deprecated (OTP now in otp_codes table)
      // We leave it for now to avoid breaking existing code, but it's not used

      // Check and add location column if missing
      if (!existingColumns.includes('location')) {
        columnsToAdd.location = {
          type: Sequelize.STRING,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: location');
      }

      // Check and add access column if missing
      if (!existingColumns.includes('access')) {
        columnsToAdd.access = {
          type: Sequelize.ARRAY(Sequelize.STRING),
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: access');
      }

      // Check and add firebaseToken column if missing
      if (!existingColumns.includes('firebaseToken')) {
        columnsToAdd.firebaseToken = {
          type: Sequelize.STRING,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: firebaseToken');
      }

      // Check and update refreshToken column (might be refreshToke from old migration)
      if (!existingColumns.includes('refreshToken') && existingColumns.includes('refreshToke')) {
        // Rename refreshToke to refreshToken
        console.log('[Migration] Will rename column: refreshToke → refreshToken');
        try {
          await queryInterface.renameColumn('users', 'refreshToke', 'refreshToken');
        } catch (e) {
          console.error('[Migration] Failed to rename refreshToke:', e.message);
          // Continue - might already be renamed
        }
      } else if (!existingColumns.includes('refreshToken')) {
        columnsToAdd.refreshToken = {
          type: Sequelize.TEXT,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: refreshToken');
      }

      // Update role enum if needed (old migrations might have 'guest' instead of 'owner')
      // Note: Enum updates are complex in PostgreSQL, so we'll skip this if the column exists
      // The enum will be correct if the table was created fresh, or can be manually fixed if needed

      // Add all missing columns at once
      if (Object.keys(columnsToAdd).length > 0) {
        console.log(`[Migration] Adding ${Object.keys(columnsToAdd).length} missing column(s)...`);
        for (const [columnName, columnDef] of Object.entries(columnsToAdd)) {
          try {
            await queryInterface.addColumn('users', columnName, columnDef);
            console.log(`[Migration] ✓ Added column: ${columnName}`);
          } catch (e) {
            console.error(`[Migration] Failed to add column ${columnName}:`, e.message);
            // Continue with other columns
          }
        }
      } else {
        console.log('[Migration] All required columns exist in users table');
      }

      // Ensure indexes exist
      try {
        const indexes = await queryInterface.showIndex('users');
        const hasPhoneIndex = indexes.some(idx => idx.fields && idx.fields.some(f => f.attribute === 'phone'));
        const hasEmailIndex = indexes.some(idx => idx.fields && idx.fields.some(f => f.attribute === 'email'));

        if (!hasPhoneIndex) {
          await queryInterface.addIndex('users', ['phone']);
        }
        if (!hasEmailIndex) {
          await queryInterface.addIndex('users', ['email']);
        }
      } catch (e) {
        // Index check might fail, try to add indexes anyway (they might already exist)
        try {
          await queryInterface.addIndex('users', ['phone'], { unique: true });
        } catch (e2) {
          // Index might already exist, ignore
        }
        try {
          await queryInterface.addIndex('users', ['email'], { unique: true });
        } catch (e2) {
          // Index might already exist, ignore
        }
      }
    }

    // ============================================================
    // 2. OTP_CODES TABLE (new unified OTP storage)
    // ============================================================
    if (!tables.includes('otp_codes')) {
      await queryInterface.createTable('otp_codes', {
        id: {
          type: Sequelize.UUID,
          primaryKey: true,
          defaultValue: Sequelize.UUIDV4,
        },
        phone: {
          type: Sequelize.STRING(20),
          allowNull: false,
        },
        purpose: {
          type: Sequelize.ENUM('login', 'register', 'verify_phone', 'reset_password', 'sensitive_action'),
          allowNull: false,
        },
        codeHash: {
          type: Sequelize.STRING(255),
          allowNull: false,
        },
        expiresAt: {
          type: Sequelize.DATE,
          allowNull: false,
        },
        consumedAt: {
          type: Sequelize.DATE,
          allowNull: true,
        },
        attempts: {
          type: Sequelize.INTEGER,
          allowNull: false,
          defaultValue: 0,
        },
        maxAttempts: {
          type: Sequelize.INTEGER,
          allowNull: false,
          defaultValue: 5,
        },
        region: {
          type: Sequelize.STRING(50),
          allowNull: true,
        },
        channel: {
          type: Sequelize.STRING(20),
          allowNull: false,
          defaultValue: 'sms',
        },
        providerMessageId: {
          type: Sequelize.STRING(255),
          allowNull: true,
        },
        dispatchStatus: {
          type: Sequelize.ENUM('pending', 'sent', 'delivered', 'failed'),
          allowNull: false,
          defaultValue: 'pending',
        },
        ipAddress: {
          type: Sequelize.STRING(45),
          allowNull: true,
        },
        userAgent: {
          type: Sequelize.TEXT,
          allowNull: true,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('otp_codes', ['phone', 'purpose']);
      await queryInterface.addIndex('otp_codes', ['expiresAt']);
      await queryInterface.addIndex('otp_codes', ['createdAt']);
    }

    // ============================================================
    // 3. BRANDS TABLE
    // ============================================================
    if (!tables.includes('brands')) {
      await queryInterface.createTable('brands', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        name: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        location: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
    } else {
      // Table exists - check and add missing columns
      console.log('[Migration] brands table exists, checking for missing columns...');
      let tableDescription;
      try {
        tableDescription = await queryInterface.describeTable('brands');
      } catch (e) {
        console.error('[Migration] Failed to describe brands table:', e.message);
        throw e;
      }
      
      const columnsToAdd = {};
      const existingColumns = Object.keys(tableDescription);

      // Check and add name column if missing
      if (!existingColumns.includes('name')) {
        columnsToAdd.name = {
          type: Sequelize.STRING,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: name');
      }

      // Check and add location column if missing
      if (!existingColumns.includes('location')) {
        columnsToAdd.location = {
          type: Sequelize.STRING,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: location');
      }

      // Add all missing columns
      if (Object.keys(columnsToAdd).length > 0) {
        console.log(`[Migration] Adding ${Object.keys(columnsToAdd).length} missing column(s) to brands table...`);
        for (const [columnName, columnDef] of Object.entries(columnsToAdd)) {
          try {
            await queryInterface.addColumn('brands', columnName, columnDef);
            console.log(`[Migration] ✓ Added column: ${columnName}`);
          } catch (e) {
            console.error(`[Migration] Failed to add column ${columnName}:`, e.message);
            // Continue with other columns
          }
        }
      } else {
        console.log('[Migration] All required columns exist in brands table');
      }
    }

    // ============================================================
    // 4. MODELS TABLE
    // ============================================================
    if (!tables.includes('models')) {
      await queryInterface.createTable('models', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        name: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        brandId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'brands', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        yearstart: {
          type: Sequelize.INTEGER,
          allowNull: true,
        },
        yearend: {
          type: Sequelize.INTEGER,
          allowNull: true,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('models', ['brandId']);
    } else {
      // Table exists - check and add missing columns
      console.log('[Migration] models table exists, checking for missing columns...');
      let tableDescription;
      try {
        tableDescription = await queryInterface.describeTable('models');
      } catch (e) {
        console.error('[Migration] Failed to describe models table:', e.message);
        throw e;
      }
      
      const columnsToAdd = {};
      const existingColumns = Object.keys(tableDescription);

      // Check and add name column if missing
      if (!existingColumns.includes('name')) {
        columnsToAdd.name = {
          type: Sequelize.STRING,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: name');
      }

      // Check and add brandId column if missing (might be brandId or brandsId)
      if (!existingColumns.includes('brandId') && !existingColumns.includes('brandsId')) {
        columnsToAdd.brandId = {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'brands', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        };
        console.log('[Migration] Will add missing column: brandId');
      } else if (existingColumns.includes('brandsId') && !existingColumns.includes('brandId')) {
        // Rename brandsId to brandId for consistency
        console.log('[Migration] Will rename column: brandsId → brandId');
        try {
          await queryInterface.renameColumn('models', 'brandsId', 'brandId');
        } catch (e) {
          console.error('[Migration] Failed to rename brandsId:', e.message);
        }
      }

      // Check and add yearstart column if missing
      if (!existingColumns.includes('yearstart')) {
        columnsToAdd.yearstart = {
          type: Sequelize.INTEGER,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: yearstart');
      }

      // Check and add yearend column if missing
      if (!existingColumns.includes('yearend')) {
        columnsToAdd.yearend = {
          type: Sequelize.INTEGER,
          allowNull: true,
        };
        console.log('[Migration] Will add missing column: yearend');
      }

      // Add all missing columns
      if (Object.keys(columnsToAdd).length > 0) {
        console.log(`[Migration] Adding ${Object.keys(columnsToAdd).length} missing column(s) to models table...`);
        for (const [columnName, columnDef] of Object.entries(columnsToAdd)) {
          try {
            await queryInterface.addColumn('models', columnName, columnDef);
            console.log(`[Migration] ✓ Added column: ${columnName}`);
          } catch (e) {
            console.error(`[Migration] Failed to add column ${columnName}:`, e.message);
            // Continue with other columns
          }
        }
      } else {
        console.log('[Migration] All required columns exist in models table');
      }

      // Ensure index exists
      try {
        const indexes = await queryInterface.showIndex('models');
        const hasBrandIndex = indexes.some(idx => 
          idx.fields && idx.fields.some(f => 
            (f.attribute === 'brandId' || f.attribute === 'brandsId')
          )
        );

        if (!hasBrandIndex) {
          await queryInterface.addIndex('models', ['brandId']);
          console.log('[Migration] ✓ Added index on brandId');
        }
      } catch (e) {
        // Index check might fail, try to add anyway
        try {
          await queryInterface.addIndex('models', ['brandId']);
        } catch (e2) {
          // Index might already exist, ignore
        }
      }
    }

    // ============================================================
    // 5. BANNERS TABLE
    // ============================================================
    if (!tables.includes('banners')) {
      await queryInterface.createTable('banners', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        creator: {
          type: Sequelize.JSONB,
          allowNull: false,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
    }

    // ============================================================
    // 6. CATEGORIES TABLE
    // ============================================================
    if (!tables.includes('categories')) {
      await queryInterface.createTable('categories', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        name: {
          type: Sequelize.JSONB,
          allowNull: false,
        },
        creator: {
          type: Sequelize.JSONB,
          allowNull: false,
        },
        priority: {
          type: Sequelize.INTEGER,
          allowNull: true,
          unique: true,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
    }

    // ============================================================
    // 7. SUBSCRIPTIONS TABLE
    // ============================================================
    if (!tables.includes('subscriptions')) {
      await queryInterface.createTable('subscriptions', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        name: {
          type: Sequelize.JSONB,
          allowNull: false,
        },
        priority: {
          type: Sequelize.INTEGER,
          allowNull: true,
          unique: true,
        },
        price: {
          type: Sequelize.DECIMAL(14, 2),
          allowNull: true,
        },
        color: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        description: {
          type: Sequelize.JSONB,
          allowNull: false,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
    }

    // ============================================================
    // 8. POSTS TABLE
    // ============================================================
    if (!tables.includes('posts')) {
      await queryInterface.createTable('posts', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        brandsId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'brands', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        modelsId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'models', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        categoryId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'categories', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        subscriptionId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'subscriptions', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        userId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'users', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        condition: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        transmission: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        engineType: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        enginePower: {
          type: Sequelize.DOUBLE,
          allowNull: true,
        },
        year: {
          type: Sequelize.INTEGER,
          allowNull: true,
        },
        milleage: {
          type: Sequelize.DOUBLE,
          allowNull: true,
        },
        vin: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        originalPrice: {
          type: Sequelize.DOUBLE,
          allowNull: true,
        },
        price: {
          type: Sequelize.DOUBLE,
          allowNull: true,
        },
        originalCurrency: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        currency: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        personalInfo: {
          type: Sequelize.JSON,
          allowNull: true,
        },
        description: {
          type: Sequelize.TEXT,
          allowNull: true,
        },
        location: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        status: {
          type: Sequelize.BOOLEAN,
          allowNull: true,
        },
        credit: {
          type: Sequelize.BOOLEAN,
          allowNull: true,
          defaultValue: false,
        },
        exchange: {
          type: Sequelize.BOOLEAN,
          allowNull: true,
          defaultValue: true,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('posts', ['brandsId']);
      await queryInterface.addIndex('posts', ['modelsId']);
      await queryInterface.addIndex('posts', ['userId']);
      await queryInterface.addIndex('posts', ['categoryId']);
    } else {
      // Table exists - check and add missing columns
      console.log('[Migration] posts table exists, checking for missing columns...');
      let tableDescription;
      try {
        tableDescription = await queryInterface.describeTable('posts');
      } catch (e) {
        console.error('[Migration] Failed to describe posts table:', e.message);
        throw e;
      }
      
      const columnsToAdd = {};
      const existingColumns = Object.keys(tableDescription);

      // Handle brandId vs brandsId mismatch
      if (existingColumns.includes('brandId') && !existingColumns.includes('brandsId')) {
        console.log('[Migration] Will rename column: brandId → brandsId');
        try {
          await queryInterface.renameColumn('posts', 'brandId', 'brandsId');
          existingColumns.push('brandsId');
          existingColumns.splice(existingColumns.indexOf('brandId'), 1);
        } catch (e) {
          console.error('[Migration] Failed to rename brandId:', e.message);
        }
      }

      // Check and add missing columns
      const expectedColumns = {
        brandsId: { type: Sequelize.STRING, allowNull: true },
        modelsId: { type: Sequelize.STRING, allowNull: true },
        categoryId: { type: Sequelize.STRING, allowNull: true },
        subscriptionId: { type: Sequelize.STRING, allowNull: true },
        userId: { type: Sequelize.STRING, allowNull: true },
        transmission: { type: Sequelize.STRING, allowNull: true },
        originalPrice: { type: Sequelize.DOUBLE, allowNull: true },
        originalCurrency: { type: Sequelize.STRING, allowNull: true },
        location: { type: Sequelize.STRING, allowNull: true },
        status: { type: Sequelize.BOOLEAN, allowNull: true },
        credit: { type: Sequelize.BOOLEAN, allowNull: true, defaultValue: false },
        exchange: { type: Sequelize.BOOLEAN, allowNull: true, defaultValue: true },
      };

      for (const [columnName, columnDef] of Object.entries(expectedColumns)) {
        if (!existingColumns.includes(columnName)) {
          columnsToAdd[columnName] = columnDef;
          console.log(`[Migration] Will add missing column: ${columnName}`);
        }
      }

      // Add all missing columns
      if (Object.keys(columnsToAdd).length > 0) {
        console.log(`[Migration] Adding ${Object.keys(columnsToAdd).length} missing column(s) to posts table...`);
        for (const [columnName, columnDef] of Object.entries(columnsToAdd)) {
          try {
            await queryInterface.addColumn('posts', columnName, columnDef);
            console.log(`[Migration] ✓ Added column: ${columnName}`);
          } catch (e) {
            console.error(`[Migration] Failed to add column ${columnName}:`, e.message);
            // Continue with other columns
          }
        }
      } else {
        console.log('[Migration] All required columns exist in posts table');
      }

      // Ensure indexes exist
      try {
        const indexes = await queryInterface.showIndex('posts');
        const indexFields = ['brandsId', 'modelsId', 'userId', 'categoryId'];
        for (const field of indexFields) {
          const hasIndex = indexes.some(idx => 
            idx.fields && idx.fields.some(f => f.attribute === field)
          );
          if (!hasIndex) {
            try {
              await queryInterface.addIndex('posts', [field]);
              console.log(`[Migration] ✓ Added index on ${field}`);
            } catch (e) {
              // Index might already exist, ignore
            }
          }
        }
      } catch (e) {
        // Index check might fail, continue
      }
    }

    // ============================================================
    // 9. VLOGS TABLE
    // ============================================================
    if (!tables.includes('vlogs')) {
      await queryInterface.createTable('vlogs', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        title: {
          type: Sequelize.STRING,
          allowNull: false,
        },
        description: {
          type: Sequelize.TEXT,
          allowNull: true,
        },
        tag: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        videoUrl: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        isActive: {
          type: Sequelize.BOOLEAN,
          allowNull: false,
          defaultValue: false,
        },
        thumbnail: {
          type: Sequelize.JSON,
          allowNull: true,
        },
        userId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'users', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        status: {
          type: Sequelize.ENUM('Pending', 'Accepted', 'Declined'),
          allowNull: false,
          defaultValue: 'Pending',
        },
        declineMessage: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('vlogs', ['userId']);
    }

    // ============================================================
    // 10. COMMENTS TABLE
    // ============================================================
    if (!tables.includes('comments')) {
      await queryInterface.createTable('comments', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        message: {
          type: Sequelize.STRING(1000),
          allowNull: false,
        },
        status: {
          type: Sequelize.BOOLEAN,
          allowNull: true,
        },
        userId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'users', key: 'uuid' },
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
          references: { model: 'posts', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        replyTo: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'comments', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('comments', ['postId']);
      await queryInterface.addIndex('comments', ['userId']);
    }

    // ============================================================
    // 11. SUBSCRIPTION_ORDER TABLE
    // ============================================================
    if (!tables.includes('subscription_order')) {
      await queryInterface.createTable('subscription_order', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        location: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        phone: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        status: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        subscriptionId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'subscriptions', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('subscription_order', ['subscriptionId']);
    }

    // ============================================================
    // 12. PHOTO TABLE
    // ============================================================
    if (!tables.includes('photo')) {
      await queryInterface.createTable('photo', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        path: {
          type: Sequelize.JSONB,
          allowNull: true,
        },
        originalPath: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        bannerId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'banners', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        categoryId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'categories', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        subscriptionId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'subscriptions', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        brandsId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'brands', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        modelsId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'models', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        userId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'users', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('photo', ['userId']);
    }

    // ============================================================
    // 13. VIDEO TABLE
    // ============================================================
    if (!tables.includes('video')) {
      await queryInterface.createTable('video', {
        id: {
          type: Sequelize.BIGINT,
          autoIncrement: true,
          primaryKey: true,
        },
        url: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        postId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'posts', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('video', ['postId']);
    }

    // ============================================================
    // 14. FILE TABLE
    // ============================================================
    if (!tables.includes('file')) {
      await queryInterface.createTable('file', {
        uuid: {
          type: Sequelize.STRING,
          primaryKey: true,
          allowNull: false,
        },
        path: {
          type: Sequelize.STRING,
          allowNull: true,
        },
        postId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'posts', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('file', ['postId']);
    }

    // ============================================================
    // 15. CONVERT_PRICES TABLE
    // ============================================================
    if (!tables.includes('convert_prices')) {
      await queryInterface.createTable('convert_prices', {
        id: {
          type: Sequelize.BIGINT,
          autoIncrement: true,
          primaryKey: true,
        },
        label: {
          type: Sequelize.STRING,
          allowNull: false,
          unique: true,
        },
        rate: {
          type: Sequelize.DECIMAL(18, 6),
          allowNull: false,
        },
      });
      await queryInterface.addIndex('convert_prices', ['label'], { unique: true });
    }

    // ============================================================
    // 16. NOTIFICATION_HISTORY TABLE
    // ============================================================
    if (!tables.includes('notification_history')) {
      await queryInterface.createTable('notification_history', {
        uuid: {
          type: Sequelize.UUID,
          primaryKey: true,
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
          type: Sequelize.ENUM('all_users', 'brand_subscribers', 'specific_user', 'topic'),
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
          references: { model: 'users', key: 'uuid' },
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
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
        updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.fn('NOW'),
        },
      });
      await queryInterface.addIndex('notification_history', ['type']);
      await queryInterface.addIndex('notification_history', ['status']);
      await queryInterface.addIndex('notification_history', ['sentBy']);
      await queryInterface.addIndex('notification_history', ['createdAt']);
    }

    // ============================================================
    // 17. JUNCTION TABLES
    // ============================================================

    // brands_user
    if (!tables.includes('brands_user')) {
      await queryInterface.createTable('brands_user', {
        id: {
          type: Sequelize.BIGINT,
          autoIncrement: true,
          primaryKey: true,
        },
        userId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'users', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        brandId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'brands', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
      });
      await queryInterface.addConstraint('brands_user', {
        fields: ['brandId', 'userId'],
        type: 'unique',
        name: 'uq_brands_user_brand_user',
      });
    }

    // photo_posts
    if (!tables.includes('photo_posts')) {
      await queryInterface.createTable('photo_posts', {
        id: {
          type: Sequelize.BIGINT,
          autoIncrement: true,
          primaryKey: true,
        },
        postId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'posts', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        photoUuid: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'photo', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
      });
      await queryInterface.addIndex('photo_posts', ['postId']);
    }

    // photo_vlogs
    if (!tables.includes('photo_vlogs')) {
      await queryInterface.createTable('photo_vlogs', {
        id: {
          type: Sequelize.BIGINT,
          autoIncrement: true,
          primaryKey: true,
        },
        vlogId: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'vlogs', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        photoUuid: {
          type: Sequelize.STRING,
          allowNull: true,
          references: { model: 'photo', key: 'uuid' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
      });
      await queryInterface.addIndex('photo_vlogs', ['vlogId']);
    }
  },

  async down(queryInterface) {
    // Drop in reverse dependency order
    await queryInterface.dropTable('photo_vlogs');
    await queryInterface.dropTable('photo_posts');
    await queryInterface.dropTable('brands_user');
    await queryInterface.dropTable('notification_history');
    await queryInterface.dropTable('convert_prices');
    await queryInterface.dropTable('file');
    await queryInterface.dropTable('video');
    await queryInterface.dropTable('photo');
    await queryInterface.dropTable('subscription_order');
    await queryInterface.dropTable('comments');
    await queryInterface.dropTable('vlogs');
    await queryInterface.dropTable('posts');
    await queryInterface.dropTable('subscriptions');
    await queryInterface.dropTable('categories');
    await queryInterface.dropTable('banners');
    await queryInterface.dropTable('models');
    await queryInterface.dropTable('brands');
    await queryInterface.dropTable('otp_codes');
    await queryInterface.dropTable('users');
  },
};
