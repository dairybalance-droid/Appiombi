-- Performance fix for farms SELECT RLS.
-- Problem:
-- The original farms SELECT policy delegates to public.can_access_farm(id),
-- and that helper also queries public.farms, which can introduce recursive or
-- overly expensive evaluation during SELECT on farms.
--
-- Goal:
-- Keep RLS enabled and preserve security, but replace the farms SELECT policy
-- with a direct membership/ownership check that does not recurse through farms.

drop policy if exists "farms_select_accessible" on public.farms;

create policy "farms_select_accessible"
on public.farms
for select
to authenticated
using (
  public.is_user_fully_enabled(public.current_profile_id())
  and (
    public.is_super_admin()
    or owner_profile_id = public.current_profile_id()
    or exists (
      select 1
      from public.farm_users fu
      where fu.farm_id = farms.id
        and fu.profile_id = public.current_profile_id()
        and fu.status = 'active'
        and fu.deleted_at is null
    )
  )
);
