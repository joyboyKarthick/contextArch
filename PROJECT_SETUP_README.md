# AI-Agent Project Setup: Context Architecture for Agent-Driven Development

Stop repeating yourself to AI agents. Stop drowning them in docs. Give them exactly what they need, when they need it.

---

## The Problem

If you build software with AI agents (Cursor, Claude, Copilot), you've hit these walls:

**Wall 1: Context repetition.** Every new agent session, you re-explain the tech stack, project structure, build commands, and architecture. Or the agent reads your 500-line ARCHITECTURE.md from scratch -- burning 30% of its context window before writing a single line of code.

**Wall 2: Context rot.** You've accumulated 20-40 markdown files -- architecture docs, task plans, implementation guides, acceptance criteria, agent workflow docs, lessons learned. Most are irrelevant to the current task. The agent reads them all anyway because it doesn't know which ones matter.

**Wall 3: Navigation chains.** Your cursor rule points to a workflow doc, which points to an agent guide, which points to the architecture doc, which indexes 4 split docs, which link to plan folders, which contain task docs. That's 6-8 file reads of pure navigation overhead.

**Wall 4: Stale instructions.** Agent behavior rules live in 3 places (cursor rule, workflow doc, agent guide). They slowly drift out of sync. The agent follows whichever it reads last.

---

## The Solution: 3-Tier Context Architecture

One system, one convention: **every folder has an `overview.md` -- the agent always reads it first.**

```
Your project/
  .cursor/rules/
    project.mdc                         <-- Tier 0: auto-loaded every session (~80 lines)
  docs/
    arch/
      overview.md                       <-- Tier 1 entry: routes to the right domain doc
      backend.md                            Simple domain = single file
      payments/
        overview.md                         Complex domain = folder with sub-docs
        processing.md
        billing.md
    tasks/
      overview.md                       <-- Tier 2 entry: all groups + cross-group status
      backend/
        overview.md                         Group: status table + dependency graph
        graph-schema.md                     Task doc with steps + verification
        repo-discovery.md
      ui/
        overview.md
        explorer.md
    ref/
      overview.md                       <-- Tier 3 entry: what reference docs exist
      requirements.md
      roadmap.md
      lessons.md
```

**Per-session context cost:**

| What | Lines | When |
|------|-------|------|
| `project.mdc` | ~80 | Auto-loaded (free) |
| `docs/arch/overview.md` | ~25 | Agent reads to find the right domain |
| `docs/arch/backend.md` | ~150 | Only the domain relevant to this task |
| `docs/tasks/backend/overview.md` | ~20 | Status + deps for this group |
| Task doc | ~50 | The actual task being worked on |
| **Total** | **~325** | **Instead of 2000+** |

---

## Walkthrough: Real Project Example

Let's say you're building **ShopAPI** -- a Rust backend with a React admin dashboard, PostgreSQL, and Docker deployment.

### Step 1: Run setup

You give the agent: *"Set up this project using project_setup.md. Project: ShopAPI, Rust + React + PostgreSQL."*

The agent runs the setup script. Your project now has:

```
ShopAPI/
  .cursor/rules/project.mdc
  docs/arch/overview.md
  docs/tasks/overview.md
  docs/tasks/TEMPLATE.md
  docs/tasks/GROUP_OVERVIEW_TEMPLATE.md
  docs/ref/overview.md
  docs/ref/lessons.md
  docs/ref/requirements.md
  docs/ref/roadmap.md
```

### Step 2: Agent fills in project.mdc

The agent inspects your codebase and fills in:

```
---
description: ShopAPI -- project context, commands, and agent rules
alwaysApply: true
---

# ShopAPI

E-commerce REST API with admin dashboard.

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Backend | Rust (Axum, SQLx) | 1.75+ |
| Database | PostgreSQL 16 | Docker |
| Frontend | React (Vite, TypeScript) | Admin dashboard |
| Infra | Docker Compose | Dev + prod |

## Project Structure

ShopAPI/
  api/              # Rust backend
  admin-ui/         # React admin dashboard
  db/migrations/    # SQL migrations
  docker-compose.yml

## Commands

| Action | Command |
|--------|---------|
| Build | `cd api && cargo build` |
| Test | `cd api && cargo test` |
| Lint | `cd api && cargo clippy` |
| Run | `docker compose up -d` |

## Navigation

Every docs folder has an overview.md. Always read it first.

- Architecture: docs/arch/overview.md
- Tasks: docs/tasks/overview.md
- Reference: docs/ref/overview.md

## Agent Rules
...11 rules...

## Active Lessons

(None yet.)
```

This is auto-loaded every session. The agent always knows what ShopAPI is, how to build it, and where to look next.

### Step 3: Agent creates architecture docs

```
docs/arch/
  overview.md       # Routes agent to the right doc
  backend.md        # Axum routes, SQLx queries, module structure
  database.md       # Schema, migrations, indexes
  ui.md             # React components, API integration
```

`docs/arch/overview.md` looks like:

```markdown
# Architecture Overview

| Domain | Doc | Structure | Description |
|--------|-----|-----------|-------------|
| Backend | [backend.md](backend.md) | Single file | Axum REST API, auth, services |
| Database | [database.md](database.md) | Single file | PostgreSQL schema, migrations |
| UI | [ui.md](ui.md) | Single file | React admin dashboard |
```

### Step 4: Work begins -- agent creates tasks

You say: *"Add product catalog CRUD endpoints."*

The agent creates:

```
docs/tasks/
  overview.md                                   # Updated with new group
  backend/
    overview.md                                 # Status + dependency graph
    product-catalog-crud.md                     # The actual task
```

`docs/tasks/backend/product-catalog-crud.md`:

```markdown
# Product Catalog CRUD

**Status:** In progress
**Blocked by:** none
**Group:** backend

## Context Scope

Read: docs/arch/backend.md, docs/arch/database.md
Ignore: docs/arch/ui.md, everything in docs/ref/

## Tools & Environment

- **CLI tools:** cargo test, sqlx migrate run
- **Env vars:** DATABASE_URL=postgres://localhost/shopapi

## What / Why

Add CRUD endpoints for products: create, read (list + detail), update, delete.
Products have: id, name, price, description, category_id, created_at.
Out of scope: image upload, search/filtering.

## Steps

1. [ ] Add Product model and migration
   - Create db/migrations/002_products.sql
   - Verify: `sqlx migrate run && sqlx migrate info`
   - Expected: Migration applied, products table exists

2. [ ] Add product repository
   - CRUD functions in api/src/repo/products.rs
   - Verify: `cargo test repo::products`
   - Expected: All tests pass

3. [ ] Add REST endpoints
   - POST/GET/PUT/DELETE /api/products in api/src/routes/products.rs
   - Verify: `cargo test routes::products`
   - Expected: All endpoint tests pass

## Notes

- Arch impact: docs/arch/backend.md (add products module), docs/arch/database.md (add schema)
- Estimated effort: medium
```

**The agent now has everything it needs in ~325 lines of context.** No navigation chains. No reading 40 irrelevant docs.

### Step 5: Months later -- project has grown

ShopAPI now has 12 domains and 80+ tasks. The system scaled without restructuring:

```
docs/arch/
  overview.md                           # 12 rows, still ~25 lines
  backend.md                            # Simple domain
  database.md                           # Simple domain
  payments/                             # Outgrew single file -- split
    overview.md                         # Routes to sub-docs
    processing.md
    subscriptions.md
    refunds.md
  auth/                                 # Also split
    overview.md
    oauth.md
    rbac.md
  ui.md
  notifications.md
  search.md
  ...

docs/tasks/
  overview.md                           # 8 groups listed
  cross-cutting/                        # Enterprise pattern: multi-domain tasks
    overview.md
    audit-logging.md
  backend/
    overview.md                         # Only 5 active tasks shown
    current-task.md
    archive/                            # Enterprise pattern: completed tasks moved here
      overview.md                       # 25 completed tasks logged
      product-crud.md
      ...

.cursor/rules/
  project.mdc                           # Still ~80 lines -- never grew
  lessons-payments.mdc                  # Enterprise pattern: domain-scoped lessons
  lessons-auth.mdc                      # Only loaded when touching auth files
```

**The cursor rule never changed.** The navigation pattern never changed. The agent still reads overview.md first, follows it to the right doc, and gets exactly the context it needs.

---

## Before / After

A real comparison from the project where this system was developed:

| Dimension | Before (ad-hoc docs) | After (this system) |
|---|---|---|
| Files read per session | 8-9 (~2000+ lines) | 3-4 (~350 lines) |
| Agent instruction sources | 3 redundant files | 1 cursor rule |
| Navigation depth | 3 levels (plan index -> plan -> task) | 1-2 levels (overview -> doc) |
| Architecture entry | 530-line monolith | 25-line overview + domain docs |
| Acceptance criteria | 2 competing systems | Embedded per-step in task doc |
| Context scoping | None (read everything) | Explicit "Read / Ignore" per task |
| Adding a new domain | Edit cursor rule + architecture monolith | Add a file + 1 row in overview.md |
| Scaling to 20+ domains | Cursor rule routing table bloats | overview.md scales independently |

---

## How It Works: The `overview.md` Convention

The entire system rests on one rule: **every folder has an `overview.md` that the agent reads first.**

For small sections, `overview.md` IS the content:

```markdown
# Reference Overview

| Doc | When to read |
|-----|-------------|
| requirements.md | Defining new features |
| roadmap.md | Planning releases |
| lessons.md | After corrections |
```

For large sections, `overview.md` is a thin router:

```markdown
# Architecture Overview

| Domain | Doc | Structure | Description |
|--------|-----|-----------|-------------|
| Backend | backend.md | Single file | REST API |
| Payments | payments/overview.md | Sub-folder | Processing, billing, compliance |
```

When a domain grows, you split the file into a folder. Only the parent `overview.md` gets a path update. The cursor rule, agent rules, and every other task doc remain untouched. This is how the system scales from a weekend project to an enterprise monolith without a rewrite.

---

## Getting Started

1. Save [`project_setup.md`](project_setup.md) somewhere accessible
2. Start a new project (or open an existing one in Cursor)
3. Tell the agent: *"Set up this project using project_setup.md"*
4. The agent creates the folder structure, fills in your project details, and you're ready to go

The setup takes ~2 minutes. Every agent session after that starts with full project context already loaded, zero repetition, zero navigation overhead.

---

## What's Inside `project_setup.md`

| Section | What it contains |
|---------|-----------------|
| Problem statement | Why this system exists |
| 3-Tier Architecture | How the tiers work and when each is read |
| Templates | Ready-to-use templates for every file type |
| Setup script | Bash script that creates the entire folder structure |
| Agent instructions | Step-by-step for the agent to execute the setup |
| Enterprise patterns | 4 additive patterns for large-scale projects |
| Design principles | Why each design decision was made |

The file is self-contained. The agent reads it, understands the system, and executes the setup autonomously. No human intervention needed beyond "set up this project."
