-- Glowbite Supabase Schema Migration
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor → New query)

-- ============================================================
-- 1. PROFILES TABLE
-- Auto-created when a user signs up via trigger
-- ============================================================

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    avatar_url text,
    skin_type text,
    created_at timestamptz default now() not null
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Auto-create a profile row when a new user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    insert into public.profiles (id, display_name, avatar_url)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''),
        coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture', '')
    );
    return new;
end;
$$;

create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- ============================================================
-- 2. SKIN SCANS TABLE
-- ============================================================

create table if not exists public.skin_scans (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    glow_score float not null,
    metrics jsonb not null default '[]'::jsonb,
    image_url text,
    ai_insight text default '',
    overall_message text default '',
    created_at timestamptz default now() not null
);

create index if not exists idx_skin_scans_user_date
    on public.skin_scans (user_id, created_at desc);

alter table public.skin_scans enable row level security;

create policy "Users can read own skin scans"
    on public.skin_scans for select
    using (auth.uid() = user_id);

create policy "Users can insert own skin scans"
    on public.skin_scans for insert
    with check (auth.uid() = user_id);

create policy "Users can delete own skin scans"
    on public.skin_scans for delete
    using (auth.uid() = user_id);

-- ============================================================
-- 3. FOOD SCANS TABLE
-- ============================================================

create table if not exists public.food_scans (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    name text not null,
    skin_impact_score float not null,
    calories int not null default 0,
    protein float not null default 0,
    fat float not null default 0,
    carbs float not null default 0,
    fiber float not null default 0,
    sugar float not null default 0,
    sodium float not null default 0,
    benefits jsonb not null default '[]'::jsonb,
    skin_effects jsonb not null default '[]'::jsonb,
    ai_tip text,
    photo_url text,
    created_at timestamptz default now() not null
);

create index if not exists idx_food_scans_user_date
    on public.food_scans (user_id, created_at desc);

alter table public.food_scans enable row level security;

create policy "Users can read own food scans"
    on public.food_scans for select
    using (auth.uid() = user_id);

create policy "Users can insert own food scans"
    on public.food_scans for insert
    with check (auth.uid() = user_id);

create policy "Users can delete own food scans"
    on public.food_scans for delete
    using (auth.uid() = user_id);

-- ============================================================
-- 4. STORAGE BUCKETS
-- ============================================================

insert into storage.buckets (id, name, public)
values ('face-scans', 'face-scans', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('food-scans', 'food-scans', false)
on conflict (id) do nothing;

-- Storage RLS: users can upload/read files in their own user_id/ folder

create policy "Users can upload own face scan photos"
    on storage.objects for insert
    with check (
        bucket_id = 'face-scans'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can read own face scan photos"
    on storage.objects for select
    using (
        bucket_id = 'face-scans'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can delete own face scan photos"
    on storage.objects for delete
    using (
        bucket_id = 'face-scans'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can upload own food scan photos"
    on storage.objects for insert
    with check (
        bucket_id = 'food-scans'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can read own food scan photos"
    on storage.objects for select
    using (
        bucket_id = 'food-scans'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can delete own food scan photos"
    on storage.objects for delete
    using (
        bucket_id = 'food-scans'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- ============================================================
-- 5. FUNCTION: Delete all user data (for account deletion)
-- ============================================================

create or replace function public.delete_user_data()
returns void
language plpgsql
security definer
as $$
begin
    delete from public.food_scans where user_id = auth.uid();
    delete from public.skin_scans where user_id = auth.uid();
    delete from public.profiles where id = auth.uid();
end;
$$;
