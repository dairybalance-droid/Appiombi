-- Minimal migration to support farm disambiguation by address fields.
-- Farm identity remains based on `farms.id`.

alter table public.farms
add column if not exists street_address text,
add column if not exists street_number text,
add column if not exists postal_code text,
add column if not exists city text,
add column if not exists province text,
add column if not exists region text,
add column if not exists country text default 'Italia';
