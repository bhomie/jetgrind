# CLAUDE.md

## Project Overview

**JetGrind** is an ADHD-friendly Pomodoro timer and task management desktop application featuring a kawaii 90s anime-style desktop pet.

## Tech Stack

- **Framework:** Electron + React + TypeScript
- **Build Tool:** Vite
- **State Management:** Zustand
- **Database:** SQLite + Prisma
- **Styling:** Tailwind CSS + Radix UI
- **Testing:** Vitest + React Testing Library

## Project Structure

```
jetgrind/
├── src/
│   ├── main/             # Electron main process
│   │   ├── services/     # Database, settings, shop services
│   │   ├── index.ts      # Main entry point
│   │   └── preload.ts    # Context bridge
│   ├── renderer/         # React frontend
│   │   ├── components/   # UI components
│   │   ├── stores/       # Zustand stores
│   │   ├── styles/       # Global CSS
│   │   └── utils/        # Utilities
│   ├── shared/           # Shared types and utilities
│   └── test/             # Test setup and tests
├── prisma/               # Database schema
└── assets/               # Icons, characters, cosmetics, sounds
```

## Commands

- `npm run dev` - Start Vite dev server
- `npm run dev:electron` - Start full Electron dev mode
- `npm run build` - Build for production
- `npm test` - Run tests
- `npm run test:coverage` - Run tests with coverage
- `npm run prisma:generate` - Generate Prisma client
- `npm run prisma:migrate` - Run database migrations

## Key Features

1. **Task Management** - Create, complete, delete tasks with XP rewards
2. **Pomodoro Timer** - Customizable work/break intervals
3. **Gamification** - XP, levels (1-100), coins, streaks
4. **Pet System** - Mood-reactive kawaii character
5. **Shop** - Cosmetic items for pet customization
6. **AI Task Chunking** - Break large tasks into ADHD-friendly chunks (future)

## XP Formula

```
XP_required = 50 * level^2

Rewards:
- Small task: 10 XP, 5 coins
- Medium task: 25 XP, 15 coins
- Large task: 50 XP, 30 coins
- Pomodoro: 25 XP, 10 coins
- Daily streak: 50 XP, 25 coins
```

## Mood Calculation

Pet mood is based on: tasks completed (+8), pomodoros (+5), streak (+3, max +15), overdue tasks (-10), inactivity after 2hr (-1/30min), active timer (+10).

Mood states: ecstatic (85+), happy (70+), content (55+), neutral (40+), sad (25+), worried (<25)
