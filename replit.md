# Student Attendance System

## Overview

This is a Flask-based student attendance system designed for Class 10 students. The application allows students to mark their attendance for different subjects within specific time windows. It features a simple login system using roll numbers and passwords, real-time attendance tracking, and an admin view for monitoring attendance reports. The system enforces class schedules and prevents duplicate attendance marking for the same subject on the same day.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
- **Framework**: Bootstrap 5 with dark theme for responsive UI design
- **File Structure**: Organized in `/frontend/` directory with:
  - `frontend/templates/` - Jinja2 HTML templates
  - `frontend/static/` - CSS, JavaScript, and static assets
- **JavaScript**: Vanilla JavaScript for client-side interactions including auto-dismissing alerts, form loading states, and real-time clock display
- **Template Engine**: Jinja2 templates with a base template system for consistent layout
- **Styling**: Font Awesome icons for enhanced visual presentation

### Backend Architecture
- **Framework**: Flask web framework with session-based authentication
- **File Structure**: Organized in `/backend/` directory with:
  - `backend/app.py` - Main application logic and Flask routes
  - `backend/main.py` - Backend-specific entry point
- **Entry Point**: Root `main.py` handles imports and runs the Flask app from backend directory
- **Authentication**: Simple session-based login using roll numbers (1-40) and predefined passwords
- **Business Logic**: Time-based class scheduling system that validates attendance marking windows

### Data Storage Solutions
- **Storage Type**: JSON file-based storage system
- **Storage Location**: Organized in `/database/` directory
- **Data Files**: 
  - `database/data/students.json` - Stores student information (40 students with roll numbers, names, passwords)
  - `database/data/attendance.json` - Stores daily attendance records by date and subject
- **Data Management**: File-based CRUD operations with automatic file creation and data initialization

### Class Schedule System
- **Schedule Definition**: Hardcoded class schedule with specific time windows for 5 subjects (Mathematics, Science, English, Social Studies, Hindi)
- **Time Validation**: Server-side validation to ensure attendance can only be marked during class hours
- **Duplicate Prevention**: System prevents marking attendance multiple times for the same subject on the same day

### Core Features
- **Student Dashboard**: Shows today's attendance status across all subjects
- **Class Selection**: Displays available classes with visual indicators for availability and completion status
- **Attendance Confirmation**: Two-step process for marking attendance with confirmation page
- **Admin Reports**: Statistical overview with total students, days with records, and subject information

## External Dependencies

### Frontend Libraries
- **Bootstrap 5**: CSS framework for responsive design and UI components
- **Font Awesome 6**: Icon library for enhanced visual presentation
- **Bootstrap Agent Dark Theme**: Custom dark theme styling from cdn.replit.com

### Backend Dependencies
- **Flask**: Core web framework for routing, templating, and session management
- **Python Standard Library**: 
  - `json` for data serialization/deserialization
  - `datetime` for time-based validations and scheduling
  - `logging` for application debugging and monitoring
  - `os` for environment variable management and file system operations

### Runtime Environment
- **Python Runtime**: Flask development server configured for host='0.0.0.0', port=5000
- **Session Management**: Flask sessions with configurable secret key from environment variables
- **File System**: Local file storage in `data/` directory for persistent data storage

### Development Tools
- **Debug Mode**: Enabled for development with detailed error reporting
- **Logging**: DEBUG level logging for application monitoring and troubleshooting