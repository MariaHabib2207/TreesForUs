# ==============================================================================
# db/seeds.rb — TreeOfUs Family Hierarchy System
# ==============================================================================
# Run with:       rails db:seed
# Full reset:     rails db:drop db:create db:migrate db:seed
# ==============================================================================

# Disable all email delivery during seeding
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = false

puts "🌱 Seeding TreeOfUs database..."
puts "=" * 60

# ------------------------------------------------------------------------------
# CLEAN SLATE — clear in reverse dependency order
# ------------------------------------------------------------------------------
puts "\n🧹 Clearing existing data..."

PublicActivity::Activity.destroy_all if ActiveRecord::Base.connection.table_exists?(:activities)
UserPartner.destroy_all
UserParentRelationship.destroy_all
FamilyCode.destroy_all
FamilyMembership.destroy_all
UserProfile.destroy_all
Family.destroy_all
User.destroy_all
AdminUser.destroy_all

puts "   ✓ All records cleared"

# ==============================================================================
# 1. ADMIN USER  (ActiveAdmin panel)
# ==============================================================================
puts "\n👑 Creating admin user..."

AdminUser.create!(
  email:                 "admin@treesfor.us",
  password:              "admin123456",
  password_confirmation: "admin123456"
)
AdminUser.create!(
  email:                 "admin@trees-for-us.com",
  password:              "admin123456",
  password_confirmation: "admin123456"
)

puts "   ✓ AdminUser created → admin@treesfor.us / admin123456"

# ==============================================================================
# 2. USERS
# ==============================================================================
# Schema columns on users:
#   first_name (string, NOT NULL)
#   last_name  (string, NOT NULL)
#   identification_type   (integer enum, default: 0, NOT NULL)
#   identification_number (string, NOT NULL, unique with id_type)
#   status  (integer enum, default: 0, NOT NULL)
#   role    (integer enum, default: 0, NOT NULL)
#   email, encrypted_password, … (Devise)
#   login_enabled (boolean, default: false)
# ==============================================================================
puts "\n👤 Creating users..."

# ── Generation 1 — Grandparents ───────────────────────────────────────────────
george = User.create!(
  first_name:            "George",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-GH-1945",
  email:                 "george.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

margaret = User.create!(
  first_name:            "Margaret",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-MH-1948",
  email:                 "margaret.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

# ── Generation 2 — Parents ────────────────────────────────────────────────────
ali = User.create!(
  first_name:            "Ali",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-AH-1972",
  email:                 "ali.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

sara = User.create!(
  first_name:            "Sara",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-SH-1975",
  email:                 "sara.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

zainab = User.create!(
  first_name:            "Zainab",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-ZH-1978",
  email:                 "zainab.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

omar = User.create!(
  first_name:            "Omar",
  last_name:             "Khalil",
  identification_type:   :nric,
  identification_number: "ID-OK-1974",
  email:                 "omar.khalil@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

# ── Generation 3 — Children ───────────────────────────────────────────────────
maria = User.create!(
  first_name:            "Maria",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-MRH-2000",
  email:                 "maria.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

yusuf = User.create!(
  first_name:            "Yusuf",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-YH-2003",
  email:                 "yusuf.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

layla = User.create!(
  first_name:            "Layla",
  last_name:             "John",
  identification_type:   :nric,
  identification_number: "ID-LH-2005",
  email:                 "layla.john@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

hana = User.create!(
  first_name:            "Hana",
  last_name:             "Khalil",
  identification_type:   :nric,
  identification_number: "ID-HK-2002",
  email:                 "hana.khalil@example.com",
  password:              "password123",
  password_confirmation: "password123",
  login_enabled:         true,
  status:                :alive,
  role:                  :family_manager
)

puts "   ✓ #{User.count} users created"

# ==============================================================================
# 3. USER PROFILES
# ==============================================================================
# Schema columns on user_profiles:
#   user_id (FK), birth_date, gender, marital_status, occupation,
#   address, city, state, zip, country, phone, nationality,
#   current_status, created_by, updated_by
# NOTE: first_name / last_name live on users, NOT here
# ==============================================================================
puts "\n📋 Creating user profiles..."

UserProfile.create!([
  # Generation 1
  {
    user:           george,
    birth_date:     Date.new(1945, 3, 12),
    gender:         "male",
    marital_status: "married",
    occupation:     "Retired Engineer",
    city:           "Beirut",
    country:        "Lebanon",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     george.id
  },
  {
    user:           margaret,
    birth_date:     Date.new(1948, 7, 22),
    gender:         "female",
    marital_status: "married",
    occupation:     "Retired Teacher",
    city:           "Beirut",
    country:        "Lebanon",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     george.id
  },

  # Generation 2
  {
    user:           ali,
    birth_date:     Date.new(1972, 11, 5),
    gender:         "male",
    marital_status: "married",
    occupation:     "Software Engineer",
    city:           "Dubai",
    country:        "UAE",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     george.id
  },
  {
    user:           sara,
    birth_date:     Date.new(1975, 4, 18),
    gender:         "female",
    marital_status: "married",
    occupation:     "Doctor",
    city:           "Dubai",
    country:        "UAE",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     ali.id
  },
  {
    user:           zainab,
    birth_date:     Date.new(1978, 9, 30),
    gender:         "female",
    marital_status: "married",
    occupation:     "Artist",
    city:           "London",
    country:        "UK",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     george.id
  },
  {
    user:           omar,
    birth_date:     Date.new(1974, 2, 14),
    gender:         "male",
    marital_status: "married",
    occupation:     "Architect",
    city:           "London",
    country:        "UK",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     zainab.id
  },

  # Generation 3
  {
    user:           maria,
    birth_date:     Date.new(2000, 6, 21),
    gender:         "female",
    marital_status: "single",
    occupation:     "Student",
    city:           "Dubai",
    country:        "UAE",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     ali.id
  },
  {
    user:           yusuf,
    birth_date:     Date.new(2003, 1, 8),
    gender:         "male",
    marital_status: "single",
    occupation:     "Student",
    city:           "Dubai",
    country:        "UAE",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     ali.id
  },
  {
    user:           layla,
    birth_date:     Date.new(2005, 10, 3),
    gender:         "female",
    marital_status: "single",
    occupation:     "Student",
    city:           "Dubai",
    country:        "UAE",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     ali.id
  },
  {
    user:           hana,
    birth_date:     Date.new(2002, 8, 16),
    gender:         "female",
    marital_status: "single",
    occupation:     "Student",
    city:           "London",
    country:        "UK",
    nationality:    "Lebanese",
    current_status: "alive",
    created_by:     omar.id
  }
])

puts "   ✓ #{UserProfile.count} profiles created"

# ==============================================================================
# 4. FAMILIES
# ==============================================================================
puts "\n🏡 Creating families..."

john_family = Family.create!(name: "The John Family")
khalil_family = Family.create!(name: "The Khalil Family")

puts "   ✓ #{Family.count} families created"

# ==============================================================================
# 5. FAMILY MEMBERSHIPS
# ==============================================================================
# membership_type is an integer enum — 0 = admin, 1 = member (adjust if
# your enum is defined differently in the model)
# ==============================================================================
puts "\n🔗 Creating family memberships..."

FamilyMembership.create!([
  # John family
  { user: george,   family: john_family,  membership_type: 0 }, # admin
  { user: margaret, family: john_family,  membership_type: 1 },
  { user: ali,      family: john_family,  membership_type: 1 },
  { user: sara,     family: john_family,  membership_type: 1 },
  { user: zainab,   family: john_family,  membership_type: 1 },
  { user: maria,    family: john_family,  membership_type: 1 },
  { user: yusuf,    family: john_family,  membership_type: 1 },
  { user: layla,    family: john_family,  membership_type: 1 },

  # Khalil family
  { user: omar,     family: khalil_family, membership_type: 0 }, # admin
  { user: zainab,   family: khalil_family, membership_type: 1 },
  { user: hana,     family: khalil_family, membership_type: 1 }
])

puts "   ✓ #{FamilyMembership.count} memberships created"

# ==============================================================================
# 6. PARENT-CHILD RELATIONSHIPS
# ==============================================================================
# Table: user_parent_child_relationships  (parent_id, child_id)
#
#   George + Margaret
#     ├── Ali   (+ Sara)
#     │     ├── Maria
#     │     ├── Yusuf
#     │     └── Layla
#     └── Zainab  (+ Omar)
#           └── Hana
# ==============================================================================
puts "\n🌳 Creating parent-child relationships..."

[
  [ george,   ali ],
  [ margaret, ali ],
  [ george,   zainab ],
  [ margaret, zainab ],
  [ ali,      maria ],
  [ sara,     maria ],
  [ ali,      yusuf ],
  [ sara,     yusuf ],
  [ ali,      layla ],
  [ sara,     layla ],
  [ omar,     hana ],
  [ zainab,   hana ]
].each do |parent, child|
  UserParentRelationship.create!(parent_id: parent.id, child_id: child.id)
end

puts "   ✓ #{UserParentRelationship.count} parent-child relationships created"

# ==============================================================================
# 7. PARTNER RELATIONSHIPS
# ==============================================================================
# Table: user_partners  (user_id, partner_id)  — no extra columns per schema
# ==============================================================================
puts "\n💑 Creating partner relationships..."

UserPartner.create!([
  { user: george, partner: margaret },
  { user: ali,    partner: sara     },
  { user: omar,   partner: zainab   }
])

puts "   ✓ #{UserPartner.count} partner relationships created"

# ==============================================================================
# SUMMARY
# ==============================================================================
puts "\n" + "=" * 60
puts "✅ Seeding complete!\n"
puts "   AdminUsers:                   #{AdminUser.count}"
puts "   Users:                        #{User.count}"
puts "   UserProfiles:                 #{UserProfile.count}"
puts "   Families:                     #{Family.count}"
puts "   FamilyMemberships:            #{FamilyMembership.count}"
puts "   UserParentRelationships: #{UserParentRelationship.count}"
puts "   UserPartners:                 #{UserPartner.count}"
puts "\n🌳 Tree structure:"
puts "   George & Margaret John  (grandparents)"
puts "     ├── Ali + Sara  →  Maria, Yusuf, Layla"
puts "     └── Zainab + Omar Khalil  →  Hana"
puts "\n🔑 Login credentials:"
puts "   Admin panel → admin@treesfor.us   / admin123456"
puts "   All users   → <their email above> / password123"
puts "=" * 60
