-- Appiombi Supabase schema
-- Foundation schema for authentication-linked profiles, legal acceptance,
-- farm access, subscriptions, trimming sessions, tasks, audit logging,
-- and offline sync support.

create extension if not exists pgcrypto;

-- ============================================================================
-- ENUMS
-- ============================================================================

create type public.user_role as enum (
  'super_admin',
  'farmer',
  'veterinarian',
  'hoof_trimmer',
  'farm_collaborator'
);

create type public.account_status as enum (
  'pending_verification',
  'active',
  'suspended',
  'disabled'
);

create type public.membership_status as enum (
  'active',
  'revoked',
  'expired'
);

create type public.invite_status as enum (
  'pending',
  'accepted',
  'expired',
  'revoked'
);

create type public.session_status as enum (
  'open',
  'closed',
  'archived'
);

create type public.laminitis_status as enum (
  'subacute',
  'chronic_mild',
  'acute_severe',
  'chronic_severe',
  'reactivated_mild',
  'reactivated_severe'
);

create type public.zone_type as enum (
  'horn',
  'derma'
);

create type public.horn_lesion_code as enum (
  'erosion',
  'ulcer',
  'necrosis',
  'abscess_pus',
  'hemorrhage',
  'petechiae',
  'deep_planes',
  'sequelae'
);

create type public.derma_stage_code as enum (
  'stage_1_early',
  'stage_2_acute',
  'stage_3_healing',
  'stage_4_chronic',
  'stage_4_1_reactivated'
);

create type public.task_type as enum (
  'remove_bandage',
  'give_antibiotic',
  'give_antiinflammatory',
  'give_antibiotic_and_antiinflammatory',
  'move_to_straw_box',
  'recheck_cow',
  'evaluate_culling',
  'custom'
);

create type public.task_status as enum (
  'open',
  'done',
  'cancelled'
);

create type public.delivery_state as enum (
  'not_sent',
  'prepared',
  'sent',
  'failed'
);

create type public.delivery_channel as enum (
  'in_app',
  'email',
  'whatsapp'
);

create type public.mutation_operation as enum (
  'insert',
  'update',
  'delete'
);

create type public.sync_status as enum (
  'pending',
  'applied',
  'conflict',
  'rejected'
);

create type public.record_sync_status as enum (
  'local_only',
  'pending_sync',
  'synced',
  'conflict',
  'failed'
);

create type public.conflict_status as enum (
  'open',
  'resolved_keep_server',
  'resolved_keep_local',
  'resolved_manual_merge',
  'dismissed'
);

create type public.legal_document_type as enum (
  'privacy_policy',
  'terms_of_service',
  'cookie_policy'
);

create type public.consent_type as enum (
  'privacy_policy',
  'terms_of_service',
  'marketing',
  'cookie_tracking'
);

create type public.subscription_provider as enum (
  'stripe',
  'revenuecat',
  'manual'
);

create type public.subscription_status as enum (
  'trialing',
  'active',
  'past_due',
  'paused',
  'canceled',
  'expired'
);

-- ============================================================================
-- COMMON TRIGGER
-- ============================================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  new.record_version = old.record_version + 1;
  return new;
end;
$$;

-- ============================================================================
-- PROFILES AND AUTH STATE
-- ============================================================================

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  email text not null unique,
  first_name text not null,
  last_name text not null,
  display_name text generated always as (trim(first_name || ' ' || last_name)) stored,
  default_role public.user_role not null,
  account_status public.account_status not null default 'pending_verification',
  is_active boolean not null default true,
  email_verified_at timestamptz,
  last_login_at timestamptz,
  must_accept_legal_documents boolean not null default false,
  marketing_consent boolean not null default false,
  mfa_enrolled boolean not null default false,
  mfa_required boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1
);

create table public.legal_documents (
  id uuid primary key default gen_random_uuid(),
  document_type public.legal_document_type not null,
  version text not null,
  locale text not null default 'it-IT',
  content_url text not null,
  effective_date date not null,
  is_active boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  unique (document_type, version, locale)
);

create table public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  legal_document_id uuid references public.legal_documents(id) on delete set null,
  accepted_at timestamptz not null default timezone('utc', now()),
  ip_address inet,
  user_agent text,
  consent_type public.consent_type not null,
  is_required boolean not null default false,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

-- ============================================================================
-- FARMS, ACCESS, AND SUBSCRIPTIONS
-- ============================================================================

create table public.farms (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id),
  name text not null,
  farm_code text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  owner_user_id uuid not null references public.profiles(id),
  provider public.subscription_provider not null,
  provider_customer_id text,
  provider_subscription_id text,
  plan text not null,
  status public.subscription_status not null,
  current_period_start timestamptz,
  current_period_end timestamptz,
  grace_period_until timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1
);

create table public.farm_invites (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  invited_email text,
  invite_code text not null unique,
  invited_role public.user_role not null check (invited_role in ('veterinarian', 'hoof_trimmer', 'farm_collaborator')),
  created_by_profile_id uuid not null references public.profiles(id),
  accepted_by_profile_id uuid references public.profiles(id),
  expires_at timestamptz,
  accepted_at timestamptz,
  revoked_at timestamptz,
  status public.invite_status not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1
);

create table public.farm_users (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.user_role not null check (role <> 'super_admin'),
  status public.membership_status not null default 'active',
  granted_by_profile_id uuid references public.profiles(id),
  accepted_invite_id uuid references public.farm_invites(id) on delete set null,
  granted_at timestamptz not null default timezone('utc', now()),
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1,
  unique (farm_id, profile_id)
);

-- ============================================================================
-- FARM DATA
-- ============================================================================

create table public.cows (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  cow_identifier text not null,
  display_identifier text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1,
  unique (farm_id, cow_identifier)
);

create table public.trimming_sessions (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  created_by_profile_id uuid not null references public.profiles(id),
  updated_by_profile_id uuid references public.profiles(id),
  title text,
  notes text,
  status public.session_status not null default 'open',
  started_at timestamptz not null default timezone('utc', now()),
  ended_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1
);

create table public.trimming_session_days (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.trimming_sessions(id) on delete cascade,
  work_date date not null,
  opened_by_profile_id uuid references public.profiles(id),
  closed_by_profile_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  unique (session_id, work_date)
);

create table public.cow_visits (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.trimming_sessions(id) on delete cascade,
  farm_id uuid not null references public.farms(id) on delete cascade,
  cow_id uuid not null references public.cows(id) on delete restrict,
  visit_date date not null default current_date,
  insertion_index integer not null,
  criticality_score integer not null default 0 check (criticality_score >= 0),
  sole_count integer not null default 0 check (sole_count >= 0),
  bandage_count integer not null default 0 check (bandage_count >= 0),
  corkscrew_grade integer check (corkscrew_grade between 1 and 3),
  laminitis_status public.laminitis_status,
  antibiotic_given boolean not null default false,
  antiinflammatory_given boolean not null default false,
  straw_box_required boolean not null default false,
  evaluate_culling boolean not null default false,
  is_chronic_cow boolean not null default false,
  other_flag boolean not null default false,
  notes text,
  created_by_profile_id uuid not null references public.profiles(id),
  updated_by_profile_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1,
  unique (session_id, cow_id),
  unique (session_id, insertion_index)
);

create table public.cow_visit_flags (
  id uuid primary key default gen_random_uuid(),
  cow_visit_id uuid not null references public.cow_visits(id) on delete cascade,
  flag_key text not null,
  flag_value_text text,
  flag_value_number numeric,
  flag_value_boolean boolean,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1
);

create table public.claw_zone_observations (
  id uuid primary key default gen_random_uuid(),
  cow_visit_id uuid not null references public.cow_visits(id) on delete cascade,
  claw_number integer not null check (claw_number between 1 and 8),
  zone_type public.zone_type not null,
  zone_code text not null,
  observation_group text not null,
  extension_grade integer check (extension_grade between 1 and 3),
  lesion_code public.horn_lesion_code,
  derma_stage_code public.derma_stage_code,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1,
  check (
    (zone_type = 'horn' and lesion_code is not null and derma_stage_code is null)
    or
    (zone_type = 'derma' and lesion_code is null and derma_stage_code is not null)
  )
);

-- ============================================================================
-- TASKS
-- ============================================================================

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  session_id uuid references public.trimming_sessions(id) on delete set null,
  cow_visit_id uuid references public.cow_visits(id) on delete set null,
  cow_id uuid references public.cows(id) on delete set null,
  task_type public.task_type not null,
  title text not null,
  details text,
  due_date date,
  status public.task_status not null default 'open',
  delivery_state public.delivery_state not null default 'not_sent',
  created_by_profile_id uuid not null references public.profiles(id),
  updated_by_profile_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1
);

create table public.task_deliveries (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  channel public.delivery_channel not null,
  status public.delivery_state not null default 'not_sent',
  scheduled_at timestamptz,
  sent_at timestamptz,
  payload jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

-- ============================================================================
-- AUDIT LOGS
-- ============================================================================

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(id) on delete set null,
  farm_id uuid references public.farms(id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  ip_address inet,
  device_id uuid
);

-- ============================================================================
-- OFFLINE / SYNC
-- ============================================================================

create table public.sync_devices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  device_label text,
  platform text,
  app_version text,
  is_active boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  unique (profile_id, device_label)
);

create table public.sync_mutations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  device_id uuid references public.sync_devices(id) on delete set null,
  farm_id uuid references public.farms(id) on delete set null,
  local_mutation_id text not null,
  local_record_id text,
  remote_record_id uuid,
  table_name text not null,
  record_id uuid,
  operation public.mutation_operation not null,
  payload jsonb not null,
  client_record_version integer,
  sync_status public.sync_status not null default 'pending',
  retry_count integer not null default 0,
  last_attempt_at timestamptz,
  error_message text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  record_version integer not null default 1,
  unique (device_id, local_mutation_id)
);

create table public.sync_conflicts (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  record_id uuid,
  farm_id uuid references public.farms(id) on delete set null,
  device_id uuid references public.sync_devices(id) on delete set null,
  local_mutation_id text,
  local_record_id text,
  server_payload jsonb,
  local_payload jsonb,
  conflict_reason text not null,
  status public.conflict_status not null default 'open',
  resolution_notes text,
  resolved_by_profile_id uuid references public.profiles(id),
  resolved_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

-- Record-level sync metadata for native mobile offline-first workflows.
alter table public.farm_users
add column client_local_id text,
add column sync_status public.record_sync_status not null default 'synced',
add column last_device_id uuid references public.sync_devices(id),
add column last_synced_at timestamptz,
add column deleted_at timestamptz;

alter table public.cows
add column client_local_id text,
add column sync_status public.record_sync_status not null default 'synced',
add column last_device_id uuid references public.sync_devices(id),
add column last_synced_at timestamptz,
add column deleted_at timestamptz;

alter table public.trimming_sessions
add column client_local_id text,
add column sync_status public.record_sync_status not null default 'synced',
add column last_device_id uuid references public.sync_devices(id),
add column last_synced_at timestamptz,
add column deleted_at timestamptz;

alter table public.cow_visits
add column client_local_id text,
add column sync_status public.record_sync_status not null default 'synced',
add column last_device_id uuid references public.sync_devices(id),
add column last_synced_at timestamptz,
add column deleted_at timestamptz;

alter table public.claw_zone_observations
add column client_local_id text,
add column sync_status public.record_sync_status not null default 'synced',
add column last_device_id uuid references public.sync_devices(id),
add column last_synced_at timestamptz,
add column deleted_at timestamptz;

alter table public.tasks
add column client_local_id text,
add column sync_status public.record_sync_status not null default 'synced',
add column last_device_id uuid references public.sync_devices(id),
add column last_synced_at timestamptz,
add column deleted_at timestamptz;

-- ============================================================================
-- INDEXES
-- ============================================================================

create index idx_legal_documents_active on public.legal_documents(document_type, locale, is_active);
create index idx_user_consents_user_type on public.user_consents(user_id, consent_type);
create index idx_farm_users_profile on public.farm_users(profile_id);
create index idx_farm_users_farm on public.farm_users(farm_id);
create index idx_farm_invites_farm on public.farm_invites(farm_id);
create index idx_subscriptions_farm on public.subscriptions(farm_id, status);
create index idx_cows_farm on public.cows(farm_id);
create index idx_sessions_farm on public.trimming_sessions(farm_id);
create index idx_cow_visits_session on public.cow_visits(session_id);
create index idx_cow_visits_farm_cow on public.cow_visits(farm_id, cow_id);
create index idx_claw_zone_observations_visit on public.claw_zone_observations(cow_visit_id);
create index idx_tasks_farm_status on public.tasks(farm_id, status);
create index idx_audit_logs_actor_created on public.audit_logs(actor_user_id, created_at desc);
create index idx_audit_logs_farm_created on public.audit_logs(farm_id, created_at desc);
create index idx_sync_mutations_profile_status on public.sync_mutations(profile_id, sync_status);
create index idx_sync_conflicts_farm_status on public.sync_conflicts(farm_id, status);
create index idx_cows_sync_status on public.cows(farm_id, sync_status);
create index idx_sessions_sync_status on public.trimming_sessions(farm_id, sync_status);
create index idx_cow_visits_sync_status on public.cow_visits(farm_id, sync_status);
create index idx_tasks_sync_status on public.tasks(farm_id, sync_status);

-- ============================================================================
-- UPDATED_AT TRIGGERS
-- ============================================================================

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger trg_farms_updated_at
before update on public.farms
for each row execute function public.set_updated_at();

create trigger trg_subscriptions_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

create trigger trg_farm_invites_updated_at
before update on public.farm_invites
for each row execute function public.set_updated_at();

create trigger trg_farm_users_updated_at
before update on public.farm_users
for each row execute function public.set_updated_at();

create trigger trg_cows_updated_at
before update on public.cows
for each row execute function public.set_updated_at();

create trigger trg_trimming_sessions_updated_at
before update on public.trimming_sessions
for each row execute function public.set_updated_at();

create trigger trg_cow_visits_updated_at
before update on public.cow_visits
for each row execute function public.set_updated_at();

create trigger trg_cow_visit_flags_updated_at
before update on public.cow_visit_flags
for each row execute function public.set_updated_at();

create trigger trg_claw_zone_observations_updated_at
before update on public.claw_zone_observations
for each row execute function public.set_updated_at();

create trigger trg_tasks_updated_at
before update on public.tasks
for each row execute function public.set_updated_at();

create trigger trg_sync_mutations_updated_at
before update on public.sync_mutations
for each row execute function public.set_updated_at();

-- ============================================================================
-- ACCESS HELPERS
-- ============================================================================

create or replace function public.current_profile_id()
returns uuid
language sql
stable
as $$
  select id
  from public.profiles
  where auth_user_id = auth.uid()
  limit 1
$$;

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
as $$
  select default_role
  from public.profiles
  where id = public.current_profile_id()
  limit 1
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = public.current_profile_id()
      and p.default_role = 'super_admin'
      and p.is_active = true
      and p.account_status = 'active'
  )
$$;

create or replace function public.is_profile_active()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = public.current_profile_id()
      and p.is_active = true
      and p.account_status = 'active'
  )
$$;

create or replace function public.is_email_verified(target_profile_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = target_profile_id
      and p.email_verified_at is not null
  )
$$;

create or replace function public.has_required_legal_consents(target_profile_id uuid)
returns boolean
language sql
stable
as $$
  select not exists (
    select 1
    from public.legal_documents ld
    where ld.is_active = true
      and ld.document_type in ('privacy_policy', 'terms_of_service')
      and not exists (
        select 1
        from public.user_consents uc
        where uc.user_id = target_profile_id
          and uc.legal_document_id = ld.id
          and uc.revoked_at is null
      )
  )
$$;

create or replace function public.is_user_fully_enabled(target_profile_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = target_profile_id
      and p.is_active = true
      and p.account_status = 'active'
  )
  and public.is_email_verified(target_profile_id)
  and public.has_required_legal_consents(target_profile_id)
$$;

create or replace function public.is_farm_owner(target_farm_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.farms f
    where f.id = target_farm_id
      and f.owner_profile_id = public.current_profile_id()
  )
$$;

create or replace function public.can_access_farm(target_farm_id uuid)
returns boolean
language sql
stable
as $$
  select public.is_user_fully_enabled(public.current_profile_id())
  and (
    public.is_super_admin()
  or (
      (
      exists (
        select 1
        from public.farms f
        where f.id = target_farm_id
          and f.owner_profile_id = public.current_profile_id()
          and f.is_active = true
      )
      or exists (
        select 1
        from public.farm_users fu
        join public.farms f on f.id = fu.farm_id
        where fu.farm_id = target_farm_id
          and fu.profile_id = public.current_profile_id()
          and fu.status = 'active'
          and fu.deleted_at is null
          and f.is_active = true
      )
    )
    )
  )
$$;

create or replace function public.has_write_subscription(target_farm_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.subscriptions s
    where s.farm_id = target_farm_id
      and (
        s.status in ('trialing', 'active')
        or (
          s.grace_period_until is not null
          and s.grace_period_until >= timezone('utc', now())
        )
      )
  )
$$;

create or replace function public.can_write_farm(target_farm_id uuid)
returns boolean
language sql
stable
as $$
  select public.can_access_farm(target_farm_id)
    and public.has_write_subscription(target_farm_id)
$$;

-- Secure invite acceptance path for authenticated operators.
create or replace function public.accept_farm_invite(p_invite_code text)
returns table (farm_id uuid, assigned_role public.user_role)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_email text;
  v_invite public.farm_invites%rowtype;
  v_existing_membership public.farm_users%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  v_profile_id := public.current_profile_id();

  if v_profile_id is null then
    raise exception 'Profile not found';
  end if;

  if not public.is_user_fully_enabled(v_profile_id) then
    raise exception 'User is not fully enabled';
  end if;

  select p.email
  into v_email
  from public.profiles p
  where p.id = v_profile_id;

  select fi.*
  into v_invite
  from public.farm_invites fi
  where fi.invite_code = p_invite_code
    and fi.status = 'pending'
    and fi.revoked_at is null
    and (fi.expires_at is null or fi.expires_at >= timezone('utc', now()))
  for update;

  if not found then
    raise exception 'Invite not found or no longer valid';
  end if;

  if v_invite.invited_email is not null and lower(v_invite.invited_email) <> lower(v_email) then
    raise exception 'Invite email does not match authenticated user';
  end if;

  select fu.*
  into v_existing_membership
  from public.farm_users fu
  where fu.farm_id = v_invite.farm_id
    and fu.profile_id = v_profile_id
  for update;

  if found then
    if v_existing_membership.status = 'active' and v_existing_membership.deleted_at is null then
      raise exception 'Farm access already exists for this user';
    end if;

    update public.farm_users
    set role = v_invite.invited_role,
        status = 'active',
        granted_by_profile_id = v_invite.created_by_profile_id,
        accepted_invite_id = v_invite.id,
        granted_at = timezone('utc', now()),
        revoked_at = null,
        deleted_at = null,
        sync_status = 'synced',
        last_synced_at = timezone('utc', now())
    where id = v_existing_membership.id;
  else
    insert into public.farm_users (
      farm_id,
      profile_id,
      role,
      status,
      granted_by_profile_id,
      accepted_invite_id,
      granted_at,
      sync_status,
      last_synced_at
    )
    values (
      v_invite.farm_id,
      v_profile_id,
      v_invite.invited_role,
      'active',
      v_invite.created_by_profile_id,
      v_invite.id,
      timezone('utc', now()),
      'synced',
      timezone('utc', now())
    );
  end if;

  update public.farm_invites
  set accepted_by_profile_id = v_profile_id,
      accepted_at = timezone('utc', now()),
      status = 'accepted'
  where id = v_invite.id;

  insert into public.audit_logs (
    actor_user_id,
    farm_id,
    entity_type,
    entity_id,
    action,
    new_values,
    created_at
  )
  values (
    v_profile_id,
    v_invite.farm_id,
    'farm_invite',
    v_invite.id,
    'accept_invite',
    jsonb_build_object(
      'farm_id', v_invite.farm_id,
      'assigned_role', v_invite.invited_role,
      'invite_id', v_invite.id
    ),
    timezone('utc', now())
  );

  return query
  select v_invite.farm_id, v_invite.invited_role;
end;
$$;

create or replace view public.active_farm_users
with (security_invoker = true) as
select *
from public.farm_users
where deleted_at is null
  and status = 'active';

create or replace view public.active_animals
with (security_invoker = true) as
select *
from public.cows
where deleted_at is null
  and is_active = true;

create or replace view public.active_trimming_sessions
with (security_invoker = true) as
select *
from public.trimming_sessions
where deleted_at is null;

create or replace view public.active_cow_visits
with (security_invoker = true) as
select *
from public.cow_visits
where deleted_at is null;

create or replace view public.active_claw_observations
with (security_invoker = true) as
select *
from public.claw_zone_observations
where deleted_at is null
  and is_active = true;

create or replace view public.active_clinical_tasks
with (security_invoker = true) as
select *
from public.tasks
where deleted_at is null;

create or replace view public.farm_access_modes
with (security_invoker = true) as
select
  f.id as farm_id,
  case
    when public.can_write_farm(f.id) then 'writable'
    when public.can_access_farm(f.id) then 'read_only'
    else 'blocked'
  end as access_mode,
  case
    when public.can_write_farm(f.id) then null
    when public.can_access_farm(f.id) then 'subscription_inactive_or_read_only'
    else 'blocked_or_not_authorized'
  end as reason,
  public.can_access_farm(f.id) as can_read,
  public.can_write_farm(f.id) as can_write
from public.farms f
where public.can_access_farm(f.id);

revoke all on function public.accept_farm_invite(text) from public;
grant execute on function public.accept_farm_invite(text) to authenticated;
grant select on public.active_farm_users to authenticated;
grant select on public.active_animals to authenticated;
grant select on public.active_trimming_sessions to authenticated;
grant select on public.active_cow_visits to authenticated;
grant select on public.active_claw_observations to authenticated;
grant select on public.active_clinical_tasks to authenticated;
grant select on public.farm_access_modes to authenticated;
