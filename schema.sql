-- =====================================================================
--  زوار المعرض – الهنا إليكتريك  (نسخة 2: مستخدمين + أدمن)
--  شغّله: Supabase → SQL Editor → New query → الصق → Run
--  آمن لو اتشغّل أكتر من مرة، ومش بيمسح أي زوار متسجلين.
--  ⚠️ قبل التشغيل: غيّر الإيميل في الخطوة 7 لإيميل حسابك انت.
-- =====================================================================

-- 1) جدول الزوار
create table if not exists public.visitors (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  name          text not null,
  company       text,
  job           text,
  phone         text not null,
  email         text,
  visitor_type  text,
  interest      text[] not null default '{}',
  project       text,
  priority      text not null default 'warm' check (priority in ('hot','warm','cold')),
  collected_by  text,
  notes         text
);
-- مين اللي سجّل (من حساب الدخول)
alter table public.visitors add column if not exists collected_by_id uuid references auth.users(id) on delete set null;

create index if not exists visitors_created_at_idx on public.visitors (created_at desc);
create index if not exists visitors_phone_idx      on public.visitors (phone);
create index if not exists visitors_by_idx         on public.visitors (collected_by_id);

-- 2) جدول الفريق: الاسم الظاهر + الصلاحية + شغال/موقوف
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text not null,
  role          text not null default 'staff' check (role in ('admin','staff')),
  active        boolean not null default true,
  created_at    timestamptz not null default now()
);

-- 3) أي مستخدم جديد (من التطبيق أو من لوحة Supabase) ياخد صف في profiles لوحده
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'display_name',''), split_part(new.email,'@',1)))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- المستخدمين اللي اتعملوا قبل كده
insert into public.profiles (id, display_name)
select id, coalesce(nullif(raw_user_meta_data->>'display_name',''), split_part(email,'@',1))
from auth.users
on conflict (id) do nothing;

-- 4) "سجّله" بيتملي من حساب الدخول تلقائيًا، ومحدش يقدر يغيّره
create or replace function public.visitors_stamp()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      new.collected_by_id := auth.uid();
      select display_name into new.collected_by from public.profiles where id = auth.uid();
    end if;
  else
    new.collected_by_id := old.collected_by_id;
    new.collected_by    := old.collected_by;
    new.created_at      := old.created_at;
  end if;
  return new;
end $$;

drop trigger if exists visitors_stamp on public.visitors;
create trigger visitors_stamp before insert or update on public.visitors
  for each row execute function public.visitors_stamp();

-- 5) دالة: هل المستخدم الحالي شغال (مش موقوف)؟
create or replace function public.is_active_member()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and active);
$$;

-- 6) الصلاحيات: المستخدم الموقوف يتقفل عليه فورًا حتى لو كان داخل
alter table public.visitors enable row level security;
alter table public.profiles enable row level security;

drop policy if exists "team can read"   on public.visitors;
drop policy if exists "team can insert" on public.visitors;
drop policy if exists "team can update" on public.visitors;
drop policy if exists "team can delete" on public.visitors;
create policy "team can read"   on public.visitors for select to authenticated using (public.is_active_member());
create policy "team can insert" on public.visitors for insert to authenticated with check (public.is_active_member());
create policy "team can update" on public.visitors for update to authenticated using (public.is_active_member()) with check (public.is_active_member());
create policy "team can delete" on public.visitors for delete to authenticated using (public.is_active_member());

-- profiles: كل واحد يقرا بياناته، والأدمن بيعدّل من خلال الـ Edge Function بس
drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select to authenticated using (id = auth.uid());

-- 7) ⚠️ خلّي حسابك أدمن: غيّر الإيميل ده لإيميل حسابك
update public.profiles set role = 'admin', active = true
where id in (select id from auth.users where email = 'admin@example.com');

-- 8) التحديث اللحظي بين الموبايلات
do $$
begin
  alter publication supabase_realtime add table public.visitors;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

-- تأكيد: لازم يطلع صف واحد على الأقل فيه role = admin
select p.display_name, u.email, p.role, p.active from public.profiles p join auth.users u on u.id = p.id order by p.created_at;
