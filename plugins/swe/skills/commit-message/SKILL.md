---
name: commit-message
description: "Commit changes: stage the task's files by name, write the message, and run the commit. Use whenever the user asks to commit changes, make a commit, or write a commit message, even if they don't mention staging or formatting."

# Maintainer notes (hosts that strip frontmatter never show these to the model):
# - Staging is by name and limited to the task's files because the working tree
#   often holds the user's local tweaks (a hardcoded localhost URL), `npm install`
#   churn, editor config, and experiments. Under-staging costs one `git add`;
#   over-staging can land an unwanted change on a shared branch.
# - The scope order lets a user commit work they did themselves: a user who
#   stages by hand treats the index as what they've verified, so an index the
#   user scoped to is committed untouched, never re-staged or trimmed.
# - The heredoc is quoted so the shell never expands backticks or `$` in the body.
# - The skill says nothing about attribution trailers on purpose, so the
#   harness's own attribution is kept as supplied (09cea65).
# - The body rules write for a reader arriving from blame or bisect and keep
#   bodies short and selective (137437f).
# - "No emoji" in the title and body was cut as default behavior: Opus doesn't
#   add emoji to commit messages unprompted. Restore it if runs start to.
---

# Commit

When the repository defines its own commit conventions (in `CLAUDE.md`, `CONTRIBUTING.md`, a commit template, or similar), follow them wherever they conflict with this skill.

## 1. Stage the task's changes

The task's changes are the first of these that applies:

1. The scope the user names: files, "what I've staged", "my changes".
2. The files you created or modified during this conversation.
3. When you changed nothing and the user named nothing: what is already staged. With nothing staged, ask which changes to commit.

When the scope is what is already staged, commit the index as it is: run `git diff --cached` to read it, stage and unstage nothing, and go to step 2. Otherwise:

- Stage files by name with `git add <path>`. Never `git add .`, `git add -A`, or `git add --all`.
- Stage only the task's files, even when `git status` shows others as modified or untracked: those belong to the user's other work.
- Run `git diff <file>` for each file before staging it. When a file mixes the task's changes with unrelated edits, leave it unstaged, tell the user what you found, and let them decide.
- If files outside the task are already staged when you start, leave them staged, tell the user, and ask before committing: they may be leftovers the user staged for another purpose.
- Leave secrets and credentials unstaged, even in files you created (a `.env` written for a test run, a token in a fixture, a private key, a cloud config with an embedded credential), and tell the user.
- When the task's changes serve two or more independent concerns (the feature the user asked for plus an unrelated bug you fixed along the way), stop before staging: tell the user, propose one commit per concern with the files each would contain, and wait for their answer.
- When unsure whether a file belongs, ask instead of staging it.

Staging is done when `git diff --cached` shows exactly the task's changes for one concern.

## 2. Write the message

### Sources

- Describe what `git diff --cached` contains, not what you remember doing and not changes left unstaged.
- Take the why from the conversation: what the user asked for, the problem they described, and the reasoning behind decisions. Leave out the request itself and the exchange. When the conversation gives no why, as for changes the user made themselves, leave it out rather than guess.
- Describe the end state. Write "switch from X to Y" only when X was already in the codebase.

### Title

- Start with the verb in present-tense imperative mood ("Add", "Fix", "Remove"), with no type prefix such as `feat:` or `fix:`.
- Sentence case, under 80 characters, no trailing period.
- Name things in plain words: "user list endpoint", not "`/api/users`"; "settings page", not "`SettingsPage.tsx`".
- When it adds clarity, hint at the why: the problem the change solves ("Paginate user list to fix memory issues on large datasets").

### Body

The body's reader arrives through `git blame`, `git bisect`, or `git log -S`: they are already looking at the code and want to know what the change does and why. The diff carries the implementation.

- Omit the body when the title says it all, as for a typo fix, a one-line config change, or a rename.
- Give a change a bullet when that reader would want to know it before opening the diff, or would misread the diff without it. Breaking changes, migrations, and required deploy steps always earn one. Fold mechanical edits (call-site updates, follow-on renames, renumbering, test fixes, version bumps) into the change they support.
- Size the body to the change: one bullet per distinct change, not per file or line touched, so a small fix gets one or two.
- Write flat bullets. Group only when the change spans several distinct areas that each have more than one change worth a bullet: the top-level bullet names the area and nested bullets give its changes, while single-change areas sit alongside as flat bullets.
- Write each bullet as one sentence describing one change, in present-tense imperative mood like the title. Run to a second sentence only when one can't carry something critical, such as a breaking change's migration path.
- Add the why as a short clause when the reason isn't obvious.
- Name the code a reader would search history for: functions, parameters, config keys, tables, values that drove a decision. Describe what the diff already shows in a few plain words, or not at all.
- Separate the body from the title with a blank line, start each bullet with `- `, and wrap lines at ~72 characters.

### Examples

Why-oriented title, two bullets:
```
Paginate user list endpoint to fix memory issues on large datasets

- Replace the unbounded query with cursor pagination (`cursor` and
  `limit` params, default 50, `next_cursor` in the response)
- Add an index on `users.created_at` so paging doesn't scan the table
```

Bug fix, one bullet carrying the cause:
```
Fix dark mode not persisting across page reloads

- Read the saved theme on mount instead of always starting in light
  mode, falling back to `prefers-color-scheme` when none is saved
```

Change touching many files, with a breaking step:
```
Apply the upload size limit to all attachment types

- Rename `MAX_IMAGE_UPLOAD_MB` to `MAX_ATTACHMENT_MB` and enforce it
  for documents and video, which previously had no limit
- Rename the env var in each deployment before upgrading; the old
  name is no longer read
```

One concern spanning several areas, grouped:
```
Add SAML single sign-on for organization accounts

- Login
  - Add a SAML flow at `/auth/saml/{org}` that creates accounts on
    first login for the org's verified domain
  - Reject password login for orgs with `sso_enforced` set
- Admin settings
  - Add an SSO page for uploading identity provider metadata and
    testing the connection
  - Allow enforcing SSO only after a successful test login, so an
    admin can't lock the whole org out
- Add the `sso_connections` table and `orgs.sso_enforced` column;
  run the migration before deploying
```

Self-explanatory change, title only:
```
Fix typo in onboarding email subject line
```

## 3. Commit and verify

- Commit with the message in a quoted heredoc:
  ```bash
  git commit -m "$(cat <<'EOF'
  Title line

  - Body bullet
  EOF
  )"
  ```
- Add `--amend` only when the user asks for it. Never pass `--no-verify` or `-a`/`--all`.
- If a pre-commit hook fails, fix the problem, re-stage the affected files by name, and make a fresh commit.
- Run `git log -1 --stat` and `git status`. The commit is done when it contains exactly the intended files and nothing is left half-staged.
