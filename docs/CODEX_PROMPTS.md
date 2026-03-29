# R.A.I.K.O Codex Prompts

## Create Project Structure
Create monorepo:

apps/
 mobile (Flutter)
 desktop (Flutter Windows)
 backend (Node)
 agent-windows

packages/
 raiko_ui
 shared_types
 shared_theme

---

## Build Shared UI

Create Flutter package raiko_ui

Components:
RaikoCard
RaikoButton
RaikoHeader
RaikoDeviceTile
RaikoVoiceOrb

Theme:
background #0B1020
card #121A2F
accent #8FB8FF

---

## Backend

Node TypeScript Fastify

Modules:
auth
devices
commands
activity

WebSocket support

---

## Agent

Node agent

Commands:
shutdown
restart
sleep
lock

---

## Mobile

Flutter screens:
Home
Devices
Activity
Settings

Floating voice button

---

## Desktop

Flutter Windows

Sidebar layout
Dashboard
Devices
Activity
Settings
