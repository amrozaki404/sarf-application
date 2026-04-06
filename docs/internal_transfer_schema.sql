-- Internal transfer foundation schema for PostgreSQL.
-- If auth already exists in another service, replace app_user references
-- with your existing user table and keep the transfer-domain tables.

create extension if not exists pgcrypto;

create type method_type as enum (
  'bank',
  'wallet',
  'cash',
  'international'
);

create type fee_type as enum (
  'fixed',
  'percentage'
);

create type transfer_status as enum (
  'draft',
  'quote_ready',
  'payment_pending',
  'receipt_uploaded',
  'under_review',
  'more_info_required',
  'approved',
  'completed',
  'cancelled',
  'rejected',
  'expired'
);

create type attachment_kind as enum (
  'receipt',
  'kyc_document',
  'payout_proof',
  'other'
);

create table if not exists app_user (
  id uuid primary key default gen_random_uuid(),
  account_number varchar(32) unique,
  phone_country_code varchar(8),
  phone_number varchar(32),
  first_name varchar(100) not null,
  last_name varchar(100) not null,
  registration_type varchar(32) not null default 'PHONE',
  status varchar(32) not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists user_device (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_user(id),
  device_id varchar(128) not null unique,
  device_name varchar(255),
  platform varchar(32),
  fcm_token text,
  last_seen_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists service_catalog (
  code varchar(64) primary key,
  name_en varchar(120) not null,
  name_ar varchar(120) not null,
  description_en text,
  description_ar text,
  flow_type varchar(32) not null,
  is_active boolean not null default true,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists currency_catalog (
  code varchar(8) primary key,
  name_en varchar(120) not null,
  name_ar varchar(120) not null,
  decimals smallint not null default 2,
  is_active boolean not null default true
);

create table if not exists transfer_method (
  id uuid primary key default gen_random_uuid(),
  code varchar(64) not null unique,
  service_code varchar(64) not null references service_catalog(code),
  name_en varchar(120) not null,
  name_ar varchar(120) not null,
  method_type method_type not null,
  currency_code varchar(8) not null references currency_catalog(code),
  logo_url text,
  details_hint_en varchar(255),
  details_hint_ar varchar(255),
  requires_account_number boolean not null default true,
  requires_account_holder boolean not null default false,
  is_active boolean not null default true,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transfer_method_service_active
  on transfer_method(service_code, is_active, display_order);

create table if not exists transfer_route (
  id uuid primary key default gen_random_uuid(),
  service_code varchar(64) not null references service_catalog(code),
  from_method_id uuid not null references transfer_method(id),
  to_method_id uuid not null references transfer_method(id),
  rate numeric(18,6) not null default 1,
  min_amount numeric(18,2),
  max_amount numeric(18,2),
  fee_currency_code varchar(8) references currency_catalog(code),
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_transfer_route unique (service_code, from_method_id, to_method_id)
);

create index if not exists idx_transfer_route_service_from
  on transfer_route(service_code, from_method_id, is_active);

create table if not exists merchant (
  id uuid primary key default gen_random_uuid(),
  code varchar(64) not null unique,
  name_en varchar(120) not null,
  name_ar varchar(120) not null,
  logo_url text,
  rating numeric(3,2),
  eta_min_minutes integer,
  eta_max_minutes integer,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists merchant_method_account (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid not null references merchant(id),
  method_id uuid not null references transfer_method(id),
  account_name varchar(255) not null,
  account_number varchar(255) not null,
  institution_name varchar(255) not null,
  note_en text,
  note_ar text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_merchant_method_account_lookup
  on merchant_method_account(merchant_id, method_id, is_active);

create table if not exists merchant_fee_rule (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid not null references merchant(id),
  service_code varchar(64) not null references service_catalog(code),
  from_method_id uuid references transfer_method(id),
  to_method_id uuid references transfer_method(id),
  fee_type fee_type not null,
  fee_value numeric(18,6) not null,
  min_fee numeric(18,2),
  max_fee numeric(18,2),
  priority integer not null default 100,
  is_active boolean not null default true,
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_merchant_fee_rule_match
  on merchant_fee_rule(merchant_id, service_code, is_active, priority);

create table if not exists transfer_quote (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_user(id),
  service_code varchar(64) not null references service_catalog(code),
  route_id uuid not null references transfer_route(id),
  merchant_id uuid not null references merchant(id),
  merchant_account_id uuid not null references merchant_method_account(id),
  send_amount numeric(18,2) not null,
  send_currency_code varchar(8) not null references currency_catalog(code),
  receive_amount numeric(18,2) not null,
  receive_currency_code varchar(8) not null references currency_catalog(code),
  fee_amount numeric(18,2) not null,
  fee_currency_code varchar(8) not null references currency_catalog(code),
  rate numeric(18,6) not null,
  rate_label varchar(255),
  payment_summary text,
  destination_summary text,
  expires_at timestamptz not null,
  request_snapshot jsonb not null default '{}'::jsonb,
  response_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_transfer_quote_user_created
  on transfer_quote(user_id, created_at desc);

create table if not exists transfer_order (
  id uuid primary key default gen_random_uuid(),
  order_reference varchar(64) not null unique,
  user_id uuid not null references app_user(id),
  service_code varchar(64) not null references service_catalog(code),
  quote_id uuid references transfer_quote(id),
  route_id uuid references transfer_route(id),
  source_method_id uuid not null references transfer_method(id),
  destination_method_id uuid not null references transfer_method(id),
  merchant_id uuid not null references merchant(id),
  merchant_account_id uuid references merchant_method_account(id),
  status transfer_status not null default 'under_review',
  customer_reference varchar(255),
  sender_name varchar(255),
  receiver_name varchar(255),
  destination_account_number varchar(255),
  destination_account_holder varchar(255),
  send_amount numeric(18,2) not null,
  send_currency_code varchar(8) not null references currency_catalog(code),
  receive_amount numeric(18,2) not null,
  receive_currency_code varchar(8) not null references currency_catalog(code),
  fee_amount numeric(18,2) not null,
  fee_currency_code varchar(8) not null references currency_catalog(code),
  rate numeric(18,6) not null,
  payment_summary text,
  destination_summary text,
  source_name_snapshot varchar(255),
  source_logo_url_snapshot text,
  destination_name_snapshot varchar(255),
  destination_logo_url_snapshot text,
  created_at timestamptz not null default now(),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  updated_at timestamptz not null default now(),
  extra_data jsonb not null default '{}'::jsonb
);

create index if not exists idx_transfer_order_user_created
  on transfer_order(user_id, created_at desc);

create index if not exists idx_transfer_order_status
  on transfer_order(status, created_at desc);

create table if not exists transfer_attachment (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references transfer_order(id),
  quote_id uuid references transfer_quote(id),
  kind attachment_kind not null,
  original_name varchar(255) not null,
  storage_key text not null,
  public_url text,
  mime_type varchar(120),
  file_size_bytes bigint,
  uploaded_by_user_id uuid references app_user(id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_transfer_attachment_order
  on transfer_attachment(order_id, created_at desc);

create table if not exists transfer_status_event (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references transfer_order(id),
  previous_status transfer_status,
  new_status transfer_status not null,
  actor_type varchar(32) not null,
  actor_id varchar(128),
  note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_transfer_status_event_order
  on transfer_status_event(order_id, created_at desc);

create table if not exists app_notification (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_user(id),
  category varchar(32) not null,
  title_en varchar(255) not null,
  title_ar varchar(255) not null,
  body_en text not null,
  body_ar text not null,
  deep_link varchar(255),
  is_read boolean not null default false,
  read_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_app_notification_user_read
  on app_notification(user_id, is_read, created_at desc);

insert into service_catalog (
  code,
  name_en,
  name_ar,
  description_en,
  description_ar,
  flow_type,
  is_active,
  display_order
) values
  (
    'local_transfer',
    'Internal Transfer',
    'تحويلات محلية',
    'Transfer between supported local banks and wallets.',
    'تحويل بين البنوك والمحافظ المحلية المدعومة.',
    'merchant_routed',
    true,
    1
  ),
  (
    'international_transfer',
    'International Transfer',
    'تحويلات دولية',
    'Receive international remittances through partner exchanges.',
    'استلام الحوالات الدولية عبر الصرافات الشريكة.',
    'exchange_payout',
    true,
    2
  )
on conflict (code) do nothing;

insert into currency_catalog (code, name_en, name_ar, decimals, is_active) values
  ('SDG', 'Sudanese Pound', 'الجنيه السوداني', 2, true),
  ('USD', 'US Dollar', 'الدولار الأمريكي', 2, true),
  ('SAR', 'Saudi Riyal', 'الريال السعودي', 2, true)
on conflict (code) do nothing;
