-- Minimal migration to automatically create application profiles from Supabase Auth users.
-- This does not change existing RLS design or business tables.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_requested_role public.user_role;
  v_has_required_consents boolean;
begin
  v_requested_role := case
    when coalesce(new.raw_user_meta_data ->> 'requested_role', new.raw_user_meta_data ->> 'role', '') = 'veterinarian' then 'veterinarian'::public.user_role
    when coalesce(new.raw_user_meta_data ->> 'requested_role', new.raw_user_meta_data ->> 'role', '') = 'hoof_trimmer' then 'hoof_trimmer'::public.user_role
    else 'farmer'::public.user_role
  end;

  v_has_required_consents :=
    coalesce(lower(new.raw_user_meta_data ->> 'accepted_privacy_policy') in ('true', 't', '1', 'yes'), false)
    and coalesce(lower(new.raw_user_meta_data ->> 'accepted_terms_of_service') in ('true', 't', '1', 'yes'), false);

  insert into public.profiles (
    id,
    auth_user_id,
    email,
    first_name,
    last_name,
    default_role,
    account_status,
    is_active,
    email_verified_at,
    must_accept_legal_documents,
    marketing_consent
  )
  values (
    new.id,
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    v_requested_role,
    case
      when new.email_confirmed_at is not null and v_has_required_consents then 'active'::public.account_status
      else 'pending_verification'::public.account_status
    end,
    true,
    new.email_confirmed_at,
    not v_has_required_consents,
    coalesce(lower(new.raw_user_meta_data ->> 'marketing_consent') in ('true', 't', '1', 'yes'), false)
  )
  on conflict (auth_user_id) do update
  set email = excluded.email,
      email_verified_at = excluded.email_verified_at,
      first_name = case when public.profiles.first_name = '' then excluded.first_name else public.profiles.first_name end,
      last_name = case when public.profiles.last_name = '' then excluded.last_name else public.profiles.last_name end,
      default_role = public.profiles.default_role,
      must_accept_legal_documents = public.profiles.must_accept_legal_documents and excluded.must_accept_legal_documents;

  return new;
end;
$$;

drop trigger if exists trg_handle_new_auth_user on auth.users;

create trigger trg_handle_new_auth_user
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- Backfill profiles for existing auth users that do not yet have a linked profile.
insert into public.profiles (
  id,
  auth_user_id,
  email,
  first_name,
  last_name,
  default_role,
  account_status,
  is_active,
  email_verified_at,
  must_accept_legal_documents,
  marketing_consent
)
select
  au.id,
  au.id,
  au.email,
  coalesce(au.raw_user_meta_data ->> 'first_name', ''),
  coalesce(au.raw_user_meta_data ->> 'last_name', ''),
  case
    when coalesce(au.raw_user_meta_data ->> 'requested_role', au.raw_user_meta_data ->> 'role', '') = 'veterinarian' then 'veterinarian'::public.user_role
    when coalesce(au.raw_user_meta_data ->> 'requested_role', au.raw_user_meta_data ->> 'role', '') = 'hoof_trimmer' then 'hoof_trimmer'::public.user_role
    else 'farmer'::public.user_role
  end,
  'pending_verification'::public.account_status,
  true,
  au.email_confirmed_at,
  true,
  coalesce(lower(au.raw_user_meta_data ->> 'marketing_consent') in ('true', 't', '1', 'yes'), false)
from auth.users au
left join public.profiles p on p.auth_user_id = au.id
where p.auth_user_id is null;
