-- A Train Detailing: run this in Supabase → SQL Editor → New query → Run
-- Heads up: this replaces the old bookings table (and any test rows in it).

drop table if exists bookings cascade;

create table bookings (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  customer_name text not null,
  phone text not null,
  vehicle text not null,
  vehicle_size text not null,
  service text not null,
  addons text[] not null default '{}',
  appointment_date date not null,
  start_time time not null,
  end_time time not null,
  estimate text,
  status text not null default 'requested'
    check (status in ('requested', 'confirmed', 'done', 'cancelled')),
  check (end_time > start_time),

  -- Two active bookings can never overlap on the same day, even if two
  -- customers hit "Request" at the same second. Cancel one and its time opens back up.
  constraint no_double_booking exclude using gist (
    tsrange(appointment_date + start_time, appointment_date + end_time) with &&
  ) where (status <> 'cancelled')
);

-- Keep RLS ON. The public site can only ADD requests, for today or later.
-- Nobody with the public key can read names or phone numbers.
alter table bookings enable row level security;

create policy "public can request appointments"
  on bookings for insert
  to anon
  with check (status = 'requested' and appointment_date >= current_date);

-- The site needs to know which times are taken, but not who took them.
-- This returns start/end times only.
create or replace function public.booked_times(day date)
returns table (start_time time, end_time time)
language sql
stable
security definer
set search_path = public
as $$
  select b.start_time, b.end_time
  from public.bookings b
  where b.appointment_date = day
    and b.status <> 'cancelled';
$$;

grant execute on function public.booked_times(date) to anon;

-- To see requests: Table Editor → bookings.
-- Confirm one by changing status to 'confirmed'. Free up a time by setting it to 'cancelled'.