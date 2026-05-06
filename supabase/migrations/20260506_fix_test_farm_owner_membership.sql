-- Corrective seed migration for linking the test farm owner into farm_users.
-- Uses existing profile: allevatore.test@appiombi.local
-- Uses existing farm: Azienda Test Appiombi

insert into public.farm_users (
  farm_id,
  profile_id,
  role,
  status,
  granted_by_profile_id,
  granted_at,
  sync_status,
  last_synced_at
)
select
  f.id,
  p.id,
  'farmer'::public.user_role,
  'active'::public.membership_status,
  p.id,
  timezone('utc', now()),
  'synced'::public.record_sync_status,
  timezone('utc', now())
from public.profiles p
join public.farms f
  on f.owner_profile_id = p.id
where lower(p.email) = lower('allevatore.test@appiombi.local')
  and f.name = 'Azienda Test Appiombi'
on conflict (farm_id, profile_id) do update
set role = excluded.role,
    status = 'active'::public.membership_status,
    granted_by_profile_id = excluded.granted_by_profile_id,
    revoked_at = null,
    deleted_at = null,
    sync_status = 'synced'::public.record_sync_status,
    last_synced_at = timezone('utc', now());
