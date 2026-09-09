# Conflict types that are not a plain `UU`

Load this for anything the long-form `git status` does not call `both modified:`. Most of these have **no conflict markers anywhere**, which makes a clean marker grep actively misleading — the structural gate (`git diff --name-only --diff-filter=U` empty after staging) is what catches them.

## The porcelain code table

`git status --porcelain=v1` two-letter codes for unmerged entries. Read them alongside the long form, which is harder to misread:

| Code | Long form | Meaning |
|---|---|---|
| `UU` | `both modified:` | Both sides changed the content. The only type with markers. |
| `AA` | `both added:` | Both sides created the path independently. No merge base (stage 1 absent). |
| `DD` | `both deleted:` | Both sides deleted it, but something else differs (usually a rename). |
| `AU` | `added by us:` | We added it; they modified a path they had and we didn't. |
| `UA` | `added by them:` | They added it; we didn't have it. |
| `DU` | `deleted by us:` | We deleted it; they modified it. |
| `UD` | `deleted by them:` | They deleted it; we modified it. |

Stage numbers: **1 = merge base, 2 = ours, 3 = theirs.** A missing stage is information — `AA` has no stage 1, `UD` has no stage 3, `DU` has no stage 2.

## Delete/modify (`UD` / `DU`)

The single most dangerous type, because the file on disk looks completely normal — it is just one side's content, unmarked.

Establish what actually happened before choosing:

```sh
git log --oneline --follow -- <path>     # was it renamed rather than deleted?
git log --diff-filter=D --oneline -- <path>   # the commit that deleted it, and its message
git show :2:<path>   # our version (absent if we deleted)
git show :3:<path>   # their version (absent if they deleted)
```

The real question is whether the modification is *superseded* by the deletion (the file's purpose moved elsewhere — keep the delete) or *independent of* it (the delete was a cleanup that didn't know about the change — keep the file, port the change to wherever it moved). The diff cannot answer that; the deleting commit's message usually can.

**This always stops and asks, even with `--fix`.** Both resolutions destroy something.

Resolving:

```sh
git rm -- "$path"             # accept the deletion — git add CANNOT resolve a deleted path

# Or keep the surviving side. Which flag works is fixed by the code, because the
# deleting side has no stage: UD (they deleted) has only stage 2 — use --ours;
# DU (we deleted) has only stage 3 — use --theirs. The wrong one exits 1 with
# "does not have their version", and the && then swallows the git add, leaving
# the path unmerged. Confirm with `git ls-files -u -- "$path"` rather than guess.
git checkout --ours   -- "$path" && git add -- "$path"   # UD: keep our modification
git checkout --theirs -- "$path" && git add -- "$path"   # DU: keep their modification
```

`git rm` is destructive, so it gets its own ask on top of the type's ask.

## Both added / add-add (`AA`)

Two sides created the same path independently. There is **no merge base**, so `git show :1:<path>` fails and `git merge-file` has no base to work from — which is itself the diagnostic signal, not an error to work around.

Git still writes markers for the text case, but they are a two-way diff with nothing to anchor them, so they read worse than usual. Compare the two versions directly instead:

```sh
git diff :2:<path> :3:<path>
```

Common causes and their fixes: the same feature implemented twice (pick one deliberately, or unify — this needs a decision), a generated file (regenerate, don't merge), or a rename landing on an existing path (see below).

## Both deleted (`DD`)

Both sides deleted the path, so the deletion is not in dispute — something adjacent is, usually a rename that git detected on one side and not the other. `git rm -- <path>` resolves it, but check `git log --diff-filter=R --oneline` on both sides first to see where the content went; if only one side's rename target exists, the other side's content may have been silently dropped.

## Renames

`git status` reports these with a source and destination path. Rename detection is heuristic (similarity-based, `-M`), so the first question is always whether git got the detection right:

```sh
git diff --find-renames --name-status <base> <side>
git log --oneline --follow -- <path>
```

| Situation | What it means | Resolution shape |
|---|---|---|
| **rename/rename** | Both sides renamed the same file, to different names | Pick one name, merge the *content* of both, delete the loser path. Content and naming are separate decisions — resolve both. |
| **rename/delete** | One side renamed, the other deleted | Same judgment as delete/modify: was the delete aware of the content? |
| **rename/add** | One side renamed onto a path the other side created | Two files' worth of content want one path. Usually one gets a new name. |

Rename conflicts leave the content conflict at the *destination* path and often leave the source path unmerged too. Resolve both, or the operation will not continue.

## Binary files

```
warning: Cannot merge binary files: <path> (HEAD vs. <other>)
```

There is no merging. The working-tree file is one side's bytes, whole, with no markers. Pick a side explicitly:

```sh
git checkout --ours   -- <path>   # remember the rebase inversion
git checkout --theirs -- <path>
git add -- <path>
```

Before picking, check whether the binary is *generated* (an image built from a source file, a compiled asset, a lockfile in binary form). If so, the resolution is to regenerate it after resolving its source — picking a side just picks a stale artifact.

## Submodules

```
CONFLICT (submodule): Merge conflict in <path>
```

The conflict is over which **commit** the submodule should point at. It is not a text conflict and the two SHAs are usually both valid — picking the newer one is a guess unless you know the submodule's history.

```sh
git ls-tree HEAD <path>                     # what we point at
git rev-parse :2:<path> :3:<path>           # both candidate SHAs
git -C <path> log --oneline :2:...:3:       # what actually differs (if both are fetched)
```

Resolve by checking out the intended commit inside the submodule and staging the gitlink:

```sh
git -C <path> checkout <chosen-sha>
git add -- <path>
```

**Always stops and asks, even with `--fix`.** A wrong submodule pointer is invisible in review and breaks everyone's checkout.

## Mode and type conflicts

- **Mode-only** (`old mode 100644 / new mode 100755`): no content conflict, but the mode still has to be chosen. `git update-index --chmod=+x -- <path>` sets it explicitly.
- **File vs directory**: one side made `foo` a file, the other a directory containing `foo/bar`. Git renames one out of the way (`foo~HEAD`). Decide the structure, then move content into place by hand.
- **File vs symlink**: same shape — one stage is a link, the other a regular file. `git ls-files -s -- <path>` shows the mode bits (`120000` = symlink) per stage.

## Generated and lock files

These are the ones most often resolved wrongly, because they look like text and merge like garbage. **Regenerate; do not hand-merge.**

| File | Regenerate with |
|---|---|
| `package-lock.json`, `npm-shrinkwrap.json` | resolve `package.json` first, then `npm install` |
| `yarn.lock` | `yarn install` |
| `pnpm-lock.yaml` | `pnpm install` |
| `Cargo.lock` | resolve `Cargo.toml`, then `cargo build` / `cargo update -p <pkg>` |
| `go.sum` | `go mod tidy` |
| `poetry.lock`, `uv.lock` | `poetry lock --no-update` / `uv lock` |
| `Gemfile.lock` | `bundle install` |
| snapshot tests | re-run the suite with its update flag |
| compiled/bundled output, generated clients | re-run the generator |

The rule: resolve the **source of truth** (the manifest, the schema, the fixture) as a normal text conflict, then regenerate the artifact from it and stage the regenerated result. A hand-merged lockfile can be internally inconsistent in ways nothing will catch until a fresh install on someone else's machine.

Migration files are the adjacent trap: two branches each adding a migration is not a text conflict at all (different filenames), but the *ordering* and any shared schema state are semantically conflicted. **Always stops and asks.**

## Merge drivers and `.gitattributes`

A repo can pre-decide some of this. Check before resolving by hand:

```sh
git check-attr -a -- <path>
```

- `merge=union` — git concatenates both sides' lines with no markers. Great for changelogs and ignore files; means the file may already be "resolved" in a way nobody reviewed.
- `merge=ours` / a custom driver — the repo has an opinion; honor it.
- `merge=binary` — treat as binary regardless of content.
- `-merge` — never merge; always conflict.
- `conflict-marker-size=<n>` — **the marker length differs on this path**, which breaks a hardcoded 7-character grep. This is a gitattribute; there is no config key of the same name.
- `text` / `eol` / `working-tree-encoding` — line-ending or encoding normalization; a whole-file conflict here usually means a renormalization is needed rather than a merge (`git merge -Xrenormalize`).

## Whitespace and line-ending churn

If every conflict in the file (or in the whole operation) is indentation or CRLF/LF, do not hand-resolve. Abort and re-run the operation with the right strategy option:

```sh
git merge   -Xignore-all-space  <other>     # or -Xignore-space-change
git rebase  -Xrenormalize       <upstream>  # line endings
```

Hand-resolving these produces a diff full of invisible changes and loses one side's real edits inside the noise.

## Semantic conflicts — the ones git cannot see

Both sides merge cleanly, and the result is wrong. Git has no signal for these, so they belong in the report's **Risks** section rather than the per-file plan.

The recurring shapes:

- One side renames a function or changes a signature; the other side adds a new call to the old one. Merges clean, fails to compile — or worse, silently resolves to a different overload.
- One side changes a function's semantics (units, nullability, error vs exception); the other adds a caller assuming the old contract. Compiles fine.
- One side adds a field to a struct/schema; the other adds a constructor or serializer that doesn't set it.
- Both sides add an entry to the same registry/enum/config with the same key in different places.
- One side adds a test that pins behavior the other side deliberately changed.

The cheap detection is the project's build and test suite (skill step 8) plus a targeted grep for every identifier either side renamed. Say plainly in the report when the project offers no way to check this.
