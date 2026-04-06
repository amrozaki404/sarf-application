-- International transfer schema addendum.
-- This file assumes the shared foundation in internal_transfer_schema.sql exists.

create extension if not exists pgcrypto;

create table if not exists exchange_house (
  id uuid primary key default gen_random_uuid(),
  code varchar(64) not null unique,
  name_en varchar(120) not null,
  name_ar varchar(120) not null,
  logo_url text,
  note_en text,
  note_ar text,
  is_active boolean not null default true,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists transfer_provider (
  id uuid primary key default gen_random_uuid(),
  code varchar(64) not null unique,
  name_en varchar(120) not null,
  name_ar varchar(120) not null,
  logo_url text,
  note_en text,
  note_ar text,
  is_active boolean not null default true,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists exchange_provider (
  id uuid primary key default gen_random_uuid(),
  exchange_house_id uuid not null references exchange_house(id),
  transfer_provider_id uuid not null references transfer_provider(id),
  is_active boolean not null default true,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_exchange_provider unique (exchange_house_id, transfer_provider_id)
);

create index if not exists idx_exchange_provider_active
  on exchange_provider(exchange_house_id, is_active, display_order);

create table if not exists provider_reference_rule (
  id uuid primary key default gen_random_uuid(),
  exchange_provider_id uuid not null references exchange_provider(id),
  is_required boolean not null default true,
  label_en varchar(120) not null default 'Reference number',
  label_ar varchar(120) not null default 'رقم المرجع',
  validation_regex text,
  help_text_en text,
  help_text_ar text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_provider_reference_rule unique (exchange_provider_id)
);

create table if not exists exchange_provider_rate (
  id uuid primary key default gen_random_uuid(),
  exchange_provider_id uuid not null references exchange_provider(id),
  send_currency_code varchar(8) not null references currency_catalog(code),
  receive_currency_code varchar(8) not null references currency_catalog(code),
  rate numeric(18,6) not null,
  fee_type fee_type,
  fee_value numeric(18,6),
  min_amount numeric(18,2),
  max_amount numeric(18,2),
  note_en text,
  note_ar text,
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  is_active boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint uq_exchange_provider_rate unique (
    exchange_provider_id,
    send_currency_code,
    receive_currency_code,
    effective_from
  )
);

create index if not exists idx_exchange_provider_rate_lookup
  on exchange_provider_rate(exchange_provider_id, send_currency_code, is_active, effective_from desc);

create table if not exists international_receive_method (
  id uuid primary key default gen_random_uuid(),
  code varchar(64) not null unique,
  name_en varchar(120) not null,
  name_ar varchar(120) not null,
  logo_url text,
  note_en text,
  note_ar text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists exchange_receive_method (
  id uuid primary key default gen_random_uuid(),
  exchange_house_id uuid not null references exchange_house(id),
  receive_method_id uuid not null references international_receive_method(id),
  is_active boolean not null default true,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_exchange_receive_method unique (exchange_house_id, receive_method_id)
);

create index if not exists idx_exchange_receive_method_active
  on exchange_receive_method(exchange_house_id, is_active, display_order);

create table if not exists international_kyc_requirement (
  id uuid primary key default gen_random_uuid(),
  exchange_house_id uuid references exchange_house(id),
  transfer_provider_id uuid references transfer_provider(id),
  field_code varchar(64) not null,
  label_en varchar(120) not null,
  label_ar varchar(120) not null,
  field_type varchar(32) not null,
  is_required boolean not null default true,
  validation_regex text,
  allowed_mime_types jsonb,
  display_order integer not null default 0,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_international_kyc_requirement_lookup
  on international_kyc_requirement(exchange_house_id, transfer_provider_id, is_active, display_order);

create table if not exists international_transfer_quote_detail (
  quote_id uuid primary key references transfer_quote(id),
  exchange_house_id uuid not null references exchange_house(id),
  transfer_provider_id uuid not null references transfer_provider(id),
  exchange_provider_rate_id uuid not null references exchange_provider_rate(id),
  receive_method_id uuid references international_receive_method(id),
  provider_reference_required boolean not null,
  provider_reference_label_en varchar(120),
  provider_reference_label_ar varchar(120),
  exchange_snapshot jsonb not null default '{}'::jsonb,
  provider_snapshot jsonb not null default '{}'::jsonb,
  receive_method_snapshot jsonb not null default '{}'::jsonb,
  rate_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists international_transfer_order_detail (
  order_id uuid primary key references transfer_order(id),
  exchange_house_id uuid not null references exchange_house(id),
  transfer_provider_id uuid not null references transfer_provider(id),
  receive_method_id uuid references international_receive_method(id),
  provider_reference varchar(255),
  sender_full_name varchar(255) not null,
  receiver_full_name varchar(255) not null,
  destination_account_number varchar(255) not null,
  destination_account_holder varchar(255) not null,
  kyc_payload jsonb not null default '{}'::jsonb,
  exchange_snapshot jsonb not null default '{}'::jsonb,
  provider_snapshot jsonb not null default '{}'::jsonb,
  receive_method_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_international_transfer_order_provider_reference
  on international_transfer_order_detail(provider_reference);

insert into exchange_house (
  code,
  name_en,
  name_ar,
  logo_url,
  note_en,
  note_ar,
  is_active,
  display_order
) values
  (
    'mig',
    'MIG Exchange',
    'صرافة MIG',
    'https://scontent.fcai20-6.fna.fb/...',
    null,
    null,
    true,
    1
  )
on conflict (code) do nothing;

insert into transfer_provider (
  code,
  name_en,
  name_ar,
  logo_url,
  note_en,
  note_ar,
  is_active,
  display_order
) values
  (
    'wistron_transfer',
    'Wistron Transfer',
    'ويسترون ترانسفير',
    'https://play-lh.googleusercontent.com/WEI7',
    'Wistron reference number is required for all transfers.',
    'رقم مرجع ويسترون مطلوب لجميع الحوالات.',
    true,
    1
  ),
  (
    'moneygram',
    'MoneyGram',
    'موني جرام',
    'https://play-lh.googleusercontent.com/uoo6Vd...',
    'No reference number is needed for MoneyGram transfers.',
    'لا يلزم رقم مرجع لحوالات موني جرام.',
    true,
    2
  )
on conflict (code) do nothing;

insert into international_receive_method (
  code,
  name_en,
  name_ar,
  logo_url,
  note_en,
  note_ar,
  is_active
) values
  (
    'bank_transfer',
    'Bank transfer',
    'تحويل بنكي',
    'https://example.com/bank_logo.png',
    'Account number and holder name are required.',
    'رقم الحساب واسم صاحبه مطلوبان.',
    true
  ),
  (
    'mobile_wallet',
    'Mobile wallet',
    'محفظة إلكترونية',
    'https://example.com/wallet_logo.png',
    null,
    null,
    true
  )
on conflict (code) do nothing;
