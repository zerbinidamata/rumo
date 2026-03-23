# PRD — Rumo
### Product Requirements Document · v0.1 · Março 2026
> Spec-driven. Cada seção de feature contém contexto, requisitos funcionais, critérios de aceitação e especificação técnica.

---

## Índice

1. [Visão do Produto](#1-visão-do-produto)
2. [Problema](#2-problema)
3. [Personas](#3-personas)
4. [Escopo e Não-Escopo](#4-escopo-e-não-escopo)
5. [Arquitetura de Alto Nível](#5-arquitetura-de-alto-nível)
6. [Modelos de Dados](#6-modelos-de-dados)
7. [Spec — Fundação e Auth](#7-spec--fundação-e-auth)
8. [Spec — Módulo Tarefas](#8-spec--módulo-tarefas)
9. [Spec — Módulo Hábitos](#9-spec--módulo-hábitos)
10. [Spec — Módulo Journal](#10-spec--módulo-journal)
11. [Spec — Integração Cruzada e AI](#11-spec--integração-cruzada-e-ai)
12. [Spec — iOS Native](#12-spec--ios-native)
13. [Spec — Monetização](#13-spec--monetização)
14. [Métricas de Sucesso](#14-métricas-de-sucesso)
15. [Roadmap de Versões](#15-roadmap-de-versões)
16. [Decisões Técnicas Registradas](#16-decisões-técnicas-registradas)
17. [Spec — Localização](#17-spec--localização)

---

## 1. Visão do Produto

**Rumo** é um app iOS-first que unifica gerenciamento de tarefas, rastreamento de hábitos e journaling em uma única experiência coesa — conectada por uma camada de inteligência artificial que observa os três pilares e gera insights que nenhum dos apps existentes consegue fazer isoladamente.

### Proposta de valor em uma frase

> Rumo é o único app que sabe quando seus hábitos, tarefas e emoções estão desalinhados — e te diz isso antes que você perceba.

### Referências de produto por pilar

| Pilar | Referência | O que absorvemos |
|-------|-----------|-----------------|
| Tarefas | TickTick | Captura rápida, linguagem natural, views flexíveis, Pomodoro |
| Hábitos | Grit | Gamificação, celebração, streaks, Apple Health |
| Journal | Day One + Reflect | Editor rico, prompts contextuais, privacidade E2E, busca semântica |

### Diferencial central

Os três pilares separados já existem como produtos maduros. O valor do Rumo está na **camada de conexão**: dados cruzados entre tarefas, hábitos e journal alimentam um motor de AI que gera alertas, insights e sugestões que nenhum app individual pode fazer.

---

## 2. Problema

### Fragmentação de ferramentas de produtividade pessoal

Usuários comprometidos com produtividade e bem-estar usam em média 3–5 apps diferentes para gerenciar tarefas, rastrear hábitos, e escrever no journal. Isso cria três problemas concretos:

**Fricção de contexto.** Alternar entre apps quebra o fluxo. Completar um hábito no Grit, registrar no Day One o que aconteceu, e criar a tarefa relacionada no TickTick são três ações em três apps diferentes.

**Dados em silos.** Nenhum app sabe o que está acontecendo nos outros. O Day One não sabe que você falhou no hábito de meditação. O TickTick não sabe que você está se sentindo sobrecarregado. O Grit não sabe que você tem cinco tarefas em atraso.

**Insights impossíveis.** A correlação mais valiosa — "seus hábitos caem quando você tem muitas tarefas em atraso" ou "você escreve sobre ansiedade nos dias que não medita" — simplesmente não existe em nenhum app isolado.

### Hipótese central

Usuários que usam os três pilares (tarefas + hábitos + journal) de forma consistente têm resultados significativamente melhores em produtividade e bem-estar do que usuários que usam apenas um ou dois. A barreira é a fricção de manter três ferramentas separadas.

---

## 3. Personas

### Persona A — Rafael, 28 anos, fundador de startup

Rafael gerencia um produto em desenvolvimento enquanto cuida da própria saúde física e mental. Usa TickTick para tarefas, tentou Grit mas abandonou, e escreve no journal só quando se sente muito bem ou muito mal. O problema dele é consistência — não falta de intenção, falta de sistema integrado. Ele quer ver o impacto dos seus hábitos na sua produtividade, mas não quer gastar tempo correlacionando dados manualmente.

**Necessidade principal:** visualizar que hábitos têm mais impacto no seu dia de trabalho.
**Comportamento esperado:** abre o app de manhã para planejar o dia e à noite para fechar o loop.

### Persona B — Mariana, 32 anos, designer freelance

Mariana tem muitos projetos simultâneos e lida com picos de ansiedade. Ela já usa journaling como ferramenta terapêutica mas não consegue conectar seus escritos com comportamentos concretos. Quer ter um espaço que conecte o que sente com o que faz.

**Necessidade principal:** entender padrões emocionais e como hábitos os afetam.
**Comportamento esperado:** usa o journal como ponto de entrada principal; quer que o app "leia" o que escreveu e sugira ações.

### Persona C — Pedro, 22 anos, estudante universitário

Pedro está construindo rotinas pela primeira vez. Não tem histórico com apps de produtividade mas está motivado a mudar comportamentos. Precisa de gamificação e de celebrações para manter engajamento inicial.

**Necessidade principal:** construir hábitos com consistência e sentir progresso visível.
**Comportamento esperado:** entra várias vezes por dia para marcar hábitos; responde bem a conquistas e streaks.

---

## 4. Escopo e Não-Escopo

### v1.0 — Em escopo

- Módulo de Tarefas com captura rápida, listas, prioridades, lembretes, recorrência e Pomodoro
- Módulo de Hábitos com rastreamento, streaks, gamificação (confete, achievements) e Apple Health
- Módulo de Journal com editor rico, mood tracking, prompts contextuais e criptografia E2E
- Dashboard unificado com resumo dos três pilares
- Motor de correlação cruzada com alertas on-device (15+ regras)
- Widgets WidgetKit (small, medium, large, lock screen, interativo)
- Apple Watch app básico (hábitos + complication)
- Sign in with Apple + magic link
- Sync local-first com Supabase
- Monetização via StoreKit 2 (mensal, anual, lifetime)

### v1.5 — Planejado

- Apple Intelligence (Foundation Models) para análise de sentimento on-device
- Revisão semanal automática via GPT-4o Mini
- Busca semântica no journal via embeddings (pgvector)
- Compartilhamento social de hábitos e desafios com amigos

### v2.0 — Futuro

- Chat contextual com o app ("como estou indo?")
- Análise de longo prazo e predição de burnout
- Android (somente após produto validado no iOS)
- Integrações externas (Zapier, Siri Shortcuts avançados)

### Fora de escopo (nunca ou indefinido)

- App web ou desktop (iOS-first, mobile-only na v1.0)
- Colaboração de tarefas em equipe (é um app pessoal)
- Integração com calendário externo (Google Calendar, Outlook) na v1.0
- Importação de dados de outros apps na v1.0

---

## 5. Arquitetura de Alto Nível

### Stack técnica

| Camada | Tecnologia | Justificativa |
|--------|-----------|--------------|
| Linguagem | Swift 6 (strict concurrency) | Performance nativa, acesso total às APIs Apple |
| UI | SwiftUI + UIKit pontual | SwiftUI para velocidade; UIKit onde SwiftUI tem limitações |
| Arquitetura | MVVM + Coordinator | Testável, previsível, familiar para devs iOS |
| Persistência local | SwiftData (iOS 17+) | Cache offline-first, compartilhado com Widget Extension |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) | BaaS completo, SDK iOS oficial, PostgreSQL relacional |
| Sync | Local-first → Supabase Realtime | Salva local imediatamente, sincroniza em background |
| AI on-device | Apple Intelligence / NaturalLanguage.framework | Privacidade total, zero custo por chamada |
| AI cloud | OpenAI GPT-4o Mini + text-embedding-3-small | Análises profundas, revisão semanal, busca semântica |
| AI gateway | Supabase Edge Function (Deno) | API key nunca exposta no cliente; rate limiting centralizado |
| Monetização | StoreKit 2 | API moderna, suporte a subscriptions e lifetime |
| Monitoramento | Sentry + TelemetryDeck | Crash reports + analytics privado (sem dados pessoais) |
| CI/CD | Xcode Cloud + Fastlane | Build automático, TestFlight, screenshots da App Store |

### Diagrama de fluxo de dados

```
iPhone (Swift)
├── SwiftData (local-first, cache)
│   ├── TaskItem, TaskList, TaskTag
│   ├── Habit, HabitLog, Achievement
│   └── JournalEntry, JournalPrompt
│
├── Apple Intelligence / NaturalLanguage (on-device)
│   ├── Análise de sentimento do journal
│   ├── Extração de tópicos e intenções
│   └── CorrelationEngine (15+ regras, zero latência)
│
└── Supabase (cloud, sync em background)
    ├── Auth (Sign in with Apple, magic link)
    ├── PostgreSQL (espelho do SwiftData)
    ├── Storage (fotos do journal, áudios)
    ├── Realtime (sync entre dispositivos)
    └── Edge Functions
        └── OpenAI (revisão semanal, embeddings, chat)
```

### Princípio de privacidade

O texto bruto do journal **nunca sai do dispositivo** para servidores de terceiros. A cloud recebe apenas metadados estruturados e anonimizados: scores numéricos, enums de mood, percentuais de hábitos. Embeddings são vetores matematicamente irreversíveis.

---

## 6. Modelos de Dados

### 6.1 Domínio de Tarefas

```swift
@Model final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?                    // Markdown
    var dueDate: Date?
    var dueTime: Date?
    var priority: TaskPriority            // none | low | medium | high
    var listId: UUID?
    var tags: [UUID]
    var parentId: UUID?                   // nil = tarefa raiz; UUID = subtarefa
    var recurrence: RecurrenceRule?
    var completedAt: Date?
    var pomodoroEstimate: Int             // número de pomos estimados
    var pomodoroActual: Int              // número de pomos realizados
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
}

@Model final class TaskList {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String                     // hex
    var icon: String                      // SF Symbol name
    var sortOrder: Int
    var isSmartList: Bool
    var smartListFilter: SmartListFilter? // se isSmartList == true
    var createdAt: Date
}

enum TaskPriority: Int, Codable { case none, low, medium, high }

struct RecurrenceRule: Codable {
    var frequency: Frequency              // daily | weekly | monthly | custom
    var interval: Int                     // a cada N dias/semanas/meses
    var daysOfWeek: [Int]?               // 0=dom, 1=seg... para weekly custom
    var endsAt: Date?
}
```

### 6.2 Domínio de Hábitos

```swift
@Model final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var color: String                     // hex
    var type: HabitType                   // good | bad
    var goalValue: Double                 // ex: 8 (copos de água)
    var goalUnit: String                  // ex: "copos", "minutos", "km"
    var frequency: HabitFrequency         // dias da semana ou mês
    var reminderTime: Date?
    var categoryId: UUID?
    var archivedAt: Date?
    var createdAt: Date
    var updatedAt: Date
}

@Model final class HabitLog {
    @Attribute(.unique) var id: UUID
    var habitId: UUID
    var date: Date                        // apenas a data, sem hora
    var value: Double                     // valor registrado (ex: 6 de 8 copos)
    var status: HabitStatus               // completed | failed | skipped
    var note: String?
    var createdAt: Date
}

@Model final class Achievement {
    @Attribute(.unique) var id: UUID
    var type: AchievementType
    var habitId: UUID?                    // nil = achievement global/cross-pilar
    var unlockedAt: Date
    var seenAt: Date?
}

enum HabitType: String, Codable { case good, bad }
enum HabitStatus: String, Codable { case completed, failed, skipped }
```

### 6.3 Domínio de Journal

```swift
@Model final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var bodyEncrypted: Data               // AES-256 GCM, chave no Keychain
    var bodyHash: String                  // SHA-256 para detectar mudanças
    var mood: MoodLevel?
    var photoIds: [String]               // IDs no Supabase Storage
    var audioUrl: String?
    var locationLat: Double?
    var locationLon: Double?
    var tags: [String]
    var promptId: UUID?
    var wordCount: Int
    var sentimentScore: Float?           // gerado on-device, -1.0 a +1.0
    var topics: [String]                 // gerado on-device, ex: ["ansiedade"]
    var embedding: [Float]?             // 1536-dim, gerado via OpenAI
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
}

@Model final class JournalPrompt {
    @Attribute(.unique) var id: UUID
    var text: String
    var category: PromptCategory         // gratitude | reflection | planning | celebration | hard
    var contextTrigger: PromptTrigger?   // nil = prompt genérico
}

enum MoodLevel: Int, Codable {
    case awful = 1, bad, neutral, good, great
}

enum PromptCategory: String, Codable {
    case gratitude, reflection, planning, celebration, hard
}
```

### 6.4 Schema Supabase (SQL)

```sql
-- Todas as tabelas espelham os modelos Swift com adição de user_id
-- RLS (Row Level Security) ativado em todas as tabelas

CREATE TABLE task_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users NOT NULL,
    title       TEXT NOT NULL,
    notes       TEXT,
    due_date    DATE,
    due_time    TIMESTAMPTZ,
    priority    SMALLINT DEFAULT 0,
    list_id     UUID,
    tags        UUID[] DEFAULT '{}',
    parent_id   UUID REFERENCES task_items(id),
    recurrence  JSONB,
    completed_at TIMESTAMPTZ,
    pomo_estimate SMALLINT DEFAULT 0,
    pomo_actual   SMALLINT DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now(),
    deleted_at  TIMESTAMPTZ  -- soft delete
);

CREATE TABLE habits (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID REFERENCES auth.users NOT NULL,
    name         TEXT NOT NULL,
    emoji        TEXT NOT NULL,
    color        TEXT NOT NULL,
    type         TEXT NOT NULL CHECK (type IN ('good','bad')),
    goal_value   NUMERIC DEFAULT 1,
    goal_unit    TEXT DEFAULT 'vez',
    frequency    JSONB NOT NULL,
    reminder_time TIME,
    category_id  UUID,
    archived_at  TIMESTAMPTZ,
    created_at   TIMESTAMPTZ DEFAULT now(),
    updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE habit_logs (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES auth.users NOT NULL,
    habit_id   UUID REFERENCES habits(id) NOT NULL,
    date       DATE NOT NULL,
    value      NUMERIC DEFAULT 1,
    status     TEXT NOT NULL CHECK (status IN ('completed','failed','skipped')),
    note       TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(habit_id, date)  -- apenas um log por hábito por dia
);

CREATE TABLE journal_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES auth.users NOT NULL,
    date            DATE NOT NULL,
    body_encrypted  BYTEA NOT NULL,   -- AES-256 GCM, Supabase não lê o conteúdo
    body_hash       TEXT NOT NULL,
    mood            SMALLINT,
    photo_ids       TEXT[] DEFAULT '{}',
    audio_url       TEXT,
    tags            TEXT[] DEFAULT '{}',
    prompt_id       UUID,
    word_count      INT DEFAULT 0,
    sentiment_score REAL,             -- gerado on-device
    topics          TEXT[] DEFAULT '{}', -- gerado on-device
    embedding       vector(1536),     -- pgvector, gerado via OpenAI
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, date)  -- uma entrada por dia
);

-- pgvector para busca semântica
CREATE EXTENSION IF NOT EXISTS vector;
CREATE INDEX journal_embedding_idx
    ON journal_entries USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- Row Level Security
ALTER TABLE task_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

-- Políticas: usuário só acessa seus próprios dados
CREATE POLICY "own data" ON task_items
    FOR ALL USING (auth.uid() = user_id);
-- (idem para as demais tabelas)
```

---

## 7. Spec — Fundação e Auth

### 7.1 Autenticação

**Contexto:** O Rumo é um app pessoal com dados sensíveis (journal com criptografia). A autenticação deve ser simples, segura e obrigatória. Sign in with Apple é exigido pela Apple sempre que o app oferece outro método de login social (App Store Guideline 4.8).

**Requisitos funcionais:**

- RF-AUTH-01: O usuário pode criar conta e fazer login com Sign in with Apple
- RF-AUTH-02: O usuário pode criar conta e fazer login com email (magic link sem senha)
- RF-AUTH-03: A sessão persiste entre aberturas do app (token armazenado no Keychain)
- RF-AUTH-04: O usuário pode fazer logout; dados locais são preservados mas desassociados da conta
- RF-AUTH-05: O usuário pode deletar a conta; todos os dados no Supabase são apagados em cascata
- RF-AUTH-06: O app funciona offline com dados locais mesmo sem sessão ativa (dados criados offline sincronizam ao reconectar)

**Critérios de aceitação:**

- [ ] Login com Apple retorna em menos de 3 segundos em boa conexão
- [ ] Magic link é entregue em menos de 30 segundos
- [ ] Após logout, nenhum dado do usuário anterior é visível
- [ ] Após deleção de conta, os dados somem do Supabase em até 24h (cascata assíncrona)
- [ ] App abre e é totalmente utilizável sem internet (dados locais disponíveis)

**Spec técnica:**

```swift
protocol AuthRepository {
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User
    func signInWithMagicLink(email: String) async throws
    func signOut() async throws
    func deleteAccount() async throws
    var currentUser: User? { get }
    var authStateStream: AsyncStream<AuthState> { get }
}
```

---

### 7.2 Sync Local-First

**Contexto:** O Rumo usa SwiftData como fonte de verdade local. O Supabase é o espelho remoto. O usuário nunca espera a rede para ver ou criar dados — a UI reflete sempre o estado local imediatamente.

**Requisitos funcionais:**

- RF-SYNC-01: Toda operação de escrita salva em SwiftData primeiro e retorna imediatamente para a UI
- RF-SYNC-02: O `SyncManager` observa mudanças no SwiftData e sincroniza com Supabase em background
- RF-SYNC-03: Operações criadas offline são enfileiradas e sincronizadas ao reconectar
- RF-SYNC-04: Conflitos são resolvidos por last-write-wins baseado em `updatedAt`
- RF-SYNC-05: O Supabase Realtime sincroniza mudanças entre dois dispositivos do mesmo usuário em tempo real

**Critérios de aceitação:**

- [ ] Criar uma tarefa offline e depois conectar → tarefa aparece no Supabase em até 5 segundos
- [ ] Editar a mesma tarefa em dois dispositivos simultaneamente → versão mais recente prevalece, sem crash
- [ ] Remover e reinstalar o app → dados do Supabase são restaurados no primeiro sync pós-login
- [ ] Com 500 itens locais, o sync inicial não bloqueia a UI (roda em background)

---

### 7.3 Criptografia do Journal

**Contexto:** O journal contém dados altamente sensíveis. A criptografia deve ser client-side antes do upload — o Supabase armazena apenas cyphertext ilegível.

**Requisitos funcionais:**

- RF-CRYPTO-01: O corpo de cada entrada de journal é criptografado com AES-256 GCM antes de ser salvo no Supabase
- RF-CRYPTO-02: A chave de criptografia é gerada por usuário, armazenada exclusivamente no Keychain do dispositivo
- RF-CRYPTO-03: Dados de metadados não-sensíveis (mood, wordCount, sentimentScore, topics) são armazenados em plaintext para viabilizar análise AI sem decriptar
- RF-CRYPTO-04: O usuário pode exportar todas as entradas em Markdown descriptografado
- RF-CRYPTO-05: O usuário pode optar por journal somente local (sem sync para cloud)

**Critérios de aceitação:**

- [ ] O campo `body_encrypted` no Supabase nunca contém texto legível
- [ ] Descriptografar no dispositivo e re-criptografar produz o mesmo cyphertext (chave estável no Keychain)
- [ ] Export em Markdown contém o texto original íntegro
- [ ] Resetar o Keychain (restaurar iPhone sem backup) torna as entradas antigas ilegíveis — comportamento esperado e documentado

---

## 8. Spec — Módulo Tarefas

### 8.1 Captura Rápida

**Contexto:** A feature mais usada do app. Referência: TickTick Quick Add. O objetivo é zero fricção — do pensamento à tarefa em menos de 3 toques.

**Requisitos funcionais:**

- RF-TASK-01: Um `QuickAddBar` fixo na parte inferior de qualquer tela do módulo de tarefas
- RF-TASK-02: O campo de texto aceita linguagem natural e faz parse automático de data, hora e recorrência
- RF-TASK-03: O parser de linguagem natural suporta: "amanhã", "hoje", "semana que vem", "às 15h", "toda segunda", "todo dia", "próxima sexta"
- RF-TASK-04: Datas detectadas pelo parser são exibidas como chip colorido antes de confirmar
- RF-TASK-05: Ao confirmar, a tarefa é salva localmente e aparece na lista imediatamente

**Critérios de aceitação:**

- [ ] "Reunião com cliente amanhã às 14h" → `dueDate = amanhã`, `dueTime = 14:00`
- [ ] "Pagar conta toda sexta" → `recurrence = weekly, dayOfWeek = 6`
- [ ] "Comprar pão" (sem data) → `dueDate = nil`, cai em "Sem data"
- [ ] Tarefa aparece na lista em menos de 200ms após confirmar (local-first)
- [ ] Parser funciona offline, sem chamada à rede

**Spec técnica — NLDateParser:**

```swift
struct NLDateParser {
    // Usa NaturalLanguage.framework + DateFormatter + regex customizado
    func parse(_ text: String) -> (cleanTitle: String, date: Date?, time: Date?, recurrence: RecurrenceRule?)

    // Exemplos de tokens reconhecidos:
    // Relativo: hoje, amanhã, depois de amanhã, semana que vem, mês que vem
    // Absoluto: "dia 15", "15/04", "15 de abril"
    // Hora: "às 14h", "às 14:30", "2pm"
    // Recorrência: "todo dia", "toda semana", "toda segunda", "todo mês"
}
```

---

### 8.2 Views de Tarefas

**Requisitos funcionais:**

- RF-TASK-06: View "Hoje" mostra tarefas com dueDate = hoje + tarefas em atraso (overdue)
- RF-TASK-07: View "Listas" agrupa tarefas por lista com contagem de itens pendentes
- RF-TASK-08: View "Calendário" exibe um grid mensal; dias com tarefas têm indicador visual; tap no dia filtra as tarefas
- RF-TASK-09: View "Kanban" exibe colunas por status (A fazer / Em progresso / Concluído) com scroll horizontal
- RF-TASK-10: View "Eisenhower" divide tarefas em quatro quadrantes (urgente+importante, importante, urgente, nenhum)
- RF-TASK-11: A view padrão é configurável pelo usuário nas preferências

**Critérios de aceitação:**

- [ ] Overdue na view Hoje é visualmente distinto (cor de destaque ou ícone de alerta)
- [ ] Arrastar tarefa entre colunas no Kanban atualiza seu status imediatamente
- [ ] No Eisenhower, tarefas sem prioridade ficam no quadrante inferior-direito

---

### 8.3 Detalhe da Tarefa

**Requisitos funcionais:**

- RF-TASK-12: A tela de detalhe exibe e permite editar: título, notas (Markdown), lista, tags, prioridade, data, hora, recorrência, lembrete(s), estimativa de Pomodoros
- RF-TASK-13: Notas suportam Markdown com preview inline (bold, italic, heading, lista, código, link)
- RF-TASK-14: Subtarefas podem ser adicionadas, completadas e reordenadas por drag & drop dentro do detalhe
- RF-TASK-15: O campo de detalhe exibe o histórico de Pomodoros realizados para aquela tarefa

**Critérios de aceitação:**

- [ ] Markdown é renderizado inline durante a digitação (sem toggle de preview)
- [ ] Criar subtarefa e completá-la não marca a tarefa pai como completa
- [ ] Deletar tarefa pai com subtarefas exibe confirmação listando o número de subtarefas afetadas

---

### 8.4 Lembretes e Recorrência

**Requisitos funcionais:**

- RF-TASK-16: Cada tarefa suporta até 5 lembretes independentes (ex: -1 dia, -1 hora, na hora)
- RF-TASK-17: Lembretes por localização usam `CLRegionMonitoring` e disparam ao chegar/sair de um local
- RF-TASK-18: "Lembrete persistente" re-notifica a cada 30 minutos até o usuário marcar a tarefa como completa
- RF-TASK-19: Notificações incluem ações interativas: **Concluir** e **Adiar 1h**
- RF-TASK-20: Tarefas recorrentes são recriadas automaticamente após conclusão com a próxima data calculada

**Critérios de aceitação:**

- [ ] Ação "Concluir" na notificação marca a tarefa sem abrir o app
- [ ] Ação "Adiar 1h" cria um novo lembrete exatamente 1h depois e cancela o anterior
- [ ] Lembrete por localização dispara em até 30 segundos de entrar na região definida

---

### 8.5 Pomodoro Timer

**Requisitos funcionais:**

- RF-TASK-21: O timer Pomodoro pode ser iniciado a partir de qualquer tarefa
- RF-TASK-22: O timer exibe uma Live Activity na Dynamic Island e Lock Screen enquanto está ativo
- RF-TASK-23: Ao final de cada sessão, um haptic e som notificam o usuário
- RF-TASK-24: O tempo de cada sessão é registrado na tarefa e acumulado no histórico

**Critérios de aceitação:**

- [ ] Timer continua rodando com o app em background
- [ ] Live Activity mostra o tempo restante atualizado a cada segundo
- [ ] Sessão interrompida antes do fim é contabilizada proporcionalmente (ex: 20min de 25min = 0.8 pomo)

---

## 9. Spec — Módulo Hábitos

### 9.1 Rastreamento Diário

**Contexto:** O ponto de entrada mais frequente do app. Deve ser rápido e satisfatório. Referência: Grit.

**Requisitos funcionais:**

- RF-HAB-01: A tela principal exibe todos os hábitos do dia com indicador de progresso por hábito
- RF-HAB-02: Tap em um hábito binário (sim/não) o completa com animação de check + confete
- RF-HAB-03: Tap em um hábito quantitativo (ex: 8 copos de água) abre um stepper rápido na própria célula
- RF-HAB-04: Long press em um hábito exibe opções: marcar como falhado, adicionar nota, pular
- RF-HAB-05: Hábitos são organizados por categoria com collapse/expand por grupo

**Critérios de aceitação:**

- [ ] Completar um hábito do tap até o fim da animação leva menos de 1 segundo
- [ ] Confete usa `CAEmitterLayer` (nativo) e respeita "Reduce Motion" das acessibilidades
- [ ] Hábito marcado como falhado exibe ícone distinto (X em vermelho) e aceita nota opcional

---

### 9.2 Gamificação

**Contexto:** A gamificação é o principal driver de retenção no módulo de hábitos. Deve ser celebratória, não punitiva.

**Requisitos funcionais:**

- RF-HAB-06: O sistema de streaks calcula automaticamente dias consecutivos com base nos `HabitLog`
- RF-HAB-07: Streaks podem ser desativados por hábito para usuários que preferem sem pressão
- RF-HAB-08: Achievements são desbloqueados automaticamente ao atingir critérios; uma notificação in-app celebra o desbloqueio
- RF-HAB-09: XP global acumula a cada ação (completar hábito, criar journal, concluir tarefa prioritária) e determina o nível do usuário
- RF-HAB-10: A tela de achievements exibe progresso parcial de conquistas ainda não desbloqueadas (ex: "7/30 dias de streak")

**Lista de achievements v1.0:**

| ID | Nome | Critério | Pilar |
|----|------|----------|-------|
| ACH-01 | Primeiro Passo | Criar primeiro hábito | Hábitos |
| ACH-02 | Semana Perfeita | 7 dias de streak em qualquer hábito | Hábitos |
| ACH-03 | Mês Invicto | 30 dias de streak em qualquer hábito | Hábitos |
| ACH-04 | Centenário | 100 dias de streak em qualquer hábito | Hábitos |
| ACH-05 | Dia Perfeito | Todos os hábitos do dia completos | Hábitos |
| ACH-06 | 10 Dias Perfeitos | 10 Perfect Days acumulados | Hábitos |
| ACH-07 | Madrugador | Hábito completo antes das 8h | Hábitos |
| ACH-08 | Honesto | Marcar hábito como falhado com nota | Hábitos |
| ACH-09 | Escritor | 10 entradas de journal criadas | Journal |
| ACH-10 | Reflexivo | 30 entradas de journal criadas | Journal |
| ACH-11 | Foco Total | 5 sessões Pomodoro concluídas | Tarefas |
| ACH-12 | Dia Triplo | Hábitos + tarefa prioritária + journal no mesmo dia | Cross-pilar |
| ACH-13 | Semana Integrada | Dia Triplo por 7 dias consecutivos | Cross-pilar |

**Critérios de aceitação:**

- [ ] Achievement é desbloqueado em tempo real, no momento em que o critério é atingido
- [ ] Modal de achievement inclui: ícone animado, nome, descrição, XP ganho
- [ ] Nível do usuário (1–50) é visível no perfil e evolui com XP acumulado

---

### 9.3 Analytics de Hábitos

**Requisitos funcionais:**

- RF-HAB-11: Tela de estatísticas exibe taxa de conclusão por hábito (% dos dias no período)
- RF-HAB-12: Heatmap de 90 dias para cada hábito (estilo GitHub contributions) usando Swift Charts
- RF-HAB-13: Gráfico de barras semanal comparando semana atual vs. semana anterior
- RF-HAB-14: Indicador do melhor streak histórico e streak atual

**Critérios de aceitação:**

- [ ] Todos os gráficos usam Swift Charts (nativo, iOS 16+)
- [ ] Período selecionável: 7 dias, 30 dias, 90 dias, tudo
- [ ] Heatmap é color-coded: cinza = sem dados, gradiente de cor do hábito = intensidade

---

### 9.4 Compartilhamento Social

**Requisitos funcionais:**

- RF-HAB-15: O usuário pode tornar hábitos específicos públicos no seu perfil
- RF-HAB-16: O usuário pode gerar uma imagem compartilhável do streak de um hábito
- RF-HAB-17: O usuário pode adicionar amigos por username ou link de convite
- RF-HAB-18: O feed de amigos exibe hábitos completados e achievements desbloqueados
- RF-HAB-19: O usuário pode criar um desafio: convidar um amigo para manter um hábito por N dias juntos
- RF-HAB-20: Desafios exibem um ranking de streak entre os participantes

**Critérios de aceitação:**

- [ ] Imagem compartilhável é gerada com `UIGraphicsImageRenderer` com branding do Rumo
- [ ] Link de convite de amigo expira em 7 dias
- [ ] Notificação push quando amigo completa hábito de desafio compartilhado

---

## 10. Spec — Módulo Journal

### 10.1 Editor de Entradas

**Contexto:** O editor é o coração do módulo de journal. Deve ser sem fricção — o usuário não deve pensar em "salvar". Referência: Day One.

**Requisitos funcionais:**

- RF-JOU-01: O editor usa `TextEditor` com toolbar de formatação customizada (bold, italic, heading, lista, quote, link)
- RF-JOU-02: A entrada é auto-salva a cada 10 segundos de inatividade e ao sair da tela (sem botão "Salvar")
- RF-JOU-03: O usuário pode inserir fotos da biblioteca ou câmera; fotos são comprimidas automaticamente antes do upload
- RF-JOU-04: O usuário pode gravar áudio; o `Speech.framework` transcreve automaticamente o áudio para texto (opt-in)
- RF-JOU-05: O seletor de mood aparece no topo da entrada com 5 níveis e ícones animados
- RF-JOU-06: Contagem de palavras é exibida em tempo real no rodapé do editor
- RF-JOU-07: Apple Pencil é suportado via PencilKit para anotações desenhadas (inline com o texto)

**Critérios de aceitação:**

- [ ] Auto-save nunca bloqueia a UI (opera em background actor)
- [ ] Fotos acima de 2MB são comprimidas para no máximo 1MB antes do upload
- [ ] Sair do editor com texto não salvo não perde dados (save imediato ao sair)
- [ ] Transcrição de áudio começa em menos de 2 segundos após parar a gravação

---

### 10.2 Prompts Contextuais

**Contexto:** O maior bloqueio do journaling é "o que escrever". Prompts contextuais resolvem isso usando dados dos outros dois pilares. Este é o principal diferencial do módulo de journal.

**Requisitos funcionais:**

- RF-JOU-08: Ao abrir o journal do dia, o app sugere 1–3 prompts baseados no contexto do dia
- RF-JOU-09: O usuário pode deslizar horizontalmente para ver prompts alternativos
- RF-JOU-10: O usuário pode descartar todos os prompts e começar em branco

**Lógica de seleção de prompts (v1.0 — on-device):**

| Condição detectada | Categoria de prompt | Exemplo |
|-------------------|--------------------|----|
| Todos os hábitos do dia completos | celebration | "Você foi consistente hoje. O que tornou isso possível?" |
| Hábito falhado hoje | reflection | "Algo atrapalhou um hábito hoje. O que você aprendeu sobre si mesmo?" |
| Tarefa de alta prioridade concluída | celebration | "Você completou algo importante. Como você se sente sobre isso?" |
| Mood selecionado = bad ou awful | hard | "Parece que foi um dia difícil. O que pesou mais?" |
| É segunda-feira | planning | "Nova semana. O que você quer proteger nessa semana?" |
| É domingo | reflection | "Fim de semana. O que foi bem? O que você mudaria?" |
| 5+ tarefas em atraso | reflection | "Você tem várias coisas pendentes. O que está tornando difícil avançar?" |
| Streak de hábito > 30 dias | celebration | "Você está em um streak incrível. O que mudou desde que começou?" |
| Nenhuma condição específica | gratitude | "Três coisas pelas quais você é grato hoje." |

**Critérios de aceitação:**

- [ ] Seleção de prompt leva menos de 100ms (lógica local, sem rede)
- [ ] Nunca exibe o mesmo prompt por dois dias consecutivos
- [ ] Ao selecionar um prompt, o texto do prompt aparece no editor como placeholder (desaparece ao digitar)

---

### 10.3 Organização e Busca

**Requisitos funcionais:**

- RF-JOU-11: A tela principal exibe entradas em ordem cronológica reversa com preview de 2 linhas
- RF-JOU-12: Calendar View exibe um grid mensal; dias com entrada têm indicador visual + cor do mood
- RF-JOU-13: "On This Day" exibe entradas do mesmo dia em anos anteriores quando disponíveis
- RF-JOU-14: Busca por texto completo funciona sobre títulos e corpo descriptografado localmente
- RF-JOU-15: Filtros disponíveis: por mood, por tag, por período
- RF-JOU-16: (v1.5) Busca semântica via embeddings: "quando me senti sobrecarregado?" retorna entradas relevantes mesmo sem essa palavra exata

**Critérios de aceitação:**

- [ ] Busca local retorna resultados em menos de 300ms com 365 entradas
- [ ] "On This Day" só aparece se houver pelo menos 1 entrada de ano anterior
- [ ] Calendar View indica visualmente dias sem entrada (cinza) vs. com entrada (cor do mood)

---

### 10.4 Privacidade

**Requisitos funcionais:**

- RF-JOU-17: O módulo de journal pode ser protegido por Face ID / Touch ID (opt-in nas configurações)
- RF-JOU-18: Se habilitado, o app pede autenticação biométrica sempre que o módulo de journal é acessado após o app ir para background
- RF-JOU-19: O usuário pode exportar todas as entradas em Markdown + JSON
- RF-JOU-20: O usuário pode optar por "modo local" — journal nunca sincroniza para o Supabase

**Critérios de aceitação:**

- [ ] Com biometria ativada, o journal é inacessível se a autenticação falhar 3 vezes consecutivas
- [ ] Export ZIP contém uma pasta com um arquivo `.md` por entrada + metadata `.json`
- [ ] Em modo local, nenhuma chamada de rede é feita para as entradas de journal

---

## 11. Spec — Integração Cruzada e AI

### 11.1 Dashboard Unificado

**Contexto:** A Home é o único lugar do app que vê os três pilares simultaneamente. É a tela de abertura padrão.

**Requisitos funcionais:**

- RF-INT-01: A Home exibe: saudação com hora do dia, score do dia (0–100), progresso de hábitos (X/Y), próxima tarefa com deadline, streak de journal, e último achievement desbloqueado
- RF-INT-02: O "Foco do Dia" destaca automaticamente a tarefa mais urgente ou o hábito com streak mais longo em risco
- RF-INT-03: O score diário (0–100) é calculado com base em: hábitos concluídos (40%), tarefas concluídas (30%) e entrada de journal (30%)

**Critérios de aceitação:**

- [ ] Score do dia atualiza em tempo real conforme o usuário completa itens
- [ ] Home carrega em menos de 200ms (todos os dados vêm do SwiftData local)

---

### 11.2 Motor de Correlação Cruzada (CorrelationEngine)

**Contexto:** Este é o módulo de AI on-device. Analisa o `DailySnapshot` e dispara alertas contextuais sem nenhuma chamada à rede.

**Spec técnica:**

```swift
// Roda em background actor, zero impacto na UI
actor CorrelationEngine {

    // Chamado ao: abrir o app, completar um hábito, salvar journal, completar tarefa
    func analyze(snapshot: DailySnapshot) async -> [Insight]
}

struct DailySnapshot {
    let date: Date
    let habitLogs: [HabitLog]
    let completedTaskCount: Int
    let overdueTaskCount: Int
    let journalEntry: JournalEntry?      // nil se ainda não escreveu hoje
    let sentimentScore: Float?           // -1.0 a +1.0, on-device
    let detectedTopics: [String]         // on-device
    let mood: MoodLevel?
    let activeStreaks: [UUID: Int]        // habitId → dias de streak
}

struct Insight {
    let id: UUID
    let type: InsightType
    let title: String
    let body: String
    let action: InsightAction?           // ação sugerida ao aceitar
    let priority: InsightPriority        // low | medium | high
    let pilarsInvolved: [Pilar]          // quais pilares geraram o insight
}
```

**Regras implementadas em v1.0:**

| Regra | Condição | Insight gerado |
|-------|----------|----------------|
| COR-01 | Hábito de meditação falhado + topics contém "ansiedade" ou "estresse" | "Você mencionou ansiedade hoje. Meditação pode ajudar — quer marcar agora?" |
| COR-02 | Hábito de exercício falhado 3+ dias + mood ≤ bad | "Exercício impacta diretamente o humor. Você não se exercitou essa semana." |
| COR-03 | Hábito de sono não registrado + topics contém "cansaço" ou "exausto" | "Você escreveu sobre cansaço. Seu hábito de sono não foi registrado." |
| COR-04 | Todos os hábitos completos + sem journal hoje | "Você foi consistente hoje! Quer registrar isso no journal?" |
| COR-05 | 5+ tarefas em atraso + taxa de hábitos < 40% na semana | "Semana sobrecarregada detectada. Que tal revisar suas prioridades?" |
| COR-06 | Tarefa de alta prioridade concluída + streak ativo | Achievement: "Dia Triplo" se journal também foi feito |
| COR-07 | mood = awful + 5+ tarefas em atraso | "Parece um dia difícil. Quer adiar algumas tarefas para amanhã?" |
| COR-08 | Journal menciona intenção ("preciso", "quero", "vou") + nenhuma tarefa criada | "Você mencionou algo que quer fazer. Quer transformar em tarefa?" |
| COR-09 | Nenhuma interação com app por 2+ dias | Notificação gentil: "Sentimos sua falta. Como está indo?" |
| COR-10 | Streak de hábito atingiu novo recorde pessoal | Celebração: "Novo recorde! [N] dias consecutivos de [hábito]" |

**Critérios de aceitação:**

- [ ] `analyze()` retorna em menos de 50ms (síncronamente do SwiftData)
- [ ] Insights não se repetem para o mesmo usuário no mesmo dia
- [ ] Máximo de 2 insights exibidos por sessão para não sobrecarregar o usuário

---

### 11.3 Análise de Sentimento On-Device

**Requisitos funcionais:**

- RF-AI-01: Ao salvar uma entrada de journal, `JournalSentimentAnalyzer` analisa o texto localmente
- RF-AI-02: Em iOS 18+ com Apple Intelligence, usar `FoundationModels` para análise estruturada (sentimento + tópicos + intenções)
- RF-AI-03: Em iOS 15–17 ou sem Apple Intelligence, usar `NaturalLanguage.framework` como fallback
- RF-AI-04: O resultado (sentimentScore + topics) é salvo na entrada e usado pelo `CorrelationEngine`

**Critérios de aceitação:**

- [ ] Análise completa em menos de 500ms (on-device, sem rede)
- [ ] Texto do journal nunca sai do dispositivo neste módulo
- [ ] Fallback com NaturalLanguage produz sentimentScore com precisão aceitável (±0.3 vs Apple Intelligence)

---

### 11.4 Revisão Semanal Automática (Cloud — GPT-4o Mini)

**Contexto:** Todo domingo às 20h, o app prepara e envia um payload de metadados da semana para a Edge Function do Supabase, que chama o GPT-4o Mini e retorna uma análise narrativa personalizada.

**Requisitos funcionais:**

- RF-AI-05: O app gera automaticamente uma revisão semanal todo domingo
- RF-AI-06: O payload enviado nunca contém texto do journal — apenas metadados estruturados
- RF-AI-07: A revisão retornada inclui: headline, 3 destaques, padrões identificados, sugestões acionáveis e um prompt personalizado para a entrada de domingo
- RF-AI-08: O usuário pode desativar a revisão automática nas configurações

**Payload (nunca contém texto sensível):**

```swift
struct WeeklyPayload: Encodable {
    let weekStart: String                  // "2026-03-16"
    let habitCompletion: [String: Float]   // {"meditação": 0.71, "exercício": 0.43}
    let taskStats: TaskWeekStats           // criadas:12, concluídas:8, em_atraso:3
    let moodByDay: [Int]                   // [3,4,2,4,5,3,4] (1–5 por dia)
    let sentimentByDay: [Float]            // [-0.2, 0.4, -0.6, ...]
    let topicsFrequency: [String: Int]     // {"trabalho":4, "ansiedade":2}
    let journalDaysCount: Int
    let streaks: [String: Int]             // {"meditação": 12, "exercício": 3}
}
```

**Critérios de aceitação:**

- [ ] Revisão semanal exibida até às 21h de domingo
- [ ] Se offline no domingo, a revisão é gerada na próxima vez que o app abre com conexão
- [ ] Custo por usuário/semana ≤ $0,002 (GPT-4o Mini: ~1300 tokens total)

---

### 11.5 Busca Semântica no Journal (v1.5)

**Requisitos funcionais:**

- RF-AI-09: Ao criar uma entrada, gerar embedding via `text-embedding-3-small` e armazenar no campo `embedding` (pgvector)
- RF-AI-10: Campo de busca do journal aceita queries em linguagem natural
- RF-AI-11: Resultados da busca semântica são ordenados por relevância (cosine similarity)
- RF-AI-12: Busca semântica e busca por texto completo são combinadas (hybrid search)

**Critérios de aceitação:**

- [ ] Query "quando me senti sobrecarregado" retorna entradas relevantes mesmo sem a palavra "sobrecarregado"
- [ ] Resultados retornam em menos de 1 segundo
- [ ] Custo de embedding por entrada ≤ $0,000006 (300 tokens × $0,02/1M)

---

## 12. Spec — iOS Native

### 12.1 Widgets (WidgetKit)

**Requisitos funcionais:**

- RF-WID-01: Widget small — círculos de progresso dos hábitos do dia
- RF-WID-02: Widget medium — resumo dos três pilares (hábitos X/Y + próxima tarefa + streak journal)
- RF-WID-03: Widget large — lista de tarefas do dia + hábitos pendentes
- RF-WID-04: Widget interativo (iOS 17+) — marcar hábito como completo direto do widget, sem abrir o app
- RF-WID-05: Lock Screen widgets — streak atual de hábito, próxima tarefa, score do dia
- RF-WID-06: Todos os widgets usam `TimelineProvider` com atualização a cada 15 minutos ou após mudança de dados

**Critérios de aceitação:**

- [ ] Widget interativo completa o hábito e atualiza visualmente em menos de 2 segundos
- [ ] Widgets são atualizados corretamente após o sync com Supabase
- [ ] `ModelContainer` é compartilhado entre App target e WidgetExtension target via App Group

---

### 12.2 Apple Watch

**Requisitos funcionais:**

- RF-WAT-01: Watch app exibe lista de hábitos do dia com progresso
- RF-WAT-02: Tap em hábito no Watch o completa com haptic (WKHapticType.success)
- RF-WAT-03: Complication exibe streak do hábito principal configurado pelo usuário
- RF-WAT-04: Voz via ditado permite criar tarefa rapidamente do pulso
- RF-WAT-05: Sincronização Watch ↔ iPhone via `WatchConnectivity` em tempo real

**Critérios de aceitação:**

- [ ] Completar hábito no Watch reflete no iPhone em menos de 5 segundos
- [ ] Watch app funciona mesmo sem iPhone por perto (dados locais em `WatchKit Extension`)

---

### 12.3 Siri e App Intents

**Requisitos funcionais:**

- RF-SIR-01: "Hey Siri, marcar [hábito] como concluído no Rumo"
- RF-SIR-02: "Hey Siri, adicionar tarefa [nome] para amanhã no Rumo"
- RF-SIR-03: "Hey Siri, abrir meu journal de hoje no Rumo"
- RF-SIR-04: Intents são expostos no app Atalhos para automações customizadas

**Critérios de aceitação:**

- [ ] Todos os intents funcionam com o app fechado (background execution)
- [ ] Siri confirma verbalmente a ação realizada ("Hábito meditação marcado como concluído")

---

## 13. Spec — Monetização

### 13.1 Planos

| Plano | Preço | Conteúdo |
|-------|-------|----------|
| **Gratuito** | $0 | Até 3 hábitos · Tarefas ilimitadas (básico) · Journal sem AI · Sem widgets avançados |
| **Premium Mensal** | $4,99/mês | Tudo ilimitado · AI insights · Revisão semanal · Busca semântica · Widgets interativos · Watch |
| **Premium Anual** | $39,99/ano (~$3,33/mês) | Tudo do mensal · 33% de desconto |
| **Lifetime** | $99 (lançamento) | Acesso permanente a todas as features atuais e futuras da v1.x |

### 13.2 Implementação StoreKit 2

**Requisitos funcionais:**

- RF-MON-01: Produtos carregados via `StoreKit.Product.products(for:)` com IDs configurados no App Store Connect
- RF-MON-02: `EntitlementManager` verifica acesso a cada feature premium antes de exibir
- RF-MON-03: Paywall contextual aparece ao tentar usar feature premium (não na abertura do app)
- RF-MON-04: Trial gratuito de 7 dias disponível para planos mensal e anual (configurado no App Store Connect)
- RF-MON-05: Compras são validadas server-side via Supabase Edge Function (evita receipt manipulation)
- RF-MON-06: Restore de compras disponível na tela de perfil

**Critérios de aceitação:**

- [ ] Usuário no plano gratuito vê o quarto hábito como bloqueado (lock icon) — não é deletado
- [ ] Upgrade para Premium desbloqueia instantaneamente todas as features sem reiniciar o app
- [ ] Lifetime não expira — validação via `StoreKit.AppTransaction` offline
- [ ] Comissão Apple de 15% (Small Business Program) — receita abaixo de $1M/ano

---

## 14. Métricas de Sucesso

### Métricas de produto (metas para 90 dias pós-lançamento)

| Métrica | Meta | Medição |
|---------|------|---------|
| D1 Retention | > 40% | TelemetryDeck |
| D7 Retention | > 20% | TelemetryDeck |
| D30 Retention | > 10% | TelemetryDeck |
| Crash-free rate | > 99,5% | Sentry |
| Conversão free → trial | > 8% | TelemetryDeck |
| Conversão trial → pago | > 30% | App Store Connect |
| Usuários com 3 pilares ativos | > 50% dos D7 | TelemetryDeck |
| Média de dias com journal | > 4/semana (usuários pagos) | TelemetryDeck |

### Métricas técnicas (metas contínuas)

| Métrica | Meta |
|---------|------|
| Cold start | < 400ms |
| Scroll 60fps | Lista com 500+ itens |
| Sync latência | < 5s item aparece no Supabase após criação |
| AI on-device (sentimento) | < 500ms por entrada |
| Revisão semanal (cloud) | < 8s end-to-end |
| Custo AI por usuário ativo/mês | < $0,005 |

### Indicador de saúde do produto

O Rumo é bem-sucedido quando usuários usam os **três pilares** consistentemente. Um usuário que usa apenas tarefas poderia usar o TickTick. O diferencial só se realiza com os três.

> **North Star Metric:** Percentual de usuários ativos que interagem com os três pilares na mesma semana.

---

## 15. Roadmap de Versões

### v1.0 — MVP (semanas 1–20)
- Fundação + Auth + Sync
- Módulo de Tarefas completo
- Módulo de Hábitos com gamificação
- Módulo de Journal com prompts e criptografia
- Dashboard unificado
- CorrelationEngine com 10 regras on-device
- Widgets básicos + Watch
- StoreKit 2 com trial

### v1.1 — Estabilidade (semanas 21–24)
- Correções baseadas em feedback da App Store
- Performance: cold start < 400ms
- Acessibilidade: VoiceOver completo nos fluxos principais
- Onboarding revisado baseado em dados de abandono

### v1.5 — Apple Intelligence (semanas 25–32)
- Foundation Models para análise de sentimento (iOS 18)
- Revisão semanal automática via GPT-4o Mini
- Busca semântica no journal (pgvector)
- Compartilhamento social de hábitos e desafios

### v2.0 — Inteligência Profunda (semanas 33–44)
- Chat contextual com o app
- Análise de longo prazo (90 dias) e predição de burnout
- Apple Health integração profunda (HRV, sono no journal)
- App Intents avançados e Spotlight

---

## 16. Decisões Técnicas Registradas

As decisões abaixo foram avaliadas com alternativas e registradas para referência futura.

---

**DTR-01 — Swift nativo vs. Flutter**
- Decisão: **Swift nativo**
- Alternativa considerada: Flutter
- Justificativa: Acesso total às APIs Apple (WidgetKit interativo, Foundation Models, Dynamic Island, WatchConnectivity, PencilKit, HealthKit). Flutter tem lacunas nestas APIs que criam workarounds custosos. Para um app iOS-first com diferenciais baseados em integração com o ecossistema Apple, o custo de desenvolvimento adicional do Swift se paga.

---

**DTR-02 — Supabase vs. Firebase vs. Railway**
- Decisão: **Supabase Pro ($25/mês)**
- Alternativas consideradas: Firebase/Firestore, Railway + extras
- Justificativa: PostgreSQL é o modelo relacional correto para dados de tarefas (hierarquia), hábitos (logs) e journal (metadados). Firestore (NoSQL) exigiria denormalização constante e risco de bill shock por reads. Railway é mais barato mas não tem auth, storage ou realtime nativos — o custo total com Clerk + R2 supera o Supabase Pro. SDK iOS oficial do Supabase é um fator decisivo.

---

**DTR-03 — Criptografia E2E do journal**
- Decisão: **AES-256 GCM client-side, chave no Keychain**
- Alternativa considerada: criptografia server-side (Supabase Vault)
- Justificativa: Criptografia server-side protege contra breach do banco, mas a Supabase (ou qualquer terceiro com acesso ao servidor) ainda pode teoricamente acessar os dados. Criptografia client-side garante que só o dispositivo do usuário pode ler o journal. O trade-off (perda de dados se o Keychain for destruído sem backup) é documentado e aceito.

---

**DTR-04 — Arquitetura MVVM + Coordinator vs. TCA**
- Decisão: **MVVM + Coordinator**
- Alternativa considerada: TCA (The Composable Architecture)
- Justificativa: TCA tem curva de aprendizado significativa e adiciona overhead de código. Para uma equipe pequena e produto em validação, MVVM + Coordinator é mais rápido de iterar. TCA pode ser adotado em módulos específicos (ex: CorrelationEngine) se a complexidade justificar.

---

**DTR-05 — AI runtime: on-device vs. cloud-first**
- Decisão: **Híbrido — on-device para análise cotidiana, cloud para insights profundos**
- Alternativa considerada: cloud-first (tudo via OpenAI)
- Justificativa: Texto do journal é dado extremamente sensível. Enviar para a cloud por padrão criaria objeção de privacidade significativa. On-device (Apple Intelligence / NaturalLanguage) cobre 90% dos casos de uso diários (sentimento, tópicos, alertas) com zero custo e zero latência. A cloud (GPT-4o Mini) é reservada para análises que requerem reasoning profundo (revisão semanal, chat) e nunca recebe texto bruto.

---

**DTR-06 — Localização: PT-BR only vs. Bilíngue desde v1.0**
- Decisão: **Bilíngue PT-BR + EN desde o dia 1**
- Alternativa considerada: PT-BR only no MVP, inglês na v1.1
- Justificativa: Estruturar o projeto com `String(localized:)` desde o início tem custo marginal baixo; refatorar todas as strings depois é custoso e arriscado. O público-alvo primário é brasileiro, mas o app na App Store global fica invisível em buscas em inglês sem localização. O nome "Rumo" é neutro o suficiente para funcionar internacionalmente. O DNA do produto é brasileiro e isso não muda — a localização é somente uma camada de tradução.

---

## 17. Spec — Localização

### Contexto

O Rumo nasce com DNA brasileiro mas precisa ser indexável globalmente na App Store. A decisão (DTR-06) é suportar **PT-BR e EN** desde a v1.0, com PT-BR como idioma base e idioma primário de desenvolvimento.

O público-alvo principal é brasileiro. A linguagem do produto (tom, microcopy, prompts de journal) reflete isso — direto, sem frescura, misturando inglês onde faz sentido (como o próprio usuário faz).

---

### Requisitos Funcionais

- **RF-LOC-01:** O app detecta o idioma do sistema (`Locale.current`) e carrega PT-BR ou EN automaticamente ao abrir pela primeira vez
- **RF-LOC-02:** O usuário pode sobrescrever o idioma do app nas configurações, independente do idioma do sistema (Settings → Idioma / Language)
- **RF-LOC-03:** Todas as strings da UI são definidas via `String(localized:)` com chave semântica — nunca strings literais hardcoded
- **RF-LOC-04:** Datas, números e moedas usam `Locale`-aware formatters (`DateFormatter`, `NumberFormatter`, `Measurement`)
- **RF-LOC-05:** Notificações push e locais são enviadas no idioma configurado no app, não no idioma do sistema
- **RF-LOC-06:** A listagem na App Store tem metadados completos em PT-BR e EN (nome, subtítulo, descrição, screenshots)
- **RF-LOC-07:** Prompts de journal contextuais (ex: "Como você está se sentindo?") são localizados e curados separadamente — não são tradução mecânica

### Requisitos Não-Funcionais

- **RNF-LOC-01:** O idioma base do Xcode project é `pt-BR`; inglês é o segundo idioma adicionado como `en`
- **RNF-LOC-02:** Nenhuma string visível ao usuário pode ser literal em código Swift — CI deve falhar em pull requests que contenham strings UI hardcoded
- **RNF-LOC-03:** O arquivo `Localizable.xcstrings` (formato Xcode 15+ String Catalog) é a fonte de verdade; arquivos `.strings` legados não são usados
- **RNF-LOC-04:** Novas features só chegam à main branch com traduções PT-BR e EN completas

### Implementação Técnica

```swift
// Correto — sempre localizado
Text("habits.streak.label")  // resolve para "Sequência" (PT-BR) ou "Streak" (EN)

// Errado — nunca hardcoded
Text("Sequência")

// Pluralização localizada
Text("habits.completed.count \(count)")
// PT-BR: "1 hábito concluído" / "3 hábitos concluídos"
// EN:    "1 habit completed" / "3 habits completed"
```

Strings que propositalmente misturam inglês no contexto PT-BR (ex: nomes de features como "Streak", "Journal", "Check-in") são mantidas como estão — faz parte da voz do produto.

### Critérios de Aceite

- [ ] Mudar o idioma do dispositivo para inglês exibe 100% da UI em inglês sem strings faltando
- [ ] Mudar o idioma do dispositivo para PT-BR exibe 100% da UI em português
- [ ] O usuário pode trocar o idioma em Settings sem reiniciar o app
- [ ] Notificações chegam no idioma correto mesmo com sistema em idioma diferente
- [ ] A App Store exibe nome, descrição e screenshots localizados ao acessar da App Store BR e da App Store US

---

> **Versão do documento:** 0.2 — Março 2026
> **Próxima revisão:** após conclusão da Fase 2 (Auth + Sync) com feedback de desenvolvimento
