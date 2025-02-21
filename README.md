# hackfusion_android

A Flutter project for an **Automated Paperless Transparent College System**.

## Overview

The **Automated Paperless Transparent College System** aims to digitize and automate various administrative processes within colleges to enhance transparency, efficiency, and accountability. This project addresses common issues such as:

- **Lack of Transparency**: In elections, budget tracking, and complaint handling.
- **Manual Processes**: Delays in approvals, notifications, and facility bookings.
- **Fragmented Systems**: No centralized digital system for managing student-related administrative tasks.

## Key Features

- **Online Elections**
  - Candidate registration and profiles
  - Secure voting mechanism
  - Live result tracking

- **Automated Health & Leave Notifications**
  - Student health reporting
  - Automated leave notifications sent to parents and coordinators

- **Campus Facility Booking**
  - Online booking requests with an availability calendar
  - Multi-step approval workflow

- **Application & Approval System**
  - Request submission portal
  - Approval tracking system with priority-based escalation

- **Cheating Record System**
  - Incident logging (including name, proof, and reason)
  - Public visibility of academic integrity violations

- **Anonymous Complaint System**
  - Secure complaint submission with moderation and approval
  - Option to reveal identity based on community voting

- **Budget & Sponsorship Transparency**
  - Expense submission and budget tracking
  - Public tracking of college funds usage

- **Authentication & Role-Based Access**
  - College email verification
  - Role management (Admin, Faculty, Student)

## Modules

The project is organized into the following key modules:

1. **Student Election System**
2. **Health & Leave Notification System**
3. **Facility Booking System**
4. **Application & Approval System**
5. **Cheating Record System**
6. **Anonymous Complaint System**
7. **Budget & Sponsorship Transparency**
8. **Authentication & Role-Based Access**

## Tech Stack

- **Flutter**: For building the mobile application.
- **Firebase**:  
  - **Firestore**: For storing and retrieving data in real time.
  - **Authentication**: For secure user sign-in using college email IDs.
  - **Storage**: For handling file uploads (e.g., images for complaints).
- **Web Integration**: (Optional) to provide a companion web app.
