# R.A.I.K.O — Software Requirements Specification

Version: 1.0  
Author: Adam Khabisa  
Project: R.A.I.K.O  

---

# 1. Introduction
R.A.I.K.O (Remote Artificial Intelligence Kernel Operator) is a cross-platform system that allows users to remotely control Windows devices from mobile.

System consists of:
- Mobile App
- Desktop App
- Windows Agent
- Backend Server

---

# 2. Architecture

Mobile App ? Backend ? Windows Agent ? PC

---

# 3. Functional Requirements

## Device Management
- register device
- remove device
- rename device
- online status

## Commands
- shutdown
- restart
- sleep
- lock
- open app

## Voice Commands
Examples:
- Raiko start my PC
- Raiko shutdown laptop

---

# 4. UI Design System

## Colors
Background: #0B1020  
Card: #121A2F  
Accent: #8FB8FF  

## Typography
Headings: Space Grotesk  
Body: Inter  

---

# 5. Screens

Mobile:
- Home
- Devices
- Activity
- Settings

Desktop:
- Dashboard
- Devices
- Activity
- Settings

---

# 6. Backend Modules
auth  
devices  
commands  
activity  

---

# 7. Agent Responsibilities
- connect websocket
- execute commands
- send status

---

# MVP
- device list
- quick commands
- voice button
- logs

---

# Future
- streaming
- keyboard control
- automation
