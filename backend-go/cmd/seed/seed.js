// ===============================================
// MahalFlow MongoDB Data Seeder (mongosh)
// Database: mongodb://localhost:27017/mahalflow
// ===============================================

const db = db.getSiblingDB("mahalflow");

print("🚀 Connecting to MongoDB database: mahalflow");

// 1. Clean existing collections
print("🧹 Cleaning existing collections...");
db.mahals.drop();
db.members.drop();
db.transactions.drop();
db.receipts.drop();
db.audit_logs.drop();

// 2. Create Indexes
print("⚙️ Ensuring collection indexes...");
db.transactions.createIndex({ idempotency_key: 1 }, { unique: true });
db.transactions.createIndex({ mahal_id: 1, status: 1, created_at: -1 });

db.receipts.createIndex({ receipt_number: 1 }, { unique: true });
db.receipts.createIndex({ mahal_id: 1, sequence_number: 1 }, { unique: true });
db.receipts.createIndex({ member_id: 1, created_at: -1 });

db.members.createIndex({ mahal_id: 1, phone: 1 }, { unique: true });
db.members.createIndex({ mahal_id: 1, member_code: 1 }, { unique: true });

// 3. Seed Mahals
print("🏛️ Seeding Mahals...");
db.mahals.insertMany([
  {
    _id: "MH_001_CALICUT",
    name: "Central Juma Masjid Mahal",
    registration_number: "REG/KL/2024/0912",
    contact: {
      email: "committee@townmasjid.org",
      phone: "+919847123456",
      address: "Main Road, Calicut, Kerala 673001"
    },
    settings: {
      currency: "INR",
      default_monthly_dues: 500.0,
      dunning_enabled: true,
      preferred_languages: ["ml", "en"],
      autopay_allowed: true
    },
    subscription: {
      plan: "STANDARD_MONTHLY",
      monthly_fee: 499.0,
      status: "ACTIVE",
      next_billing_date: new Date("2026-09-01T00:00:00Z")
    },
    created_at: new Date("2026-01-01T00:00:00Z"),
    updated_at: new Date()
  },
  {
    _id: "MH_002_KOCHI",
    name: "Al-Huda Community Center Mahal",
    registration_number: "REG/KL/2023/1104",
    contact: {
      email: "admin@alhuda-kochi.org",
      phone: "+919847654321",
      address: "MG Road, Kochi, Kerala 682016"
    },
    settings: {
      currency: "INR",
      default_monthly_dues: 600.0,
      dunning_enabled: true,
      preferred_languages: ["ml", "en"],
      autopay_allowed: true
    },
    subscription: {
      plan: "PREMIUM_MONTHLY",
      monthly_fee: 799.0,
      status: "GRACE_PERIOD",
      next_billing_date: new Date("2026-08-30T00:00:00Z")
    },
    created_at: new Date("2026-01-01T00:00:00Z"),
    updated_at: new Date()
  }
]);

// 4. Seed Members
print("👥 Seeding Members for MH_001_CALICUT...");
db.members.insertMany([
  {
    _id: "MEM_001_9910",
    mahal_id: "MH_001_CALICUT",
    member_code: "M-101",
    name: "Muhammed Ameen",
    phone: "+919847111222",
    house_name: "Darul Aman",
    family_head: true,
    family_members_count: 4,
    monthly_dues_custom_amount: 500.0,
    status: "ACTIVE",
    last_paid_month: "2026-05", // 3 months overdue (Jun, Jul, Aug = ₹1,500)
    outstanding_balance: 1500.0,
    version: 1,
    created_at: new Date("2026-01-10T00:00:00Z"),
    updated_at: new Date()
  },
  {
    _id: "MEM_001_9911",
    mahal_id: "MH_001_CALICUT",
    member_code: "M-102",
    name: "Abdul Rahman",
    phone: "+919847333444",
    house_name: "Baitul Noor",
    family_head: true,
    family_members_count: 5,
    monthly_dues_custom_amount: 500.0,
    status: "ACTIVE",
    last_paid_month: "2026-08", // Fully paid up to date
    outstanding_balance: 0.0,
    version: 1,
    created_at: new Date("2026-01-10T00:00:00Z"),
    updated_at: new Date()
  },
  {
    _id: "MEM_001_9912",
    mahal_id: "MH_001_CALICUT",
    member_code: "M-103",
    name: "Faisal K.V.",
    phone: "+919847555666",
    house_name: "Green Valley",
    family_head: true,
    family_members_count: 3,
    monthly_dues_custom_amount: 500.0,
    status: "ACTIVE",
    last_paid_month: "2026-07", // 1 month overdue (Aug = ₹500)
    outstanding_balance: 500.0,
    version: 1,
    created_at: new Date("2026-02-01T00:00:00Z"),
    updated_at: new Date()
  },
  {
    _id: "MEM_001_9913",
    mahal_id: "MH_001_CALICUT",
    member_code: "M-104",
    name: "Zubair Ahmed",
    phone: "+919847777888",
    house_name: "Al-Burooj",
    family_head: true,
    family_members_count: 6,
    monthly_dues_custom_amount: 500.0,
    status: "ACTIVE",
    last_paid_month: "2026-06", // 2 months overdue (Jul, Aug = ₹1,000)
    outstanding_balance: 1000.0,
    version: 1,
    created_at: new Date("2026-02-15T00:00:00Z"),
    updated_at: new Date()
  }
]);

// 5. Seed Chained Cryptographic Receipts (SHA-256)
print("📜 Seeding Cryptographic Chained Receipts...");
db.receipts.insertMany([
  {
    _id: "RCPT_001",
    receipt_number: "GV1MH00120260515R00001",
    sequence_number: NumberLong(1),
    mahal_id: "MH_001_CALICUT",
    member_id: "MEM_001_9910",
    member_name: "Muhammed Ameen",
    transaction_id: "TXN_HIST_01",
    payment_type: "MONTHLY_DUES",
    paid_months: ["2026-05"],
    amount: 500.0,
    previous_receipt_hash: "0000000000000000000000000000000000000000000000000000000000000000",
    receipt_hash: "a8f5f167f44f4964e6c998dee827110c59828d9c6328a6f3b798782f9547d6e1",
    created_at: new Date("2026-05-15T10:00:00Z")
  },
  {
    _id: "RCPT_002",
    receipt_number: "GV1MH00120260801R00002",
    sequence_number: NumberLong(2),
    mahal_id: "MH_001_CALICUT",
    member_id: "MEM_001_9911",
    member_name: "Abdul Rahman",
    transaction_id: "TXN_HIST_02",
    payment_type: "MONTHLY_DUES",
    paid_months: ["2026-07", "2026-08"],
    amount: 1000.0,
    previous_receipt_hash: "a8f5f167f44f4964e6c998dee827110c59828d9c6328a6f3b798782f9547d6e1",
    receipt_hash: "c9e2b14498fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852c9a2",
    created_at: new Date("2026-08-01T11:30:00Z")
  }
]);

// 6. Seed Audit Log
print("🛡️ Seeding Audit Trail Log...");
db.audit_logs.insertOne({
  _id: "AUD_INIT_001",
  mahal_id: "MH_001_CALICUT",
  actor: { user_id: "SYS_SEEDER", role: "SUPER_ADMIN" },
  category: "SYSTEM_INIT",
  action: "DATABASE_SEEDED",
  entity_type: "database",
  entity_id: "mahalflow",
  timestamp: new Date()
});

print("✨ MongoDB Seeding Complete!");
print("• Mahals count: " + db.mahals.countDocuments());
print("• Members count: " + db.members.countDocuments());
print("• Receipts count: " + db.receipts.countDocuments());
print("• Audit logs count: " + db.audit_logs.countDocuments());
