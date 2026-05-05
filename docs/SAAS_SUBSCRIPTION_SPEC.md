# SaaS Subscription Specification

## Purpose

Define how Appiombi models subscription state for farm ownership and paid SaaS access without implementing real billing logic yet.

## Scope

- database model for subscriptions
- access impact on farm write permissions
- grace period behavior
- reactivation behavior
- legal retention considerations

## Subscription Entity

`subscriptions` tracks farm-level billing state.

Core fields:

- `farm_id`
- `owner_user_id`
- `provider`
- `provider_customer_id`
- `provider_subscription_id`
- `plan`
- `status`
- `current_period_start`
- `current_period_end`
- `grace_period_until`

## Providers

- `stripe`
- `revenuecat`
- `manual`

No provider integration is implemented in MVP.

## Status Model

- `trialing`
- `active`
- `past_due`
- `paused`
- `canceled`
- `expired`

## Access Rules

### Read Access

- farm owners must retain visibility to their business data unless a later legal review defines narrower restrictions
- operators may still be limited by normal farm membership revocation rules

### Write Access

- writable when status is `trialing` or `active`
- writable when inside configured `grace_period_until`
- otherwise farm may become read-only

### Access Mode Exposure

Invited operators should be able to determine the current access mode of authorized farms without reading raw subscription rows.

Recommended backend shape:

- view or helper such as `farm_access_modes`

Suggested fields:

- `farm_id`
- `access_mode`
- `reason`
- `can_read`
- `can_write`

Expected modes:

- `writable`
- `read_only`
- `blocked`, reserved for non-readable or administratively blocked states where exposed by backend logic

### Export

- farmer data export should remain possible if legally required, even when subscription is no longer active

## Grace Period

- grace period is configurable through stored `grace_period_until`
- during grace, the farm remains writable
- after grace, read-only rules may apply

## Reactivation

- when subscription becomes active again, write access is restored
- no automatic data deletion should occur during inactive periods

## Ownership Notes

- subscription is modeled at farm level
- `owner_user_id` points to the paying owner profile
- historical subscription rows should be preserved for audit

## Security Notes

- client must not be trusted as source of billing truth
- subscription gating must be enforced server-side for write policies
- no payment secrets or webhook secrets should be stored in this repository
