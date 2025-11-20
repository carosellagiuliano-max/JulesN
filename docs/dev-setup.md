# Developer Setup

## Prerequisites

- Node.js 18+
- npm
- Docker (for local Supabase) - Optional if using cloud directly, but recommended for migrations.

## Installation

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd <repo-name>
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Variables**
   Copy `.env.example` to `.env.local` and fill in the values.
   ```bash
   cp .env.example .env.local
   ```
   Required variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY` (only for scripts/seed, do not expose to client)
   - `STRIPE_SECRET_KEY`
   - `STRIPE_WEBHOOK_SECRET`

4. **Database Setup**
   - Ensure you have Supabase CLI installed: `npm install -g supabase`
   - Start local Supabase (if using local): `supabase start`
   - Apply migrations: `supabase db push` (or `supabase migration up`)

5. **Run Development Server**
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000).

## Development Workflow

- **New Features**: Create a feature branch.
- **Database Changes**:
  - Create a migration: `supabase migration new <name>`
  - Edit the SQL file in `supabase/migrations`.
  - Apply locally to test.
- **Commits**: Use conventional commits (e.g., `feat: add booking flow`, `fix: correct time calculation`).

## Testing

- Run linting: `npm run lint`
- (Future) Run tests: `npm test`
