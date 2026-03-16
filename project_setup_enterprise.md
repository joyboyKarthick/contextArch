# Enterprise Scaling Patterns

> **Context:** Extension of [project_setup.md](project_setup.md). These patterns are not needed for small projects. Apply them when the project hits the threshold described in each section.

---

## 1. Task Archive (threshold: 15+ tasks in a group)

When a group's overview.md lists more than ~15 tasks, completed tasks become noise. The agent reads 15 "Done" rows to find the 3 active ones.

**Solution:** Move completed tasks to an `archive/` subfolder within the group.

```
docs/tasks/backend/
  overview.md                   # Only active + blocked tasks
  sync-branch.md                # In progress
  search-tool.md                # Blocked
  archive/
    overview.md                 # Historical log of completed tasks
    graph-schema.md             # Done
    repo-discovery.md           # Done
    scoping-repo-branch.md      # Done
```

**Rules:**
- When a task is marked Done, move it to `archive/` and remove its row from the group overview.md
- Add a row to `archive/overview.md` (date completed, brief result)
- The group overview.md stays lean: only active, blocked, and not-started tasks
- Archive is never read during normal work -- only for historical reference

## 2. Cross-Cutting Task Group (threshold: tasks spanning 3+ domains)

Enterprise monoliths have tasks that don't belong to any single domain: "add audit logging everywhere", "migrate to gRPC", "upgrade auth library across all services."

**Solution:** Create a `cross-cutting/` task group.

```
docs/tasks/
  overview.md
  cross-cutting/
    overview.md                 # Status + affected domains per task
    audit-logging.md            # Touches: auth, payments, orders, notifications
    grpc-migration.md           # Touches: all backend services
  backend/
    overview.md
    ...
```

**Cross-cutting task doc additions:**

```markdown
# Audit Logging

**Blocked by:** none
**Group:** cross-cutting
**Affected domains:** auth, payments, orders, notifications

## Context Scope

Read: docs/arch/overview.md (to find all affected domain docs)
Read: docs/arch/backend.md (logging infrastructure)
```

**Rules:**
- Cross-cutting tasks list all affected domains in an "Affected domains" field
- Agent reads `docs/arch/overview.md` to find the arch docs for each affected domain
- If a cross-cutting task blocks domain tasks, those domain tasks reference it: `Blocked by: ../cross-cutting/audit-logging.md`
- Cross-cutting group is listed first in `docs/tasks/overview.md`

## 3. Domain-Scoped Lessons (threshold: 15+ lessons or 10+ domains)

When lessons accumulate, the "Active Lessons" section in `project.mdc` grows until it dominates the cursor rule. 20 lessons = 40-60 lines of rules, most irrelevant to the current task domain.

**Solution:** Use Cursor's glob-scoped rules to load lessons only for the domain the agent is working in.

```
.cursor/rules/
  project.mdc                           # alwaysApply: true -- universal rules + 3-5 universal lessons
  lessons-backend.mdc                   # globs: ["services/backend/**", "src/api/**"]
  lessons-payments.mdc                  # globs: ["services/payments/**"]
  lessons-ui.mdc                        # globs: ["graph-ui/**", "frontend/**"]
```

**Each domain lesson rule:**

```
---
description: Lessons for {domain} -- auto-loaded when editing {domain} files
globs: ["{path-pattern}/**"]
---

# {Domain} Lessons

- {Lesson from correction on 2026-03-10: ...}
- {Lesson from correction on 2026-03-15: ...}
```

**Rules:**
- `project.mdc` keeps only 3-5 universal lessons (apply to ALL domains)
- Domain-specific lessons go in domain `.mdc` files with `globs:` matching that domain's file paths
- When promoting from `docs/ref/lessons.md`: if it's universal, add to `project.mdc`; if domain-specific, add to `lessons-{domain}.mdc`
- Cursor auto-loads the right lessons when the agent touches files in that glob

**Migration:** Start with all lessons in `project.mdc`. When you hit ~10 lessons, split domain-specific ones into glob-scoped rules.

## 4. Concurrent Agent Branching (threshold: 2+ agents working simultaneously)

When multiple agents work on different tasks in the same repo, they can create conflicting changes to overview.md files, mark tasks done that block each other, or introduce merge conflicts.

**Solution:** Each agent works on a git branch. Status updates are coordinated through branch + PR workflow.

**Branch convention:**

```
main                          # Source of truth for all overview.md files
task/backend-sync-branch      # Agent A working on sync-branch task
task/ui-explorer              # Agent B working on explorer task
task/cross-cutting-audit      # Agent C working on audit logging
```

**Rules:**
- Each agent creates a branch named `task/{group}-{task-name}` before starting work
- Agents update their own task doc's status on their branch
- Agents do NOT update group overview.md or top-level overview.md on their branch
- When work is done, create a PR. The PR description includes status changes for overview.md files
- Overview.md status updates happen on merge to `main` (by the merging agent or human)
- Before starting work, agent pulls `main` and reads overview.md files to check current status

**Task doc addition for concurrent work:**

```markdown
**Branch:** task/backend-sync-branch
```

**Why this works:** Overview.md files are the coordination layer. By updating them only on `main` (via PR merge), concurrent agents never conflict on status tracking. Each agent's actual code changes are isolated on their own branch.

## Scaling Checklist

Use this to decide which patterns to activate:

| Signal | Pattern to activate |
|--------|-------------------|
| A task group has 15+ tasks (most Done) | Task Archive (#1) |
| A task touches 3+ domains | Cross-Cutting Group (#2) |
| 10+ lessons in project.mdc Active Lessons | Domain-Scoped Lessons (#3) |
| 2+ agents assigned to different tasks simultaneously | Concurrent Agent Branching (#4) |
| An arch doc exceeds 200 lines | Split into `{domain}/overview.md` + sub-docs (already in base system) |
| A group overview.md exceeds 30 lines | Archive completed tasks (#1) or split the group |

None of these require restructuring the base system. They are additive -- activate when you hit the threshold, ignore until then.

---

## Tools & Environment Usage Guide

| Field | When to include | Example |
|-------|----------------|---------|
| **MCP servers** | Task interacts with external services via MCP | `firebase` for deploy, `dart` for Flutter analysis |
| **CLI tools** | Task needs specific build/test/deploy commands | `cargo test graph`, `psql -d mydb` |
| **Agent type** | Task needs a specific subagent | `shell` for build-heavy, `browser-use` for UI testing |
| **Browser** | Task requires visual verification or UI interaction | `Yes -- http://localhost:8080/settings` |
| **Scripts** | Task uses project-specific automation | `./scripts/migrate.sh`, `./restart.sh` |
| **Env vars** | Task needs specific environment configuration | `DATABASE_URL=...`, `API_KEY=...` |

Most tasks will only need 1-2 of these fields. Delete the rest to keep the doc lean.
