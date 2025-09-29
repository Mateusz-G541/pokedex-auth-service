#!/usr/bin/env node

/**
 * Seed script to create initial admin user
 * Run: node scripts/seed-admin.js
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function seedAdmin() {
  try {
    // Get admin credentials from environment or use defaults
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@pokedex.com';
    const adminPassword = process.env.ADMIN_PASSWORD || 'AdminPass123!';
    const bcryptRounds = parseInt(process.env.BCRYPT_ROUNDS || '12');

    console.log('Checking for existing admin user...');

    // Check if admin already exists
    const existingAdmin = await prisma.user.findUnique({
      where: { email: adminEmail }
    });

    if (existingAdmin) {
      console.log(`Admin user already exists: ${adminEmail}`);
      
      // Update to ensure it's an admin
      if (existingAdmin.role !== 'ADMINISTRATOR') {
        await prisma.user.update({
          where: { email: adminEmail },
          data: { role: 'ADMINISTRATOR' }
        });
        console.log('Updated existing user to ADMINISTRATOR role');
      }
      
      return;
    }

    console.log('Creating admin user...');

    // Hash password
    const hashedPassword = await bcrypt.hash(adminPassword, bcryptRounds);

    // Create admin user
    const admin = await prisma.user.create({
      data: {
        email: adminEmail,
        password: hashedPassword,
        role: 'ADMINISTRATOR',
        isActive: true
      }
    });

    console.log('✅ Admin user created successfully!');
    console.log('Email:', admin.email);
    console.log('Role:', admin.role);
    console.log('');
    console.log('⚠️  IMPORTANT: Change the default password after first login!');
    
  } catch (error) {
    console.error('Error seeding admin user:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the seed function
seedAdmin();
