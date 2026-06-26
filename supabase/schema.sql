-- Junpo — florist accounts + their saved shop config
-- HOW TO RUN: Supabase dashboard → SQL Editor → New query → paste this → Run.
-- Safe to re-run (uses if-not-exists / drop-if-exists).

create table if not exists public.shops (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text,
  config     jsonb   not null default '{}',          -- the whole owner-mode "shop" object
  published  boolean not null default false,          -- for the future customer marketplace
  updated_at timestamptz not null default now()
);

alter table public.shops enable row level security;

-- A florist can read/write ONLY their own row:
drop policy if exists "owner full access" on public.shops;
create policy "owner full access" on public.shops
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- Anyone may READ shops marked published (lays groundwork for customers browsing shops):
drop policy if exists "public read published" on public.shops;
create policy "public read published" on public.shops
  for select using (published = true);

-- Keep updated_at fresh on every save:
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists shops_touch on public.shops;
create trigger shops_touch before update on public.shops
  for each row execute function public.touch_updated_at();


-- ============================================================
-- STORAGE: shop-images bucket (create the bucket in the dashboard first, name = shop-images)
-- ============================================================

-- Make the bucket public so customers can view shop photos:
update storage.buckets set public = true where id = 'shop-images';

-- Anyone may READ images:
drop policy if exists "shop-images read" on storage.objects;
create policy "shop-images read" on storage.objects
  for select using (bucket_id = 'shop-images');

-- A logged-in florist may upload/replace/delete files in their OWN folder (folder name = their user id):
drop policy if exists "shop-images insert" on storage.objects;
create policy "shop-images insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'shop-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "shop-images update" on storage.objects;
create policy "shop-images update" on storage.objects
  for update to authenticated
  using (bucket_id = 'shop-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "shop-images delete" on storage.objects;
create policy "shop-images delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'shop-images' and (storage.foldername(name))[1] = auth.uid()::text);


-- ============================================================
-- SIGNATURE BOUQUETS: a shop's saved arrangements (name + price + the full design)
-- ============================================================
create table if not exists public.signatures (
  id         uuid primary key default gen_random_uuid(),
  shop_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  price      numeric not null default 0,
  design     jsonb not null,                 -- the saved bouquet (wrapper, stems, colors, etc.)
  created_at timestamptz not null default now()
);
alter table public.signatures enable row level security;

-- A florist manages only their own signatures:
drop policy if exists "own signatures" on public.signatures;
create policy "own signatures" on public.signatures
  for all using (auth.uid() = shop_id) with check (auth.uid() = shop_id);

-- Customers (anonymous) may READ all signatures, for the generator / marketplace:
drop policy if exists "public read signatures" on public.signatures;
create policy "public read signatures" on public.signatures
  for select using (true);

create index if not exists signatures_shop_idx on public.signatures(shop_id);

-- optional deal / sale price (flowers to move fast). null = no deal.
alter table public.signatures add column if not exists sale_price numeric;

-- real sample photos (owner's actual arrangements) — array of public Storage URLs, max ~3
alter table public.signatures add column if not exists photos jsonb not null default '[]'::jsonb;
