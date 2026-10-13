-- A Train Detailing: bookings table
-- Paste into Supabase > SQL Editor > Run

create table if not exists bookings (
  id            bigint generated always as identity primary key,
  ref           text not null,
  package       text not null,
  vehicle_size  text not null,
  addons        text[] default '{}',
  estimate      numeric not null,
  booking_date  date not null,
  time_slot     text not null,
  address       text not null,
  name          text not null,
  phone         text not null,
  email         text,
  vehicle       text,
  notes         text,
  status        text default 'new',
  created_at    timestamptz default now()
);

-- Keep RLS ON so the public key can't read customer info
alter table bookings enable row level security;

-- Public site can only ADD bookings (no read, update, or delete)
drop policy if exists "public can create bookings" on bookings;
create policy "public can create bookings"
  on bookings for insert
  to anon
  with check (true);
