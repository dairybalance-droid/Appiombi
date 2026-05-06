-- Seed migration for initial Appiombi test data.
-- Uses existing Auth/Profile user: allevatore.test@appiombi.local
-- Note: the current `farms` schema does not yet include columns for:
-- provincia, regione, nazione, destinazione latte.
-- The farm is seeded with the supported fields only.

do $$
begin
  if not exists (
    select 1
    from public.profiles p
    where lower(p.email) = lower('allevatore.test@appiombi.local')
  ) then
    raise exception 'Required profile not found for allevatore.test@appiombi.local';
  end if;
end
$$;

-- Create minimal active legal documents only if none active already exist.
insert into public.legal_documents (
  document_type,
  version,
  locale,
  content_url,
  effective_date,
  is_active
)
select
  'privacy_policy'::public.legal_document_type,
  'test-v1',
  'it-IT',
  'app://legal/privacy/test-v1',
  current_date,
  true
where not exists (
  select 1
  from public.legal_documents ld
  where ld.document_type = 'privacy_policy'
    and ld.locale = 'it-IT'
    and ld.is_active = true
);

insert into public.legal_documents (
  document_type,
  version,
  locale,
  content_url,
  effective_date,
  is_active
)
select
  'terms_of_service'::public.legal_document_type,
  'test-v1',
  'it-IT',
  'app://legal/terms/test-v1',
  current_date,
  true
where not exists (
  select 1
  from public.legal_documents ld
  where ld.document_type = 'terms_of_service'
    and ld.locale = 'it-IT'
    and ld.is_active = true
);

-- Ensure required legal consents exist for the existing farmer profile.
insert into public.user_consents (
  user_id,
  legal_document_id,
  accepted_at,
  consent_type,
  is_required
)
select
  p.id,
  ld.id,
  timezone('utc', now()),
  ld.document_type::text::public.consent_type,
  true
from public.profiles p
join public.legal_documents ld
  on ld.document_type in ('privacy_policy', 'terms_of_service')
 and ld.is_active = true
where lower(p.email) = lower('allevatore.test@appiombi.local')
  and not exists (
    select 1
    from public.user_consents uc
    where uc.user_id = p.id
      and uc.legal_document_id = ld.id
      and uc.revoked_at is null
  );

-- If email is already verified and required consents now exist, clear the legal gate
-- and allow active account status for the test profile.
update public.profiles p
set must_accept_legal_documents = false,
    account_status = case
      when p.email_verified_at is not null then 'active'::public.account_status
      else p.account_status
    end
where lower(p.email) = lower('allevatore.test@appiombi.local')
  and exists (
    select 1
    from public.legal_documents ld
    where ld.is_active = true
      and ld.document_type = 'privacy_policy'
      and exists (
        select 1
        from public.user_consents uc
        where uc.user_id = p.id
          and uc.legal_document_id = ld.id
          and uc.revoked_at is null
      )
  )
  and exists (
    select 1
    from public.legal_documents ld
    where ld.is_active = true
      and ld.document_type = 'terms_of_service'
      and exists (
        select 1
        from public.user_consents uc
        where uc.user_id = p.id
          and uc.legal_document_id = ld.id
          and uc.revoked_at is null
      )
  );

-- Create the test farm.
insert into public.farms (
  owner_profile_id,
  name,
  farm_code,
  is_active
)
select
  p.id,
  'Azienda Test Appiombi',
  'azienda-test-appiombi',
  true
from public.profiles p
where lower(p.email) = lower('allevatore.test@appiombi.local')
  and not exists (
    select 1
    from public.farms f
    where f.farm_code = 'azienda-test-appiombi'
  );

-- Create an active manual subscription for the test farm if missing.
insert into public.subscriptions (
  farm_id,
  owner_user_id,
  provider,
  plan,
  status,
  current_period_start,
  current_period_end,
  grace_period_until
)
select
  f.id,
  p.id,
  'manual'::public.subscription_provider,
  'test-active',
  'active'::public.subscription_status,
  timezone('utc', now()),
  timezone('utc', now()) + interval '30 days',
  timezone('utc', now()) + interval '7 days'
from public.farms f
join public.profiles p on p.id = f.owner_profile_id
where f.farm_code = 'azienda-test-appiombi'
  and lower(p.email) = lower('allevatore.test@appiombi.local')
  and not exists (
    select 1
    from public.subscriptions s
    where s.farm_id = f.id
      and s.provider = 'manual'
      and s.plan = 'test-active'
      and s.status in ('trialing', 'active')
  );

-- Create three test cows in the seeded farm.
insert into public.cows (
  farm_id,
  cow_identifier,
  display_identifier,
  is_active
)
select
  f.id,
  cow_seed.cow_identifier,
  cow_seed.cow_identifier,
  true
from public.farms f
cross join (
  values
    ('101'),
    ('234'),
    ('789')
) as cow_seed(cow_identifier)
where f.farm_code = 'azienda-test-appiombi'
on conflict (farm_id, cow_identifier) do nothing;
