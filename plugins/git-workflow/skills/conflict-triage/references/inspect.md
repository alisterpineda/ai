# Inspecting a hunk you can't read off the file

Load this when the markers alone do not explain what a side was trying to do. Everything here leaves **the user's** working tree and index untouched, which is what makes it safe in Phase 1 — the scratch-file and scratch-worktree techniques write only under a `mktemp -d` path. The one command that writes to the user's own tree is called out at the bottom as Phase-2-only.

## The three stages

```sh
git ls-files -u -- <path>          # which stages exist, with modes and OIDs
git show :1:<path>                 # merge base
git show :2:<path>                 # ours   (HEAD right now)
git show :3:<path>                 # theirs (the change being applied)
git rev-parse :1:<path>            # just the blob OID
```

A missing stage is a diagnosis, not a failure: no stage 1 = add/add (no common ancestor), no stage 3 = they deleted it, no stage 2 = we deleted it.

## Rendering the conflict with the base inline

Non-destructive, does not touch the file:

```sh
git merge-file --object-id -p --zdiff3 \
  "$(git rev-parse :2:<path>)" "$(git rev-parse :1:<path>)" "$(git rev-parse :3:<path>)"
```

Argument order is `<current> <base> <other>` — ours, base, theirs. `-p` writes to stdout instead of a file. `--zdiff3` keeps the common leading/trailing lines outside the markers and shows the base section between `|||||||` and `=======`, which is what makes a conflict readable: you can see what each side *changed*, not just what each side *has*.

`--object-id` requires git ≥ 2.44. Fallback for older git — write the stages to scratch files first (a temp directory, never the repo):

```sh
d=$(mktemp -d)
git show :1:<path> > "$d/base"; git show :2:<path> > "$d/ours"; git show :3:<path> > "$d/theirs"
git merge-file -p --zdiff3 "$d/ours" "$d/base" "$d/theirs"
rm -rf "$d"
```

## Diffing the sides against each other

```sh
git diff :1:<path> :2:<path>     # what we changed, relative to the base
git diff :1:<path> :3:<path>     # what they changed, relative to the base
git diff :2:<path> :3:<path>     # the two sides head to head
```

The first two are the ones that matter. Two sides "conflicting" often turn out to be one side doing something and the other doing nothing meaningful to that region — the base-relative diffs make that obvious in a way the markers do not.

Shorthands for the same thing against the working tree:

```sh
git diff --ours   -- <path>      # working tree vs stage 2
git diff --theirs -- <path>      # working tree vs stage 3
git diff --base   -- <path>      # working tree vs stage 1
```

Note that a bare `git diff -- <path>` on an unmerged entry produces a **combined diff**, which is a different format and is easy to misread as an ordinary diff. Prefer the explicit forms above.

## Intent — what were the two sides doing?

Text says what changed; commits say why.

```sh
git log --merge -p -- <path>     # commits on either side that touched this file
git log --merge --oneline -- <path>
```

`--merge` works during merge, rebase, cherry-pick, and revert (it uses `MERGE_HEAD`/`REBASE_HEAD`/etc.). It does **not** work during a stash pop — there is no other side to name. For a stash pop, use `git stash show -p 'stash@{0}'` instead.

Explicit ranges, when `--merge` is unavailable or too broad:

```sh
base=$(git merge-base HEAD MERGE_HEAD)
git log --oneline "$base"..HEAD        -- <path>    # our side's commits
git log --oneline "$base"..MERGE_HEAD  -- <path>    # their side's commits
```

For a rebase, substitute `REBASE_HEAD` for `MERGE_HEAD`; for a cherry-pick, `CHERRY_PICK_HEAD`. Reading the *commit messages* on both sides resolves more conflicts than reading the diffs does.

## Pinpointing a specific hunk's origin

```sh
git log -L <start>,<end>:<path> <rev>      # the evolution of exactly these lines
git log -S '<string>' --oneline -- <path>  # commits that added or removed a string
git log -G '<regex>' --oneline -- <path>   # commits whose diff matches a regex
git blame <rev> -- <path>                  # blame a specific side: :2: or :3: won't work, use MERGE_HEAD/HEAD
```

`git log -L` is the strongest of these for a conflict: it answers "who last touched these exact lines and why" on either side, which is usually the whole question.

## `AUTO_MERGE` — what git itself produced

With the `ort` merge strategy (default since 2.34), git writes the tree it auto-merged, markers and all, to the `AUTO_MERGE` ref:

```sh
git rev-parse -q --verify AUTO_MERGE     # present?
git diff AUTO_MERGE                      # what you changed on top of git's auto-merge
git show AUTO_MERGE:<path>               # git's auto-merged version of one file
```

`git diff AUTO_MERGE` is the single most useful verification command in Phase 2: it shows **exactly** what the resolution added on top of what git could do by itself, with the auto-merged parts of the file subtracted out. A resolution that shows unexpected changes there touched something it shouldn't have.

`AUTO_MERGE` is written by `ort`, which is the default strategy and which modern git also routes `recursive` to — and a conflicted `git stash pop` writes it as well, which matters because that is the one operation with no `--continue` to fall back on. It is still not guaranteed, so probe with `git rev-parse -q --verify AUTO_MERGE` (above) rather than assuming it either way.

## rerere

```sh
git rerere status      # paths rerere is tracking for this conflict
git rerere remaining   # unmerged paths rerere did NOT auto-resolve
git rerere diff        # what rerere changed, per path
```

`remaining` is the important one — **but only once rerere is known to be on.** rerere is disabled by default, and a disabled `git rerere remaining` prints nothing and exits 0, so the rule below would flag every conflicted file. Check `git config --get rerere.enabled` or `[ -d "$(git rev-parse --git-path rr-cache)" ]` first; empty output from an inactive rerere means the rule does not apply. When it is on: anything in `git diff --name-only --diff-filter=U` but *not* in `git rerere remaining` was auto-resolved from a previous conflict — the file is clean, unreviewed, and still unmerged in the index.

## Size and encoding checks

```sh
git cat-file -s "$(git rev-parse :2:<path>)"   # blob size in bytes
file <(git show :2:<path>)                     # type sniffing
git ls-files -s -- <path>                      # modes: 100644, 100755, 120000 (symlink), 160000 (submodule)
```

Worth doing before reading a stage in full — a 2 MB minified bundle or a `160000` gitlink is a different problem than a text conflict, and reading it as text wastes the attempt.

## Building a comparison without touching the worktree

When the sides genuinely need to be run or built to be understood, use a scratch worktree — never the user's:

```sh
d=$(mktemp -d)
git worktree add --detach "$d" <rev>
# ... inspect / build in "$d" ...
git worktree remove --force "$d"
```

## The command that is Phase-2 only

```sh
git checkout --conflict=zdiff3 -- <path>     # WRITES the file from the index stages
```

It re-creates the conflict markers in the file, now with the base section included — genuinely useful when the original markers were `diff3`-less and hard to read. But it **overwrites the working-tree file and discards any edits already made to it**, which is why it never runs in Phase 1. In Phase 2 it is safe only as the *first* action on a path that is still unmerged, before any editing has started on it.

The read-only equivalent, and the reason it is rarely needed, is the `git merge-file --object-id -p --zdiff3` invocation at the top of this file.
