-- Appiombi - Step 1 database core for real data collection flow
-- Supports:
-- - working sessions with explicit type and reopen state
-- - core cow visit records with integer cow_number
-- - soft delete and sync-ready visit lifecycle
-- - anti-duplicate protection inside the same session
-- - compatibility with the existing farm-scoped RLS model

begin;

-- ============================================================================
-- ENUMS
-- ============================================================================

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typnamespace = 'public'::regnamespace
      and typname = 'trimming_session_type'
  ) then
    create type public.trimming_session_type as enum (
      'herd_trim',
      'selected_trim',
      'emergency',
      'recheck'
    );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typnamespace = 'public'::regnamespace
      and typname = 'cow_visit_status'
  ) then
    create type public.cow_visit_status as enum (
      'draft',
      'saved',
      'deleted'
    );
  end if;
end $$;

alter type public.session_status add value if not exists 'reopened';

-- ============================================================================
-- TRIMMING SESSIONS
-- ============================================================================

alter table public.trimming_sessions
  add column if not exists session_type public.trimming_session_type,
  add column if not exists reopened_at timestamptz;

update public.trimming_sessions
set session_type = 'herd_trim'
where session_type is null;

alter table public.trimming_sessions
  alter column session_type set default 'herd_trim';

alter table public.trimming_sessions
  alter column session_type set not null;

comment on column public.trimming_sessions.session_type is
'Step 1 data collection core: logical session type for reporting and future differentiated workflows.';

comment on column public.trimming_sessions.reopened_at is
'Timestamp of the most recent reopen action for the session.';

create or replace function public.normalize_trimming_session_core()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'closed' and new.closed_at is null then
    new.closed_at = timezone('utc', now());
  end if;

  if new.status = 'reopened' and new.reopened_at is null then
    new.reopened_at = timezone('utc', now());
  end if;

  return new;
end;
$$;

drop trigger if exists trg_trimming_sessions_core_normalize on public.trimming_sessions;

create trigger trg_trimming_sessions_core_normalize
before insert or update on public.trimming_sessions
for each row execute function public.normalize_trimming_session_core();

-- Only one modifiable session (`open` or `reopened`) can exist for the same farm.
create unique index if not exists uq_trimming_sessions_one_modifiable_per_farm
on public.trimming_sessions (farm_id)
where deleted_at is null
  and status in ('open', 'reopened');

create index if not exists idx_trimming_sessions_farm_type_status_started
on public.trimming_sessions (farm_id, session_type, status, started_at desc);

-- ============================================================================
-- COW VISITS - STEP 1 CORE FIELDS
-- ============================================================================

alter table public.cow_visits
  alter column cow_id drop not null;

alter table public.cow_visits
  add column if not exists cow_number integer,
  add column if not exists laminitis_code public.laminitis_status,
  add column if not exists corkscrew_code integer,
  add column if not exists soles_count integer not null default 0,
  add column if not exists bandages_count integer not null default 0,
  add column if not exists antibiotic_code text,
  add column if not exists anti_inflammatory_code text,
  add column if not exists recheck_code text,
  add column if not exists status public.cow_visit_status not null default 'draft',
  add column if not exists needs_conflict_resolution boolean not null default false,
  add column if not exists original_cow_number integer,
  add column if not exists conflict_reason text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'cow_visits_corkscrew_code_check'
      and conrelid = 'public.cow_visits'::regclass
  ) then
    alter table public.cow_visits
      add constraint cow_visits_corkscrew_code_check
      check (corkscrew_code is null or corkscrew_code between 1 and 3);
  end if;
end $$;

update public.cow_visits cv
set cow_number = cast(c.cow_identifier as integer)
from public.cows c
where cv.cow_id = c.id
  and cv.cow_number is null
  and c.cow_identifier ~ '^-?[0-9]+$';

update public.cow_visits
set laminitis_code = laminitis_status
where laminitis_code is null
  and laminitis_status is not null;

update public.cow_visits
set corkscrew_code = corkscrew_grade
where corkscrew_code is null
  and corkscrew_grade is not null;

update public.cow_visits
set soles_count = sole_count
where soles_count = 0
  and sole_count <> 0;

update public.cow_visits
set bandages_count = bandage_count
where bandages_count = 0
  and bandage_count <> 0;

update public.cow_visits
set antibiotic_code = case when antibiotic_given then 'yes' else antibiotic_code end
where antibiotic_code is null
  and antibiotic_given = true;

update public.cow_visits
set anti_inflammatory_code = case when antiinflammatory_given then 'yes' else anti_inflammatory_code end
where anti_inflammatory_code is null
  and antiinflammatory_given = true;

update public.cow_visits
set status = case
  when deleted_at is not null then 'deleted'
  else 'saved'
end
where status = 'draft';

comment on column public.cow_visits.cow_number is
'Step 1 data collection core: integer cow number entered in the session popup. Can be negative when business rules require it.';

comment on column public.cow_visits.status is
'Visit lifecycle for Appiombi data collection core. Physical delete is not the default path.';

comment on column public.cow_visits.original_cow_number is
'Original cow number preserved when a conflict requires temporary disambiguation, for example a 999-prefixed duplicate.';

comment on column public.cow_visits.conflict_reason is
'Human-readable reason describing why the visit requires manual conflict resolution.';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'cow_visits_cow_number_required'
      and conrelid = 'public.cow_visits'::regclass
  ) then
    alter table public.cow_visits
      add constraint cow_visits_cow_number_required
      check (status = 'deleted' or cow_number is not null)
      not valid;
  end if;
end $$;

create or replace function public.normalize_cow_visit_core()
returns trigger
language plpgsql
as $$
declare
  v_session_farm_id uuid;
  v_cow_farm_id uuid;
  v_identifier text;
begin
  if new.soles_count is null then
    new.soles_count = coalesce(new.sole_count, 0);
  end if;
  new.sole_count = coalesce(new.soles_count, 0);

  if new.bandages_count is null then
    new.bandages_count = coalesce(new.bandage_count, 0);
  end if;
  new.bandage_count = coalesce(new.bandages_count, 0);

  if new.laminitis_code is null then
    new.laminitis_code = new.laminitis_status;
  end if;
  new.laminitis_status = new.laminitis_code;

  if new.corkscrew_code is null then
    new.corkscrew_code = new.corkscrew_grade;
  end if;
  new.corkscrew_grade = new.corkscrew_code;

  if new.antibiotic_code is null and coalesce(new.antibiotic_given, false) then
    new.antibiotic_code = 'yes';
  end if;
  if new.antibiotic_code is not null then
    new.antibiotic_given = lower(new.antibiotic_code) not in ('', 'no', 'none', 'false');
  end if;

  if new.anti_inflammatory_code is null and coalesce(new.antiinflammatory_given, false) then
    new.anti_inflammatory_code = 'yes';
  end if;
  if new.anti_inflammatory_code is not null then
    new.antiinflammatory_given = lower(new.anti_inflammatory_code) not in ('', 'no', 'none', 'false');
  end if;

  if new.status = 'deleted' and new.deleted_at is null then
    new.deleted_at = timezone('utc', now());
  end if;

  if new.deleted_at is not null and new.status <> 'deleted' then
    new.status = 'deleted';
  end if;

  select s.farm_id
  into v_session_farm_id
  from public.trimming_sessions s
  where s.id = new.session_id;

  if v_session_farm_id is null then
    raise exception 'Session % not found for cow visit', new.session_id;
  end if;

  if new.farm_id <> v_session_farm_id then
    raise exception 'Cow visit farm_id must match trimming session farm_id';
  end if;

  if new.cow_id is not null then
    select c.farm_id, c.cow_identifier
    into v_cow_farm_id, v_identifier
    from public.cows c
    where c.id = new.cow_id;

    if v_cow_farm_id is null then
      raise exception 'Cow % not found for cow visit', new.cow_id;
    end if;

    if v_cow_farm_id <> new.farm_id then
      raise exception 'Cow visit cow_id must belong to the same farm';
    end if;

    if new.cow_number is null and v_identifier ~ '^-?[0-9]+$' then
      new.cow_number = cast(v_identifier as integer);
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_cow_visits_core_normalize on public.cow_visits;

create trigger trg_cow_visits_core_normalize
before insert or update on public.cow_visits
for each row execute function public.normalize_cow_visit_core();

-- Prevent duplicate active cow numbers inside the same session.
create unique index if not exists uq_cow_visits_session_cow_number_active
on public.cow_visits (session_id, cow_number)
where deleted_at is null
  and status <> 'deleted'
  and cow_number is not null;

create index if not exists idx_cow_visits_farm_cow_number_visit_date
on public.cow_visits (farm_id, cow_number, visit_date desc)
where deleted_at is null;

create or replace view public.active_cow_visits
with (security_invoker = true) as
select *
from public.cow_visits
where deleted_at is null
  and status <> 'deleted';

grant select on public.active_cow_visits to authenticated;

-- ============================================================================
-- VALIDATE EXISTING RLS COVERAGE
-- ============================================================================

comment on table public.trimming_sessions is
'Step 1 database core supports real data collection sessions. Existing farm-scoped RLS policies remain valid.';

comment on table public.cow_visits is
'Step 1 database core supports real cow visit collection with integer cow_number, soft delete and conflict markers. Existing farm-scoped RLS policies remain valid.';

commit;
