-- Migration: Create task tables
-- Tables: task_lists, task_tags, task_items, task_item_tags

-- ============================================================
-- TASK LISTS
-- ============================================================

create table public.task_lists (
    id              uuid primary key,
    user_id         uuid not null references auth.users(id) on delete cascade,
    name            text not null,
    color           text not null default '#007AFF',
    icon            text not null default 'list.bullet',
    sort_order      integer not null default 0,
    is_smart_list   boolean not null default false,
    smart_list_filter jsonb,
    created_at      timestamptz not null,
    updated_at      timestamptz not null,
    deleted_at      timestamptz
);

alter table public.task_lists enable row level security;

create policy "task_lists: user owns rows"
    on public.task_lists
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index task_lists_user_id_idx on public.task_lists(user_id);
create index task_lists_updated_at_idx on public.task_lists(updated_at);

-- ============================================================
-- TASK TAGS
-- ============================================================

create table public.task_tags (
    id          uuid primary key,
    user_id     uuid not null references auth.users(id) on delete cascade,
    name        text not null,
    color       text not null default '#8E8E93',
    created_at  timestamptz not null,
    updated_at  timestamptz not null,
    deleted_at  timestamptz
);

alter table public.task_tags enable row level security;

create policy "task_tags: user owns rows"
    on public.task_tags
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index task_tags_user_id_idx on public.task_tags(user_id);

-- ============================================================
-- TASK ITEMS
-- ============================================================

create table public.task_items (
    id                  uuid primary key,
    user_id             uuid not null references auth.users(id) on delete cascade,
    list_id             uuid references public.task_lists(id) on delete set null,
    title               text not null,
    notes               text,
    due_date            timestamptz,
    has_time            boolean not null default false,
    priority            integer not null default 0,
    is_completed        boolean not null default false,
    completed_at        timestamptz,
    sort_order          integer not null default 0,
    reminder_date       timestamptz,
    location_reminder   text,
    recurrence_rule     text,
    pomodoro_estimate   integer not null default 0,
    pomodoro_actual     integer not null default 0,
    subtasks            jsonb,
    tag_ids             uuid[] not null default '{}',
    created_at          timestamptz not null,
    updated_at          timestamptz not null,
    deleted_at          timestamptz
);

alter table public.task_items enable row level security;

create policy "task_items: user owns rows"
    on public.task_items
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index task_items_user_id_idx on public.task_items(user_id);
create index task_items_list_id_idx on public.task_items(list_id);
create index task_items_updated_at_idx on public.task_items(updated_at);
create index task_items_due_date_idx on public.task_items(due_date) where deleted_at is null;
create index task_items_is_completed_idx on public.task_items(is_completed) where deleted_at is null;
