---
paths:
  - "app/**"
---

# Frontend Rules

## Project layout (Nuxt SPA)
- Source root is `app/` (configured in `nuxt.config.ts`) — not the project root
- SSR is disabled (`ssr: false`); this is a pure client-side SPA
- Root `/` auto-redirects to `/events` via Nuxt route rules
- Components are auto-imported from `app/components/`

## State management
- All API calls go through Pinia stores in `app/stores/` — never call the API directly from components
- Stores use axios; after mutations, they re-fetch the list to keep state fresh
- `settingsStore` is the source of truth for universe dates and current day

## Component organization
- `app/components/ui/` — generic, reusable primitives (Button, Input, Dialog, Table, Badge …)
- `app/components/features/` — domain components grouped by entity (characters/, events/, groups/, settings/)
- `app/components/layout/` — AppLayout, NavBar, PageLayout, ConfirmDialog

## Composables
- `useToast` — toast notifications (5 s auto-dismiss); import from `app/composables/useToast.ts`
- `useConfirm` — modal confirmation dialog
- `useSearch` — generic search/filter utility; accepts custom filter functions

## Dates on the frontend
- Use `@internationalized/date` for date arithmetic and formatting
- Age calculation logic lives in `app/lib/ageCalculator.ts` — reuse it, don't duplicate
- The "current day" for age calculations comes from `settingsStore.settings.currentDay`

## Timeline view
- Events page has list and timeline views; timeline uses vis-timeline / vis-data
- Timeline component is `app/components/features/events/EventTimelineView.vue`
