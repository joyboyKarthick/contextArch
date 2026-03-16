# Staff Engineer / Context Engineer Evaluation

> **Context:** Critical review of the ContextArch system (`project_setup.md`).
> **Purpose:** Load this alongside `project_setup.md` in a new session to adopt the recommended fixes.

---

## What's genuinely good -- keep as-is

### 1. Tiered loading model

The insight that not everything needs to be in the agent's context at once, with a hierarchy (always loaded -> per-domain -> per-task -> on-demand) is the single most important design decision. This is the right architecture.

### 2. Context Scope per task

The "Read: X. Ignore: Y." field at the top of each task doc is the highest-value feature. The #1 cause of wasted agent context is reading irrelevant docs. If you shipped nothing else, ship this.

### 3. Single cursor rule for agent behavior

Eliminating redundancy (multiple files defining agent behavior) is unambiguously correct. Auto-loaded means enforced.

### 4. overview.md convention (concept)

One rule, handles both simple and complex, same navigation pattern at any depth. The concept is sound.

---

## What needs fixing -- adopt these changes

### Fix 1: overview.md will go stale (CRITICAL)

**Problem:** Every overview.md is a hand-maintained index. When someone adds a file but forgets to update overview.md, the agent never discovers it. This is the same failure mode as every wiki.

**Fix:** Add a validation script and an agent rule to catch drift.

Create `docs/validate.sh`:
```bash
#!/usr/bin/env bash
# Checks that every .md file in docs/ folders is listed in its parent overview.md
# Run before starting work or as a git pre-commit hook

errors=0
for dir in docs/arch docs/tasks docs/ref; do
  [ ! -d "$dir" ] && continue
  overview="$dir/overview.md"
  [ ! -f "$overview" ] && { echo "MISSING: $overview"; errors=$((errors+1)); continue; }
  for f in "$dir"/*.md; do
    [ "$f" = "$overview" ] && continue
    [ "$(basename "$f")" = "TEMPLATE.md" ] && continue
    [ "$(basename "$f")" = "GROUP_OVERVIEW_TEMPLATE.md" ] && continue
    basename_f=$(basename "$f")
    if ! grep -q "$basename_f" "$overview"; then
      echo "NOT IN OVERVIEW: $f missing from $overview"
      errors=$((errors+1))
    fi
  done
  # Check subfolders (e.g. docs/arch/payments/, docs/tasks/backend/)
  for subdir in "$dir"/*/; do
    [ ! -d "$subdir" ] && continue
    subdir_name=$(basename "$subdir")
    [ "$subdir_name" = "archive" ] && continue
    if ! grep -q "$subdir_name" "$overview"; then
      echo "NOT IN OVERVIEW: $subdir missing from $overview"
      errors=$((errors+1))
    fi
  done
done

if [ $errors -eq 0 ]; then
  echo "All overview.md files are in sync."
else
  echo "$errors inconsistencies found. Update the relevant overview.md files."
  exit 1
fi
```

Add agent rule to project.mdc:
```
12. **Validate overviews** — After adding, removing, or moving any doc, run `bash docs/validate.sh` to ensure overview.md files are in sync.
```

### Fix 2: Task template is too heavy for small tasks

**Problem:** The template has 8 sections (~40 lines boilerplate). For a 1-2 step task like "fix login redirect" or "add a field," this is more overhead than the task itself.

**Fix:** Define two tiers.

**Inline task** (1-2 steps): Lives as a row in the group overview.md. No separate file.

```markdown
# Backend Tasks

| Task | File | Status | Blocked by |
|------|------|--------|-----------|
| Add user CRUD | [user-crud.md](user-crud.md) | In progress | -- |
| **Fix login redirect** | *inline* | Not started | -- |
| **Add created_at to users** | *inline* | Not started | -- |

## Inline Tasks

- [ ] **Fix login redirect** — Update auth/redirect.rs. Verify: `cargo test auth`
- [ ] **Add created_at to users** — Add migration + field. Verify: `sqlx migrate run`
```

**Full task doc** (3+ steps): Separate file using the template. Same as current system.

Update agent rule #2 to:
```
2. **Plan proportionally** — For 1-2 step tasks, add an inline task to the group overview.md. For 3+ step tasks, create a full task doc in the group folder.
```

### Fix 3: Double-write for task status

**Problem:** Rule #5 says update status in both the task doc AND the group overview.md. One will be forgotten. Then overview says "In progress" but task doc says "Done."

**Fix:** Single source of truth. overview.md owns status. Remove the `**Status:**` field from task docs.

- Group overview.md status table is the authority
- Task docs focus on content: Context Scope, Tools, Steps, Notes
- No duplicate to keep in sync
- Agent reads overview.md to know what's active, then reads the task doc for details

Updated task template (remove Status line):
```markdown
# {Task Name}

**Blocked by:** {relative path to prerequisite task, or "none"}
**Group:** {group folder name}

## Context Scope
...
```

### Fix 4: Split project_setup.md into core + appendix

**Problem:** 934 lines is a lot for the agent to read on session 0. The enterprise patterns, detailed explanations, and usage guides are reference material -- not needed for initial setup.

**Fix:** Split into two files.

- `project_setup.md` (~400 lines): Architecture, templates, setup script, agent instructions. Everything needed to set up a project.
- `project_setup_enterprise.md` (~300 lines): Enterprise scaling patterns, detailed rationale. Read only when you hit the scaling thresholds.

Remove the "Enterprise Scaling Patterns" section and "Tools & Environment usage guide" table from the core file. Link to the enterprise doc:
```markdown
## Scaling

For enterprise patterns (task archive, cross-cutting groups, domain-scoped lessons,
concurrent agent branching), see [project_setup_enterprise.md](project_setup_enterprise.md).
Activate these when you hit the thresholds described there.
```

### Fix 5: Make mermaid dependency graphs optional

**Problem:** Nobody updates mermaid diagrams as tasks change. The graph becomes stale on day 2. The status table and "Blocked by" fields are the real dependency tracker.

**Fix:** In the group overview template, make the mermaid graph a comment/note, not a default:

```markdown
# {Group Name} Tasks

| Task | File | Status | Blocked by |
|------|------|--------|-----------|
| Task 1 | [task-1.md](task-1.md) | Done | -- |
| Task 2 | [task-2.md](task-2.md) | In progress | task-1 |

<!-- Optional: add a mermaid dependency graph only if the group has
     complex non-linear dependencies (5+ tasks with branching). -->

Cross-group dependencies: none
```

The "Blocked by" column in the table IS the dependency graph. The mermaid diagram is bonus visualization for complex groups, not a requirement.

### Fix 6: Add filesystem fallback to overview.md convention

**Problem:** If overview.md is stale, the agent is blind to undiscovered files.

**Fix:** Add a fallback to the agent rule:

```
1. **overview.md first** — When entering any docs folder, read its overview.md.
   If overview.md seems incomplete or stale, also run `ls` on the folder to
   discover files not listed. Update overview.md if you find unlisted files.
```

This makes overview.md self-healing: any agent that discovers a mismatch fixes it.

---

## Summary: changes to make

| Fix | What to change | Priority |
|-----|---------------|----------|
| **#1 Validation script** | Add `docs/validate.sh` + agent rule #12 | High |
| **#2 Inline tasks** | Add lightweight task format to group overview template + update rule #2 | High |
| **#3 Single status source** | Remove Status from task docs, overview.md owns status | High |
| **#4 Split core/enterprise** | Move enterprise patterns to separate file, slim core to ~400 lines | Medium |
| **#5 Optional mermaid** | Make dependency graph a comment in the template, not default | Medium |
| **#6 Filesystem fallback** | Update agent rule #1 to self-heal stale overviews | High |

---

## What to keep exactly as-is

- Tiered loading model (Tier 0-3)
- overview.md convention (with fixes #1 and #6 applied)
- Context Scope per task
- Tools & Environment per task
- Cursor rule as single source of agent behavior
- Lessons promotion (lessons.md -> cursor rules)
- Grow-organically principle (no upfront ceremony)
