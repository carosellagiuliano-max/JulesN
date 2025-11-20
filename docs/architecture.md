# Architecture

## High Level Overview

SCHNITTWERK is a modern, full-stack web application designed for a hair salon in Switzerland. It serves three main user groups:
1. **Public Customers**: Booking appointments, browsing services, and purchasing products.
2. **Registered Customers**: Managing their profile, appointments, orders, and loyalty points.
3. **Staff/Admin**: Managing the calendar, customers, inventory, and business settings.

## Tech Stack

- **Frontend**: Next.js 14+ (App Router), React Server Components, Tailwind CSS, shadcn/ui.
- **Database**: Supabase PostgreSQL.
- **Auth**: Supabase Auth (Email/Password).
- **Storage**: Supabase Storage.
- **Payments**: Stripe.
- **Email**: Resend (or similar).
- **Hosting**: Vercel (Frontend), Supabase (Backend).

## Architecture Principles

- **Monorepo-like structure**: Single Next.js app, but feature-folder based organization.
- **Server First**: Use React Server Components for data fetching. Use Server Actions for mutations.
- **Type Safety**: End-to-end type safety using TypeScript and database-generated types.
- **Feature Encapsulation**: Code related to a specific domain (e.g., booking) should be co-located in `features/`.
- **Configuration Driven**: Business logic (prices, hours, rules) should be in the database, not hardcoded.

## Directory Structure

- `app/`: Next.js App Router pages and layouts.
- `components/`: Shared UI components (shadcn/ui primitives).
- `features/`: Domain-specific logic and components (booking, shop, etc.).
- `lib/`: Shared utilities, database clients, types.
- `supabase/`: Database migrations and seeds.
- `docs/`: Project documentation.

## Key Systems

### Booking Engine
- Slot computation happens on demand.
- Prevents double bookings via database constraints and optimistic locking (or robust transaction logic).
- Handles multiple services and staff availability.

### Shop & Checkout
- Integrated e-commerce for products.
- Unified cart for guest and logged-in users.
- Stripe integration for payments.

### Role-Based Access Control (RBAC)
- Implemented via Supabase RLS (Row Level Security) at the database level.
- Enforced in Server Actions.
- UI visibility controls.

## Security

- All data access is protected by RLS.
- Inputs are validated using Zod.
- Content Security Policy (CSP) headers.
