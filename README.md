# 🌳 TreesForUs

A **Family Hierarchy Management System** built with Ruby on Rails. TreesForUs allows families to map, manage, and visualize their family trees — tracking members, relationships, generational hierarchies, and access roles all in one place.
---
Detailed Documentation At : (https://docs.google.com/document/d/1FRlTcXSPeLLuZU8SQGo2VLqj871elEDubcBH2bjOLlk/edit?tab=t.0)

<img width="1678" height="889" alt="Screenshot 2026-06-05 at 8 57 27 AM" src="https://github.com/user-attachments/assets/78c503f8-1e5e-4d17-819a-9c7a9e7a36e5" />
<img width="1449" height="740" alt="Screenshot 2026-06-05 at 8 58 13 AM" src="https://github.com/user-attachments/assets/79afba43-18ef-4103-be9b-fee5f8c9b30e" />


## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [Running the App](#running-the-app)
- [Running Tests](#running-tests)
- [User Roles](#user-roles)
- [Key Models](#key-models)
- [Contributing](#contributing)

---

## Overview

TreesForUs is a web application that lets families build and manage their family hierarchy. Users can be added as tree-only members (without login access) or as full login-enabled members. The system supports parent-child relationships, spouse/partner links, and family group memberships, all with role-based access control.

---

## Features

- **Family Tree Management** — Add, view, and manage family members across multiple generations
- **Parent / Child Relationships** — Link members in parent-child hierarchies
- **Partner Relationships** — Track spousal and partner connections bidirectionally
- **Family Groups** — Organize members into family units (up to 2 families per user)
- **Role-Based Access** — Admin, Family Manager, and Viewer roles
- **Two Member Types** — Login-enabled users and tree-only members
- **User Invitation System** — Invite tree members to create a login account via tokenized email links
- **Google OAuth** — Sign in with Google via OmniAuth
- **User Profiles** — Store personal details including birthdate, nationality, occupation, address, and more
- **Activity Feed** — Track model changes via `public_activity`
- **Admin Dashboard** — Powered by ActiveAdmin
- **Pagination** — Via Kaminari
- **Identification Validation** — Supports NRIC, Passport, Driving License, and Birth Certificate formats
- **Responsive UI** — Built with Tailwind CSS

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.3.5 |
| Framework | Rails 8.0.5 |
| Database | SQLite (development) / PostgreSQL (production) |
| Frontend | Tailwind CSS, Stimulus, Turbo (Hotwire) |
| Templating | Slim |
| Authentication | Devise + OmniAuth (Google OAuth2) |
| Admin | ActiveAdmin |
| Email | Resend / Mailjet |
| Activity | public_activity |
| Pagination | Kaminari |
| Deployment | Kamal / Render / Docker |

---

## Prerequisites

Before you begin, make sure you have the following installed:

- Ruby `3.3.5` (use [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/))
- Bundler (`gem install bundler`)
- Node.js and Yarn
- SQLite3 (development)
- PostgreSQL (production)

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/MariaHabib2207/TreesForUs.git
cd TreesForUs
```

### 2. Install Ruby dependencies

```bash
bundle install
```

### 3. Install JavaScript dependencies

```bash
yarn install
```

### 4. Set up environment variables

Copy the example env file and fill in your values:

```bash
cp .env.example .env
```

See [Environment Variables](#environment-variables) for the full list of required keys.

---

## Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Email (Resend or Mailjet)
RESEND_API_KEY=your_resend_api_key
MAILJET_API_KEY=your_mailjet_api_key
MAILJET_SECRET_KEY=your_mailjet_secret_key

# Rails
RAILS_MASTER_KEY=your_master_key

# Database (production only)
DATABASE_URL=postgresql://user:password@host/dbname
```

---

## Database Setup

```bash
# Create the database
rails db:create

# Run migrations
rails db:migrate

# (Optional) Seed initial data
rails db:seed
```

---

## Running the App

### Development

```bash
bin/dev
```

This starts Rails + Tailwind CSS in watch mode via `Procfile.dev`.

Then visit: [http://localhost:3000](http://localhost:3000)

### With Docker

```bash
docker build -t trees_for_us .
docker run -p 3000:3000 trees_for_us
```

---

## Running Tests

```bash
rails test
```

For system tests (requires Chrome/Selenium):

```bash
rails test:system
```

---

## User Roles

| Role | Description |
|---|---|
| `admin` | Full access — manage all users, families, and settings |
| `family_manager` | Can manage their own family members and relationships |
| `viewer` | Read-only access to the family tree |

Users can also be **tree-only members** (`login_enabled: false`) — they appear in the family tree but cannot log in until invited.

---

## Key Models

### User
Central model representing a person in the system. Supports login-enabled users and tree-only members, with Devise authentication, role management, and identification validation.

### UserProfile
Stores personal details (birthdate, gender, nationality, occupation, address, etc.) associated 1:1 with a user.

### Family & FamilyMembership
Organizes users into family groups. Each user can belong to a maximum of 2 families.

### UserParentRelationship
Tracks parent-child links between users (self-referential through `child_id` and `parent_id`).

### UserPartner
Tracks partner/spousal relationships between users bidirectionally.


## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## License

This project is private. All rights reserved.
