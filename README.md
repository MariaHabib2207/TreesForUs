# 🌳 TreesForUs

**Live Demo:** https://tree-of-us.up.railway.app/

TreesForUs is a modern **Ruby on Rails 8** social networking application that helps families stay connected by building interactive family trees, preserving memories, and communicating in real time. Users can create multi-generational family hierarchies, maintain a personal friends network, share life activities, and chat instantly using Rails Action Cable.

---

## 📖 Documentation

**Detailed Documentation:**  
https://docs.google.com/document/d/1FRlTcXSPeLLuZU8SQGo2VLqj871elEDubcBH2bjOLlk/edit?tab=t.0

---

## 📸 Screenshots

<img width="1678" height="889" alt="Home" src="https://github.com/user-attachments/assets/78c503f8-1e5e-4d17-819a-9c7a9e7a36e5" />

<img width="1449" height="740" alt="Family Tree" src="https://github.com/user-attachments/assets/79afba43-18ef-4103-be9b-fee5f8c9b30e" />

---

# Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture Highlights](#architecture-highlights)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [Testing](#testing)
- [Core Models](#core-models)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

# Overview

TreesForUs is a full-stack **Ruby on Rails 8** application designed to strengthen family connections through an interactive digital platform.

Users can securely register using **Google OAuth** or email authentication, create multiple family trees, add family members, define parent-child and partner relationships, and visualize complex family hierarchies spanning multiple generations.

Beyond genealogy, TreesForUs provides a private social experience where users can:

- Share life activities and milestones with family
- Build a personal Friends Tree
- Chat with family members and friends in real time
- Preserve family history in one secure platform

The project demonstrates modern Rails development using **Hotwire, Turbo, Stimulus, Action Cable, Tailwind CSS, PostgreSQL, Redis, and Devise**.

---

# Features

## 🌳 Family Tree

- Multi-generational family trees
- Interactive relationship visualization
- Parent-child relationships
- Partner/Spouse relationships
- Multiple family support
- Tree-only members
- Login-enabled members

---

## 👤 User Profiles

- Detailed personal profiles
- Profile pictures
- Birth information
- Nationality
- Occupation
- Contact information
- Biography
- Relationship information

---

## 📅 Life Activities

Users can share important moments with their family including:

- Birthdays
- Weddings
- Graduations
- Career achievements
- Family events
- Photos
- Memories
- Personal milestones

Activities are shared privately with family members and appear in their activity feed.

---

## 👥 Friends Tree

Beyond family relationships, users can:

- Add friends
- Organize personal social connections
- View friend profiles
- Build a separate friendship network

---

## 💬 Real-Time Chat

Built using **Rails Action Cable**.

Features include:

- Real-time messaging
- Private conversations
- Group chats
- Instant message delivery
- Live updates without page refresh
- Online collaboration

---

## 🔐 Authentication & Security

- Devise Authentication
- Google OAuth
- Email invitations
- Secure sessions
- Authorization
- Role-based access

---

## ⚙️ Administration

- ActiveAdmin dashboard
- User management
- Family management
- Activity monitoring

---

## 🎨 Modern UI

- Fully responsive
- Mobile friendly
- Tailwind CSS
- Hotwire Turbo
- StimulusJS
- Fast page navigation

---

# Tech Stack

| Category | Technology |
|------------|------------|
| Language | Ruby 3.3.5 |
| Framework | Ruby on Rails 8 |
| Database | PostgreSQL / SQLite |
| Frontend | Tailwind CSS |
| Templating | Slim |
| JavaScript | Stimulus |
| SPA Experience | Hotwire Turbo |
| Authentication | Devise |
| OAuth | Google OAuth |
| Real-Time | Rails Action Cable |
| Background Communication | Redis |
| Email | Resend |
| Admin Panel | ActiveAdmin |
| Pagination | Kaminari |
| Activity Tracking | PublicActivity |
| Deployment | Railway / Docker |

---

# Architecture Highlights

- MVC Architecture
- RESTful Design
- Self-referential family relationships
- Real-time WebSocket communication
- Hotwire-first frontend
- Secure authentication
- Role-based authorization
- Optimized relational database design

---

# Prerequisites

Install the following before running the project.

- Ruby 3.3.5
- Rails 8
- PostgreSQL
- Redis
- Node.js
- Yarn
- Bundler

---

# Installation

Clone the repository.

```bash
git clone https://github.com/MariaHabib2207/TreeOfUs.git

cd TreeOfUs
```

Install dependencies.

```bash
bundle install
```

```bash
yarn install
```

Create environment variables.

```bash
cp .env.example .env
```

---

# Environment Variables

```env
GOOGLE_CLIENT_ID=

GOOGLE_CLIENT_SECRET=

RESEND_API_KEY=

RAILS_MASTER_KEY=

DATABASE_URL=

REDIS_URL=
```

---

# Database Setup

Create and migrate the database.

```bash
rails db:create

rails db:migrate

rails db:seed
```

---

# Running the Application

Start the development server.

```bash
bin/dev
```

Application will be available at:

```
http://localhost:3000
```

---

## Docker

```bash
docker build -t treesforus .

docker run -p 3000:3000 treesforus
```

---

# Testing

Run all tests.

```bash
rails test
```

Run system tests.

```bash
rails test:system
```

---

# Core Models

## User

Authentication, authorization, friendships, family memberships, invitations, and messaging.

---

## UserProfile

Stores user information including biography, occupation, nationality, profile image, and birth information.

---

## Family

Represents a family unit.

---

## FamilyMembership

Connects users with families and manages permissions.

---

## ParentRelationship

Defines parent-child relationships.

---

## PartnerRelationship

Represents spouse and partner connections.

---

## Friend

Maintains friendship relationships between users.

---

## ChatRoom

Represents one-to-one and group conversations.

---

## Message

Stores chat messages delivered through Action Cable.

---

## LifeActivity

Stores milestones, achievements, memories, and family updates shared by users.

---

# Future Roadmap

- 📹 Audio Calling
- 🎥 Video Calling
- 📱 Progressive Web App (PWA)
- 🔔 Push Notifications
- 📍 Family Event Calendar
- 🗂️ Shared Family Documents
- 📷 Shared Photo Albums
- 🤖 AI-powered Family Story Generator

---

# Contributing

Contributions are welcome.

1. Fork the repository

2. Create a feature branch

```bash
git checkout -b feature/new-feature
```

3. Commit changes

```bash
git commit -m "Add new feature"
```

4. Push changes

```bash
git push origin feature/new-feature
```

5. Open a Pull Request

---

# License

This project is private.

All Rights Reserved.

---

## ⭐ Highlights

- ✅ Ruby on Rails 8
- ✅ Hotwire
- ✅ Tailwind CSS
- ✅ Devise Authentication
- ✅ Google OAuth
- ✅ Rails Action Cable
- ✅ Redis
- ✅ PostgreSQL
- ✅ Real-Time Chat
- ✅ Interactive Family Tree
- ✅ Friends Network
- ✅ Life Activity Sharing
- ✅ Responsive Design
- ✅ Docker Ready
- ✅ Production Deployment