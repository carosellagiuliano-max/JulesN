# Security & Row Level Security (RLS)

SCHNITTWERK uses a "deny by default" security model. Access is granted explicitly via Postgres Row Level Security (RLS) policies.

## Authentication

Authentication is handled by Supabase Auth.
- **Providers**: Email/Password (Phase 1).
- **Session**: JWT tokens containing `sub` (User ID).

## Authorization (RBAC)

Roles are defined in the `user_roles` table.
- **Scope**: Roles are scoped to a `salon_id`. A user can have different roles in different salons.
- **Roles**:
  - `admin`: Full access to salon data.
  - `manager`: Can manage staff, services, and operational data.
  - `mitarbeiter`: Can view schedule, customers, and manage appointments.
  - `kunde`: Can view own profile and appointments.
  - `hq`: Cross-salon access (future).

## RLS Policies

### General Principles
1. **Isolation**: Data is always filtered by `salon_id`.
2. **Least Privilege**: Public access is read-only for essential data (services, prices).
3. **Ownership**: Customers can only access their own data (`auth.uid() = profile_id`).

### Specific Policies

#### Salons
- **Public**: Read-only (Name, Address).
- **Admin**: Update.

#### Profiles
- **Self**: Read/Update own profile.
- **Staff**: Read all profiles (to identify customers).

#### Appointments
- **Staff**: View/Edit all appointments in their salon.
- **Customer**: View/Create/Cancel their own appointments.

#### Services & Configuration
- **Public**: Read-only.
- **Admin/Manager**: Full control.

## Triggers

- **Profile Creation**: A trigger on `auth.users` automatically creates a corresponding row in `profiles` upon registration.
