# 🌳 TreesForUs

> **Build, preserve, and share your family story.**

**TreesForUs** is a modern social networking platform built with **Ruby on Rails 8** that helps families and friends stay connected through interactive family trees, real-time messaging, shared timelines, and collaborative social experiences.

Unlike traditional genealogy applications, TreesForUs combines **family relationship management**, **private social networking**, **real-time communication**, and **interactive activities** into one secure platform.

---

## 🚀 Live Demo

**Application:** https://tree-of-us.com
---

## 📖 Documentation

Detailed project documentation:

https://docs.google.com/document/d/1FRlTcXSPeLLuZU8SQGo2VLqj871elEDubcBH2bjOLlk/edit?tab=t.0

---

# 📸 Screenshots

### Home

<img width="1678" height="889" alt="Home" src="https://github.com/user-attachments/assets/78c503f8-1e5e-4d17-819a-9c7a9e7a36e5" />

### Family Tree

<img width="1449" height="740" alt="Family Tree" src="https://github.com/user-attachments/assets/79afba43-18ef-4103-be9b-fee5f8c9b30e" />

---

# 📚 Table of Contents

* Overview
* Features
* Technology Stack
* Architecture
* Installation
* Environment Variables
* Database Setup
* Running the Application
* Docker
* Testing
* Core Models
* Future Roadmap
* Contributing
* License

---

# 🌟 Overview

TreesForUs is a full-stack **Ruby on Rails 8** application that enables users to build digital family trees while communicating and sharing memories with their loved ones.

The platform supports multiple families, friendship networks, private timelines, real-time messaging, voice and video communication, and multiplayer game rooms—all within a secure, responsive web application.

Built using modern Rails technologies including **Hotwire**, **Turbo**, **Stimulus**, **Action Cable**, **Redis**, **PostgreSQL**, and **Tailwind CSS**, TreesForUs demonstrates a production-ready architecture focused on scalability, maintainability, and an excellent user experience.

---

# ✨ Features

## 🔐 Authentication

Secure authentication powered by **Devise**.

* User Registration
* Email Login
* Google OAuth Sign-In
* Forgot Password
* Password Reset
* Remember Me
* Secure Sessions

---

## 🏡 Dashboard

A centralized dashboard for managing your family network.

* Create multiple families
* Switch between families
* Add spouses
* Add children
* Add friends
* Invite members to chat rooms
* View profile avatars
* Manage family relationships
* Search user profiles
* View activity feed
* Login activity tracking

---

## 🌳 Interactive Family Tree

Create and visualize complex family relationships.

* Multi-generation family trees
* Parent-child relationships
* Spouse relationships
* Dynamic family hierarchy
* Multiple family support
* Registered family members
* Tree-only members
* Interactive relationship visualization

---

## 👤 User Profiles

Rich personal profiles for every member.

* Profile photo
* Biography
* Birth information
* Nationality
* Occupation
* Contact information
* Relationship information
* Searchable profiles

---

## 📅 Timeline & Activities

Share important moments with family and friends.

* Create activities
* Edit activities
* Delete activities
* Share with family
* Share with friends
* Privacy controls
* Activity timeline
* Personal milestones
* Family memories
* Photo sharing

---

## 👥 Friends Network

Build relationships beyond family.

* Add friends
* Search users
* View profiles
* Manage friendships
* Private social network

---

## 💬 Real-Time Messaging

Powered by **Rails Action Cable**.

Features include:

* One-to-one chat
* Group chat
* Instant messaging
* Audio messages
* Video messages
* File attachments
* Image attachments
* Read receipts
* Last seen
* Delete message for everyone
* Delete message for me
* Live updates
* Real-time communication

---

## 📞 Audio & Video Calling

Built-in communication features.

* Audio calls
* Video calls
* Call history
* Screen sharing
* Camera switching
* Emoji reactions
* Delete call logs

---

## 🎮 Game Rooms

Play games with family and friends.

* Multiplayer game rooms
* User search
* Send game invitations
* Tic Tac Toe

---

## 🔔 Activity Feed

Track everything happening in your network.

* New activities
* Updated activities
* Deleted activities
* User login tracking
* Family activity feed

---

## 🛡️ Administration

Administrative features powered by **ActiveAdmin**.

* User management
* Family management
* Activity monitoring
* Role-based authorization
* Secure administration

---

## 🎨 Modern User Experience

Designed using modern Rails technologies.

* Responsive layout
* Mobile-friendly
* Tailwind CSS
* Hotwire Turbo
* StimulusJS
* Fast navigation
* WebSocket updates
* Optimized performance

---

# 🛠 Technology Stack

| Category                 | Technology          |
| ------------------------ | ------------------- |
| Language                 | Ruby 3.3.5          |
| Framework                | Ruby on Rails 8     |
| Database                 | PostgreSQL / SQLite |
| CSS Framework            | Tailwind CSS        |
| Template Engine          | Slim                |
| JavaScript               | StimulusJS          |
| SPA Experience           | Hotwire Turbo       |
| Authentication           | Devise              |
| OAuth                    | Google OAuth        |
| Real-Time Communication  | Rails Action Cable  |
| Background Communication | Redis               |
| Email Service            | Resend              |
| Admin Panel              | ActiveAdmin         |
| Pagination               | Kaminari            |
| Activity Tracking        | PublicActivity      |
| Deployment               | Railway             |
| Containerization         | Docker              |

---

# 🏗 Architecture

TreesForUs follows modern Ruby on Rails best practices.

* MVC Architecture
* RESTful Routing
* Hotwire-first Frontend
* WebSocket Communication
* Self-referential Associations
* Service-oriented Components
* Secure Authentication
* Authorization
* Responsive UI
* Optimized Database Design

---

# 📦 Prerequisites

Install the following before running the project.

* Ruby 3.3.5
* Rails 8
* PostgreSQL
* Redis
* Node.js
* Yarn
* Bundler

---

# ⚡ Installation

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

Create the environment file.

```bash
cp .env.example .env
```

---

# 🔑 Environment Variables

```env
GOOGLE_CLIENT_ID=

GOOGLE_CLIENT_SECRET=

RESEND_API_KEY=

RAILS_MASTER_KEY=

DATABASE_URL=

REDIS_URL=
```

---

# 🗄 Database Setup

```bash
rails db:create

rails db:migrate

rails db:seed
```

---

# ▶️ Running the Application

Start the Rails development server.

```bash
bin/dev
```

Visit:

```
http://localhost:3000
```

---

# 🐳 Docker

Build the Docker image.

```bash
docker build -t treesforus .
```

Run the container.

```bash
docker run -p 3000:3000 treesforus
```

---

# 🧪 Testing

Run all tests.

```bash
rails test
```

Run system tests.

```bash
rails test:system
```

---

# 🗂 Core Models

### User

Authentication, authorization, messaging, friendships, and family memberships.

### UserProfile

Stores personal information, biography, profile image, and demographic details.

### Family

Represents an individual family.

### FamilyMembership

Associates users with families and manages permissions.

### ParentRelationship

Defines parent-child relationships.

### PartnerRelationship

Represents spouse and partner relationships.

### Friend

Stores friendship connections.

### ChatRoom

Supports private and group conversations.

### Message

Stores real-time chat messages.

### LifeActivity

Stores timeline posts, milestones, and memories.

---

# 🚀 Future Roadmap

* Progressive Web App (PWA)
* Push Notifications
* Shared Photo Albums
* Family Event Calendar
* Shared Family Documents
* Birthday & Anniversary Reminders
* Multi-language Support
* AI Family Story Generator
* Additional Multiplayer Games
* Event Invitations
* Family Polls
* Mobile Applications (iOS & Android)

---

# 🤝 Contributing

Contributions are welcome.

1. Fork the repository

2. Create a feature branch

```bash
git checkout -b feature/new-feature
```

3. Commit your changes

```bash
git commit -m "Add new feature"
```

4. Push to your branch

```bash
git push origin feature/new-feature
```

5. Open a Pull Request

---

# 📄 License

This project is currently private.

**All Rights Reserved.**

---

# ⭐ Project Highlights

* ✅ Ruby on Rails 8
* ✅ Hotwire
* ✅ Turbo
* ✅ StimulusJS
* ✅ Tailwind CSS
* ✅ PostgreSQL
* ✅ Redis
* ✅ Devise Authentication
* ✅ Google OAuth
* ✅ Rails Action Cable
* ✅ Interactive Family Tree
* ✅ Friends Network
* ✅ Timeline & Activity Feed
* ✅ Privacy Controls
* ✅ Real-Time Messaging
* ✅ Audio & Video Messages
* ✅ Group Chats
* ✅ Read Receipts
* ✅ Last Seen
* ✅ Audio & Video Calling
* ✅ Screen Sharing
* ✅ Multiplayer Game Rooms
* ✅ ActiveAdmin
* ✅ Docker Ready
* ✅ Railway Deployment
* ✅ Responsive Design
