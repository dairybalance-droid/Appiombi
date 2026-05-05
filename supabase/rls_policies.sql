-- Appiombi RLS policies
-- These policies assume authenticated access through Supabase Auth and a linked
-- row in public.profiles for each signed-in user.

alter table public.profiles enable row level security;
alter table public.legal_documents enable row level security;
alter table public.user_consents enable row level security;
alter table public.farms enable row level security;
alter table public.subscriptions enable row level security;
alter table public.farm_invites enable row level security;
alter table public.farm_users enable row level security;
alter table public.cows enable row level security;
alter table public.trimming_sessions enable row level security;
alter table public.trimming_session_days enable row level security;
alter table public.cow_visits enable row level security;
alter table public.cow_visit_flags enable row level security;
alter table public.claw_zone_observations enable row level security;
alter table public.tasks enable row level security;
alter table public.task_deliveries enable row level security;
alter table public.audit_logs enable row level security;
alter table public.sync_devices enable row level security;
alter table public.sync_mutations enable row level security;
alter table public.sync_conflicts enable row level security;

-- ============================================================================
-- APP PROFILES
-- ============================================================================

create policy "profiles_select_self_or_admin"
on public.profiles
for select
to authenticated
using (
  auth_user_id = auth.uid()
  or public.is_super_admin()
);

create policy "profiles_insert_self"
on public.profiles
for insert
to authenticated
with check (
  auth_user_id = auth.uid()
  and default_role in ('farmer', 'veterinarian', 'hoof_trimmer')
);

create policy "profiles_update_self_or_admin"
on public.profiles
for update
to authenticated
using (
  auth_user_id = auth.uid()
  or public.is_super_admin()
)
with check (
  (
    auth_user_id = auth.uid()
    and default_role in ('farmer', 'veterinarian', 'hoof_trimmer', 'farm_collaborator')
  )
  or public.is_super_admin()
);

-- ============================================================================
-- LEGAL DOCUMENTS AND CONSENTS
-- ============================================================================

create policy "legal_documents_select_authenticated"
on public.legal_documents
for select
to authenticated
using (true);

create policy "legal_documents_manage_admin_only"
on public.legal_documents
for all
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

create policy "user_consents_select_self_or_admin"
on public.user_consents
for select
to authenticated
using (
  user_id = public.current_profile_id()
  or public.is_super_admin()
);

create policy "user_consents_insert_self_or_admin"
on public.user_consents
for insert
to authenticated
with check (
  user_id = public.current_profile_id()
  or public.is_super_admin()
);

-- ============================================================================
-- FARMS
-- ============================================================================

create policy "farms_select_accessible"
on public.farms
for select
to authenticated
using (public.can_access_farm(id));

create policy "farms_insert_owner_only"
on public.farms
for insert
to authenticated
with check (
  owner_profile_id = public.current_profile_id()
  and public.is_profile_active()
);

create policy "farms_update_owner_or_admin"
on public.farms
for update
to authenticated
using (
  public.is_farm_owner(id)
  or public.is_super_admin()
)
with check (
  public.is_farm_owner(id)
  or public.is_super_admin()
);

-- ============================================================================
-- SUBSCRIPTIONS
-- ============================================================================

create policy "subscriptions_select_owner_or_admin"
on public.subscriptions
for select
to authenticated
using (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
);

create policy "subscriptions_insert_owner_or_admin"
on public.subscriptions
for insert
to authenticated
with check (
  owner_user_id = public.current_profile_id()
  and (
    public.is_farm_owner(farm_id)
    or public.is_super_admin()
  )
);

create policy "subscriptions_update_owner_or_admin"
on public.subscriptions
for update
to authenticated
using (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
)
with check (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
);

-- ============================================================================
-- FARM INVITES
-- ============================================================================

-- Generic or email-bound invite redemption is handled through the protected
-- `accept_farm_invite(invite_code text)` RPC. Base-table access remains
-- restricted so the client cannot self-authorize with direct writes.

create policy "farm_invites_select_owner_target_or_admin"
on public.farm_invites
for select
to authenticated
using (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
  or (
    invited_email is not null
    and exists (
      select 1
      from public.profiles p
      where p.id = public.current_profile_id()
        and lower(p.email) = lower(farm_invites.invited_email)
    )
  )
);

create policy "farm_invites_insert_owner_only"
on public.farm_invites
for insert
to authenticated
with check (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
);

create policy "farm_invites_update_owner_or_admin"
on public.farm_invites
for update
to authenticated
using (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
)
with check (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
);

-- ============================================================================
-- FARM USERS
-- ============================================================================

create policy "farm_users_select_accessible"
on public.farm_users
for select
to authenticated
using (
  profile_id = public.current_profile_id()
  or public.is_farm_owner(farm_id)
  or public.is_super_admin()
);

create policy "farm_users_insert_owner_or_admin"
on public.farm_users
for insert
to authenticated
with check (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
);

create policy "farm_users_update_owner_or_admin"
on public.farm_users
for update
to authenticated
using (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
)
with check (
  public.is_farm_owner(farm_id)
  or public.is_super_admin()
);

-- ============================================================================
-- COWS
-- ============================================================================

create policy "cows_select_accessible"
on public.cows
for select
to authenticated
using (public.can_access_farm(farm_id));

create policy "cows_insert_writable"
on public.cows
for insert
to authenticated
with check (public.can_write_farm(farm_id));

create policy "cows_update_writable"
on public.cows
for update
to authenticated
using (public.can_write_farm(farm_id))
with check (public.can_write_farm(farm_id));

-- ============================================================================
-- SESSIONS
-- ============================================================================

create policy "sessions_select_accessible"
on public.trimming_sessions
for select
to authenticated
using (public.can_access_farm(farm_id));

create policy "sessions_insert_writable"
on public.trimming_sessions
for insert
to authenticated
with check (
  public.can_write_farm(farm_id)
  and created_by_profile_id = public.current_profile_id()
);

create policy "sessions_update_writable"
on public.trimming_sessions
for update
to authenticated
using (public.can_write_farm(farm_id))
with check (public.can_write_farm(farm_id));

-- ============================================================================
-- SESSION DAYS
-- ============================================================================

create policy "session_days_select_accessible"
on public.trimming_session_days
for select
to authenticated
using (
  exists (
    select 1
    from public.trimming_sessions s
    where s.id = session_id
      and public.can_access_farm(s.farm_id)
  )
);

create policy "session_days_insert_writable"
on public.trimming_session_days
for insert
to authenticated
with check (
  exists (
    select 1
    from public.trimming_sessions s
    where s.id = session_id
      and public.can_write_farm(s.farm_id)
  )
);

create policy "session_days_update_writable"
on public.trimming_session_days
for update
to authenticated
using (
  exists (
    select 1
    from public.trimming_sessions s
    where s.id = session_id
      and public.can_write_farm(s.farm_id)
  )
)
with check (
  exists (
    select 1
    from public.trimming_sessions s
    where s.id = session_id
      and public.can_write_farm(s.farm_id)
  )
);

-- ============================================================================
-- COW VISITS
-- ============================================================================

create policy "cow_visits_select_accessible"
on public.cow_visits
for select
to authenticated
using (public.can_access_farm(farm_id));

create policy "cow_visits_insert_writable"
on public.cow_visits
for insert
to authenticated
with check (
  public.can_write_farm(farm_id)
  and created_by_profile_id = public.current_profile_id()
);

create policy "cow_visits_update_writable"
on public.cow_visits
for update
to authenticated
using (public.can_write_farm(farm_id))
with check (public.can_write_farm(farm_id));

-- ============================================================================
-- COW VISIT FLAGS
-- ============================================================================

create policy "cow_visit_flags_select_accessible"
on public.cow_visit_flags
for select
to authenticated
using (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_access_farm(cv.farm_id)
  )
);

create policy "cow_visit_flags_insert_writable"
on public.cow_visit_flags
for insert
to authenticated
with check (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_write_farm(cv.farm_id)
  )
);

create policy "cow_visit_flags_update_writable"
on public.cow_visit_flags
for update
to authenticated
using (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_write_farm(cv.farm_id)
  )
)
with check (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_write_farm(cv.farm_id)
  )
);

-- ============================================================================
-- CLAW ZONE OBSERVATIONS
-- ============================================================================

create policy "claw_observations_select_accessible"
on public.claw_zone_observations
for select
to authenticated
using (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_access_farm(cv.farm_id)
  )
);

create policy "claw_observations_insert_writable"
on public.claw_zone_observations
for insert
to authenticated
with check (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_write_farm(cv.farm_id)
  )
);

create policy "claw_observations_update_writable"
on public.claw_zone_observations
for update
to authenticated
using (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_write_farm(cv.farm_id)
  )
)
with check (
  exists (
    select 1
    from public.cow_visits cv
    where cv.id = cow_visit_id
      and public.can_write_farm(cv.farm_id)
  )
);

-- ============================================================================
-- TASKS
-- ============================================================================

create policy "tasks_select_accessible"
on public.tasks
for select
to authenticated
using (public.can_access_farm(farm_id));

create policy "tasks_insert_writable"
on public.tasks
for insert
to authenticated
with check (
  public.can_write_farm(farm_id)
  and created_by_profile_id = public.current_profile_id()
);

create policy "tasks_update_writable"
on public.tasks
for update
to authenticated
using (public.can_write_farm(farm_id))
with check (public.can_write_farm(farm_id));

create policy "task_deliveries_select_accessible"
on public.task_deliveries
for select
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and public.can_access_farm(t.farm_id)
  )
);

create policy "task_deliveries_insert_writable"
on public.task_deliveries
for insert
to authenticated
with check (
  exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and public.can_write_farm(t.farm_id)
  )
);

create policy "task_deliveries_update_writable"
on public.task_deliveries
for update
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and public.can_write_farm(t.farm_id)
  )
)
with check (
  exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and public.can_write_farm(t.farm_id)
  )
);

-- ============================================================================
-- AUDIT LOGS
-- ============================================================================

create policy "audit_logs_select_owner_self_or_admin"
on public.audit_logs
for select
to authenticated
using (
  actor_user_id = public.current_profile_id()
  or (farm_id is not null and public.is_farm_owner(farm_id))
  or public.is_super_admin()
);

create policy "audit_logs_insert_self_accessible_or_admin"
on public.audit_logs
for insert
to authenticated
with check (
  public.is_super_admin()
);

-- ============================================================================
-- SYNC TABLES
-- ============================================================================

create policy "sync_devices_select_self_or_admin"
on public.sync_devices
for select
to authenticated
using (
  profile_id = public.current_profile_id()
  or public.is_super_admin()
);

create policy "sync_devices_insert_self_or_admin"
on public.sync_devices
for insert
to authenticated
with check (
  profile_id = public.current_profile_id()
  or public.is_super_admin()
);

create policy "sync_devices_update_self_or_admin"
on public.sync_devices
for update
to authenticated
using (
  profile_id = public.current_profile_id()
  or public.is_super_admin()
)
with check (
  profile_id = public.current_profile_id()
  or public.is_super_admin()
);

create policy "sync_mutations_select_self_or_admin"
on public.sync_mutations
for select
to authenticated
using (
  profile_id = public.current_profile_id()
  or public.is_super_admin()
);

create policy "sync_mutations_insert_self_authorized_or_admin"
on public.sync_mutations
for insert
to authenticated
with check (
  (profile_id = public.current_profile_id() or public.is_super_admin())
  and (
    farm_id is null
    or public.can_access_farm(farm_id)
    or public.is_super_admin()
  )
);

create policy "sync_mutations_update_self_authorized_or_admin"
on public.sync_mutations
for update
to authenticated
using (
  profile_id = public.current_profile_id()
  or public.is_super_admin()
)
with check (
  (profile_id = public.current_profile_id() or public.is_super_admin())
  and (
    farm_id is null
    or public.can_access_farm(farm_id)
    or public.is_super_admin()
  )
);

create policy "sync_conflicts_select_accessible"
on public.sync_conflicts
for select
to authenticated
using (
  farm_id is null
  or public.can_access_farm(farm_id)
  or public.is_super_admin()
);

create policy "sync_conflicts_insert_accessible_or_admin"
on public.sync_conflicts
for insert
to authenticated
with check (
  farm_id is null
  or public.can_access_farm(farm_id)
  or public.is_super_admin()
);

create policy "sync_conflicts_update_accessible_or_admin"
on public.sync_conflicts
for update
to authenticated
using (
  farm_id is null
  or public.can_access_farm(farm_id)
  or public.is_super_admin()
)
with check (
  farm_id is null
  or public.can_access_farm(farm_id)
  or public.is_super_admin()
);
