# Northwind Energy

Northwind Energy is a fictional residential energy self-service portal.
It is used as a workshop exercise. Do not treat it as a production system.

## Running the application

```
npm run dev
```

Open http://localhost:5173 in a browser.

## Project layout

| Path | What it contains |
|---|---|
| `src/pages/` | One file per page (Home, Contract, Contact) |
| `src/components/ui/` | Reusable UI components: Button, Card, Badge, Field, Container, PageHeader, Skeleton |
| `src/components/layout/` | SiteHeader, SiteFooter |
| `src/data/` | Fixture data: offers (Flex, Zeker, Groen), contract, usage |
| `src/lib/` | api.ts (fake async API), useAsync.ts, format.ts, cn.ts |

## Pages

| Route | Page |
|---|---|
| `/` | Home – brand hero, plan teasers, quick links |
| `/contract` | My contract – plan details, account info, usage |
| `/contact` | Contact – form and contact information |

## How data works

The app uses a fake in-process API (`src/lib/api.ts`). There is no backend server.
Data is defined in `src/data/` and the API functions return it after a short delay.
To add or change data, edit the files in `src/data/`.

## Components

Components in `src/components/ui/` accept a `className` prop for local overrides.
Styling uses Tailwind CSS v4. Brand colours are defined as `brand-*` (e.g. `bg-brand-700`, `text-brand-50`).
