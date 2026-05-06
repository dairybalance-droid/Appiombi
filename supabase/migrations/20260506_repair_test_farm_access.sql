-- Repair migration for local test data access.
-- Ensures the current test profile owns and is actively linked to the seeded farm.

do $$
declare
  v_profile_id uuid;
  v_farm_id uuid;
begin
  select p.id
  into v_profile_id
  from public.profiles p
  where lower(p.email) = lower('allevatore.test@appiombi.local')
  order by p.created_at desc
  limit 1;

  if v_profile_id is null then
    raise exception 'Profile not found for allevatore.test@appiombi.local';
  end if;

  select f.id
  into v_farm_id
  from public.farms f
  where f.farm_code = 'azienda-test-appiombi'
     or f.name = 'Azienda Test Appiombi'
  order by f.created_at desc
  limit 1;

  if v_farm_id is null then
    raise exception 'Test farm not found';
  end if;

  update public.farms
  set owner_profile_id = v_profile_id
  where id = v_farm_id
    and owner_profile_id <> v_profile_id;

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
  values (
    v_farm_id,
    v_profile_id,
    'farmer'::public.user_role,
    'active'::public.membership_status,
    v_profile_id,
    timezone('utc', now()),
    'synced'::public.record_sync_status,
    timezone('utc', now())
  )
  on conflict (farm_id, profile_id) do update
  set role = excluded.role,
      status = 'active'::public.membership_status,
      granted_by_profile_id = excluded.granted_by_profile_id,
      revoked_at = null,
      deleted_at = null,
      sync_status = 'synced'::public.record_sync_status,
      last_synced_at = timezone('utc', now());

  update public.subscriptions
  set owner_user_id = v_profile_id
  where farm_id = v_farm_id
    and owner_user_id <> v_profile_id;
end
$$;
