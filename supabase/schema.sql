-- Ejecutar este script en el SQL Editor de Supabase
do $$
begin
  if to_regclass('public.productos') is not null and to_regclass('public.empresas') is null then
    alter table public.productos rename to empresas;
  end if;
end $$;

create table if not exists public.empresas (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nombre text not null,
  descripcion text,
  rubro text,
  ubicacion text,
  contacto text,
  activa boolean not null default true,
  creado_en timestamptz not null default now(),
  logo_url text,
  logo_ruta text
);

alter table public.empresas add column if not exists rubro text;
alter table public.empresas add column if not exists ubicacion text;
alter table public.empresas add column if not exists contacto text;
alter table public.empresas add column if not exists activa boolean not null default true;
alter table public.empresas add column if not exists logo_url text;
alter table public.empresas add column if not exists logo_ruta text;

do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'empresas' and column_name = 'precio') then
    alter table public.empresas alter column precio drop not null;
    alter table public.empresas alter column precio set default 0;
  end if;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'empresas' and column_name = 'stock') then
    alter table public.empresas alter column stock drop not null;
    alter table public.empresas alter column stock set default 0;
  end if;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'empresas' and column_name = 'imagen_url') then
    update public.empresas set logo_url = coalesce(logo_url, imagen_url) where imagen_url is not null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'empresas' and column_name = 'imagen_ruta') then
    update public.empresas set logo_ruta = coalesce(logo_ruta, imagen_ruta) where imagen_ruta is not null;
  end if;
end $$;

alter table public.empresas enable row level security;
grant select, insert, update, delete on table public.empresas to authenticated;

do $$
begin
  create policy "Usuarios leen sus empresas" on public.empresas for select to authenticated using ((select auth.uid()) = usuario_id);
exception when duplicate_object then null;
end $$;

do $$
begin
  create policy "Usuarios crean sus empresas" on public.empresas for insert to authenticated with check ((select auth.uid()) = usuario_id);
exception when duplicate_object then null;
end $$;

do $$
begin
  create policy "Usuarios modifican sus empresas" on public.empresas for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
exception when duplicate_object then null;
end $$;

do $$
begin
  create policy "Usuarios eliminan sus empresas" on public.empresas for delete to authenticated using ((select auth.uid()) = usuario_id);
exception when duplicate_object then null;
end $$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('empresas', 'empresas', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  create policy "Usuarios suben logos de empresas" on storage.objects for insert to authenticated with check (bucket_id = 'empresas' and (storage.foldername(name))[1] = (select auth.uid())::text);
exception when duplicate_object then null;
end $$;

do $$
begin
  create policy "Usuarios ven sus logos de empresas" on storage.objects for select to authenticated using (bucket_id = 'empresas' and owner_id = (select auth.uid())::text);
exception when duplicate_object then null;
end $$;

do $$
begin
  create policy "Usuarios eliminan sus logos de empresas" on storage.objects for delete to authenticated using (bucket_id = 'empresas' and owner_id = (select auth.uid())::text);
exception when duplicate_object then null;
end $$;

notify pgrst, 'reload schema';
