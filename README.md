# SCP Mobile App

This repository contains the **Flutter mobile application** for the Supplier Consumer Platform (SCP), a B2B platform designed to streamline interactions between food suppliers and institutional consumers such as restaurants, cafes, and hotels.

The mobile application allows users to browse supplier catalogs, place orders, communicate with suppliers, and manage complaints through an intuitive interface.

This project was developed as part of a **Software Engineering team project at Nazarbayev University**.

## Features

The mobile app includes the following functionality:

- User authentication and login
- Browsing supplier catalogs
- Sending supplier link requests
- Viewing linked suppliers
- Placing and tracking orders
- Real-time chat with suppliers
- Complaint submission and management
- User profile and account management

## Technologies

- Flutter
- Dart
- REST API integration
- Figma (UI/UX design)

## System Architecture

The full Supplier Consumer Platform consists of three main components:

- **Mobile application** – built with Flutter  
- **Web dashboard** – built with React  
- **Backend API** – built with FastAPI and PostgreSQL  

This repository contains **only the mobile client** developed as part of the system.

## Project Structure

Typical Flutter project structure:

```
lib/
assets/
android/
ios/
web/
windows/
linux/
macos/
pubspec.yaml
```

Most of the application logic is located inside the **lib/** directory.

## Team

Software Engineering Project – Team 9

- **Amina Sadybek** – Mobile development, UI design (Figma), ERD and activity diagrams, documentation
- Kamila Nurzhanova – Backend development
- Madina Maldarbekova – Frontend (React) development
- Assylkhan Kerey – Mobile development and documentation support

## Future Improvements

Potential future improvements include:

- Payment system integration
- Delivery and logistics tracking
- Ratings and review system
- Admin dashboard
- Performance optimization
