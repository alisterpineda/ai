# Operations — state, continue, skip, abort

Load this when the operation is anything other than a plain merge, when a `--continue` is refused, or when the run reaches a tail state (autostash, empty commit, a rebase stop with no conflicts).

## Detection, in precedence order

```sh
[ -d "$(git rev-parse --git-path rebase-merge)" ]   # rebase, merge backend (default; -i, -r, -m)
[ -d "$(git rev-parse --git-path rebase-apply)" ]   # rebase (apply backend) OR git am
git rev-parse -q --verify MERGE_HEAD
git rev-parse -q --verify CHERRY_PICK_HEAD
git rev-parse -q --verify REVERT_HEAD
[ -f "$(git rev-parse --git-path sequencer/todo)" ]
```

**The order is not cosmetic, and it is git's own.** `git-prompt.sh` tests `rebase-merge`, then `rebase-apply`, then `MERGE_HEAD`, and only then the sequencer state — and its sequencer check classifies *any* `sequencer/todo` whose first line starts with `pick` as a cherry-pick, which is exactly the shape a rebase todo has. Older gits additionally set `CHERRY_PICK_HEAD` while a `rebase -i` replayed a pick (git 2.52 sets `REBASE_HEAD` instead and leaves `CHERRY_PICK_HEAD` unset). Either way, a pseudoref-first check can report "cherry-pick" for a rebase — and then `git cherry-pick --continue` runs against a rebase, which errors out (`error: no cherry-pick or revert in progress`) or advances the wrong state machine. **Test the directories first, always.**

The reliable positive tells, once the directories have decided:

| Set | Means |
|---|---|
| `REBASE_HEAD` | A rebase is replaying this commit — it is the *theirs* side. |
| `CHERRY_PICK_HEAD` | A real `git cherry-pick` (not a rebase, on current git). |
| `REVERT_HEAD` | A real `git revert`. |
| `MERGE_HEAD` | A merge. |

Inside `rebase-apply`, the two cases are distinguished by marker files:

| File present | Operation | Continue |
|---|---|---|
| `rebase-apply/rebasing` | rebase (apply backend) | `git rebase --continue` |
| `rebase-apply/applying` | `git am` | `git am --continue` |

Neither directory present and no pseudoref, but `git diff --diff-filter=U` is non-empty → `git stash pop`, `git checkout -m`, or `git apply -3`. There is no state machine and no continue: **staging is the finish.**

Useful files inside the state directories (read-only, all via `git rev-parse --git-path`):

| Path | What it tells you |
|---|---|
| `rebase-merge/head-name` | The branch being rebased (`refs/heads/…`). |
| `rebase-merge/onto` | The commit being replayed onto — the "ours" side. |
| `rebase-merge/orig-head` | The pre-rebase tip. Survives `ORIG_HEAD` being clobbered. |
| `rebase-merge/git-rebase-todo` | What is left to replay. |
| `rebase-merge/done` | What has already been replayed. |
| `rebase-merge/msgnum`, `end` | Progress: "commit N of M". |
| `sequencer/todo` | Remaining cherry-pick/revert sequence. |
| `MERGE_MSG` | The commit message git will use. |

`REBASE_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD` are all readable with `git show` / `git log -1` for the subject line — use them to name the stopping commit in the report.

## Per-operation table

| Operation | Continue | Skip | Abort | Abort restores |
|---|---|---|---|---|
| merge | `GIT_EDITOR=true git merge --continue` | — | `git merge --abort` | Pre-merge HEAD and tree. **Caveat below.** |
| rebase | `GIT_EDITOR=true git rebase --continue` | `git rebase --skip` | `git rebase --abort` | The original branch at its original tip. |
| rebase (quit) | — | — | `git rebase --quit` | Nothing — leaves HEAD where it is and forgets the rebase. |
| cherry-pick | `GIT_EDITOR=true git cherry-pick --continue` | `git cherry-pick --skip` | `git cherry-pick --abort` | The sequence's starting state. |
| cherry-pick (quit) | — | — | `git cherry-pick --quit` | Keeps already-applied picks, drops the sequence. |
| revert | `GIT_EDITOR=true git revert --continue` | `git revert --skip` | `git revert --abort` | The sequence's starting state. |
| `git am` | `git am --continue` | `git am --skip` | `git am --abort` | Pre-`am` HEAD. |
| stash pop | — (staging is the finish) | — | **none** | See below. |
| `checkout -m` / `apply -3` | — | — | **none** | `git checkout --merge -- <paths>` or `git checkout HEAD -- <paths>`. |

### Why every continue gets `GIT_EDITOR=true`

There is no portable `--no-edit` on the continue verbs — the flags simply do not exist:

```
$ git merge --continue --no-edit
fatal: --continue expects no arguments
$ git rebase --continue --no-edit
error: unknown option `no-edit'
```

`git merge --continue` opens the editor for `MERGE_MSG`; `git rebase --continue` and `git cherry-pick --continue` open it for the replayed commit's message. `GIT_EDITOR=true` makes the editor a no-op that exits 0, accepting the prepared message. It works uniformly on all of them, so apply it uniformly rather than reasoning per command about whether this particular one will prompt.

(`git commit --no-edit` and `git merge --no-edit` *at merge start* are real and different — they are not the continue path.)

### `git merge --abort` on a dirty tree

`git merge --abort` is `git reset --merge`, and its own documentation warns it "may not be able to fully restore" changes that were in the working tree when the merge started. If step 1 recorded a dirty tree at merge start, say so in the report's escape hatch — the abort command is still right, but it is not a guaranteed undo, and the user may want to save their work first.

### `git rebase --continue` refuses on *any* unstaged change

> `Cannot rebase: You have unstaged changes.`

It means anywhere in the tree, not just in conflicted files. A build fix touching a file that never conflicted blocks the continue until it is staged. Stage those too — by name — or the loop stalls with a message that looks unrelated to what was actually edited.

### Empty result → `--skip`, not `--continue`

> `The previous cherry-pick is now empty, possibly due to conflict resolution.`
> `Otherwise, please use 'git cherry-pick --skip'`

This happens whenever the resolution ends up matching what is already there — most often when the resolution is "take upstream wholesale". `--skip` drops the now-redundant commit, which is the correct outcome. **Never** reach for `--allow-empty`: it records a commit that changes nothing, which is noise in the history and hides the fact that the change was already present.

The same applies to `git rebase --skip` and `git revert --skip`.

## Interactive rebase stops that are not conflicts

`git rebase -i` stops for reasons other than conflict, and the tell is an operation in progress with **zero** unmerged paths:

| Todo verb | Why it stopped | How it continues |
|---|---|---|
| `edit` | Deliberate pause to amend the commit | `git commit --amend`, then `GIT_EDITOR=true git rebase --continue` |
| `break` | Deliberate pause, nothing to amend | `git rebase --continue` |
| `reword` | Message editor | `GIT_EDITOR=true` accepts as-is (defeats the point — usually the user wants to type) |
| `exec` failure | A command in the todo exited non-zero | Fix the cause, then `git rebase --continue` |

Report the state and what it is waiting for. Do not invent conflicts, and do not `--continue` past an `edit` the user asked for.

## Tail states

### Autostash

`rebase.autoStash` and `merge.autostash` (and `--autostash`) stash a dirty tree at the start and pop it at the end. **That pop can conflict:**

> `Applying autostash resulted in conflicts.`
> `Your changes are safe in the stash.`

The operation itself completed — the state directories are gone, HEAD is where it should be — and what is left is a stash-pop-shaped conflict with no operation in progress. Handle it as the stash-pop branch of the skill, and note that the entry is still in `git stash list`.

### Rebase completed but HEAD looks detached

During a rebase HEAD is detached by design; it reattaches to `head-name` on completion. A detached HEAD *after* the state directory is gone means the rebase ended abnormally (`--quit`, or a crash) — reconcile against `rebase-merge/orig-head` recorded in step 1 before doing anything else.

### rerere

`git rerere` records conflict resolutions and replays them on identical conflicts later.

```sh
git rerere remaining   # unmerged paths NOT auto-resolved by rerere
git rerere diff        # what rerere changed, per path
git rerere status      # paths rerere is tracking for this conflict
```

The trap: with the default `rerere.autoUpdate=false`, an auto-resolved file gets clean content in the working tree but **stays unmerged in the index**. It shows up in `git diff --diff-filter=U`, greps clean for markers, and would be staged unread. Any path in the `U` list but *absent* from `git rerere remaining` was auto-applied from a previous resolution — read it by hand before staging. **Guard the rule on rerere being active** (`git config --get rerere.enabled`, or `[ -d "$(git rev-parse --git-path rr-cache)" ]`): rerere is off by default, and then `git rerere remaining` prints nothing and exits 0, which would make the rule flag every conflicted file.

The other direction matters for the report: if rerere is enabled, the resolutions made in this run are being **memorized** and will be replayed silently the next time the same conflict appears. That belongs in the Risks section.

## Stash pop — the non-answer

There is no `git stash pop --abort` and no `--continue`. What is true:

- **The stash entry is not dropped** when the pop conflicts. The work is still in `git stash list` — that is the safety net.
- **Staging is the finish.** Once every path is staged, the pop is complete.
- Staging leaves everything **staged**, which is not the state the user's working tree was in before. Offer `git restore --staged -- <paths>` to put it back to modified-but-unstaged.
- To get back to the conflicted state on a path: `git checkout --merge -- <path>` re-creates the markers from the index stages.
- To discard a path's changes entirely: `git checkout HEAD -- <path>` — destructive, ask first.
- **Never `git reset --hard`.** It is the common advice and it is wrong here: it destroys every unrelated uncommitted change in the tree along with the conflict.
- `git stash drop` is its own ask, and the default answer is don't — the entry costs nothing and it is the only copy of that work if the resolution turns out wrong.

## `git am`

`git am` applies a mailbox of patches; it is not a rebase, even though it shares the `rebase-apply` directory. Stop and explain rather than issuing a rebase command:

- `git am --continue` after staging resolutions (`git am --resolved` is the same thing).
- `git am --skip` drops the failing patch.
- `git am --abort` returns to the pre-`am` HEAD.
- `git am --show-current-patch=diff` shows what failed to apply — usually the fastest way to see why.

A 3-way fallback (`git am -3`) produces real conflict markers; without `-3` it produces `.rej` files and no index conflicts at all, which is a different problem with a different fix (apply the reject by hand, or re-run with `-3`).
