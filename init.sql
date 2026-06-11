-- =====================================================================
--  CHÁ REVELAÇÃO — init.sql
--  Setup completo do banco (Supabase / PostgreSQL).
--
--  COMO USAR:
--    1. Crie um novo projeto no Supabase.
--    2. Vá em  SQL Editor  ->  New query.
--    3. Cole este arquivo inteiro e clique em  Run.
--    4. Pegue a URL e a anon/publishable key em Settings -> API
--       e coloque no config.json.
--
--  É idempotente: pode rodar de novo a qualquer momento sem quebrar nada.
-- =====================================================================


-- =====================================================================
--  1) TABELA DE VOTOS / PARTICIPANTES
-- =====================================================================
create table if not exists public.participantes (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  cargo       text not null,
  voto        text not null check (voto in ('menino', 'menina')),
  created_at  timestamptz not null default now()
);

create index if not exists idx_participantes_created_at
  on public.participantes (created_at);


-- =====================================================================
--  2) TABELA DE MENSAGENS (CHAT EM TEMPO REAL)
-- =====================================================================
create table if not exists public.mensagens (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  cargo       text,
  texto       text not null,
  created_at  timestamptz not null default now()
);

create index if not exists idx_mensagens_created_at
  on public.mensagens (created_at);


-- =====================================================================
--  3) ROW LEVEL SECURITY + POLÍTICAS (acesso público, sem login)
--     A anon/publishable key pode LER e INSERIR, mas NÃO pode
--     editar nem apagar registros.
-- =====================================================================

-- ---- participantes ----
alter table public.participantes enable row level security;

drop policy if exists "participantes_select" on public.participantes;
create policy "participantes_select"
  on public.participantes for select using (true);

drop policy if exists "participantes_insert" on public.participantes;
create policy "participantes_insert"
  on public.participantes for insert with check (true);

-- ---- mensagens ----
alter table public.mensagens enable row level security;

drop policy if exists "mensagens_select" on public.mensagens;
create policy "mensagens_select"
  on public.mensagens for select using (true);

drop policy if exists "mensagens_insert" on public.mensagens;
create policy "mensagens_insert"
  on public.mensagens for insert with check (true);


-- =====================================================================
--  4) REALTIME (atualização ao vivo de votos e chat)
--     Adiciona as tabelas à publication só se ainda não estiverem nela.
-- =====================================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'participantes'
  ) then
    alter publication supabase_realtime add table public.participantes;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'mensagens'
  ) then
    alter publication supabase_realtime add table public.mensagens;
  end if;
end $$;


-- =====================================================================
--  PRONTO! Banco configurado.
--
--  Comandos úteis para o dia a dia (rode separadamente quando precisar):
--
--    -- Limpar os votos:
--    -- truncate table public.participantes;
--
--    -- Limpar o chat:
--    -- truncate table public.mensagens;
--
--    -- Limpar tudo de uma vez:
--    -- truncate table public.participantes, public.mensagens;
-- =====================================================================