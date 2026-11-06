---
name: commit-message
description: Defines how git commits should be handled — what to stage, how to format the message, and how to run the commit. Use this skill whenever the user asks to commit changes, make a commit, or write a commit message — even if they don't mention formatting or staging. This ensures commits only include relevant changes and follow the user's preferred message style.
---

# Commit Workflow

**Repo conventions win.** If the repository defines its own commit conventions — in `CLAUDE.md`, `CONTRIBUTING.md`, a commit template, or similar — follow those wherever they conflict with this skill. This skill is the default, not an override.

## What to stage

The working tree often contains changes unrelated to the current task — manual tweaks for local development (e.g. hardcoding a localhost URL), dependency file changes from `npm install`, editor configs, or experiments the user hasn't mentioned. Committing these by accident can break shared repos or pollute the history, and reversing a bad commit on a shared branch is painful. Being selective about staging is worth the extra few seconds.

- **Stage files by name, not by wildcard.** Don't use `git add .`, `git add -A`, or `git add --all`. These sweep up everything, including changes you didn't make and shouldn't commit.
- **Only stage files you changed** as part of the current task. If you didn't create or modify a file during this conversation, don't stage it — even if `git status` shows it as modified or untracked. Those changes belong to the user's other work.
- **Review diffs before staging.** Run `git diff <file>` for each file you plan to stage. If a file contains a mix of your task-related changes and unrelated edits (e.g. the user manually tweaked a config value in the same file you refactored), don't stage the whole file. Instead, tell the user what you found and let them decide — they may want to split the commit or revert their local tweak first.
- **Don't assume pre-staged changes are intentional.** If files are already staged when you begin, review them with `git diff --cached`. They may be leftovers the user staged earlier for a different purpose.
- **Never stage secrets or credentials — even files you created.** A `.env` written for a test run, a token pasted into a fixture, a private key, or a cloud config with an embedded credential must not be committed. If such a file is part of what you changed, leave it unstaged and tell the user.
- **Split unrelated work.** If the changes you made serve two or more independent concerns (e.g. the feature the user asked for plus an unrelated bug you fixed along the way), don't fold them into one commit. Stop before staging, tell the user what you found, propose one commit per concern with the files each would contain, and wait for their answer.
- **When in doubt, ask.** Under-staging is easy to fix (`git add` one more file). Over-staging can mean an unwanted change lands on a shared branch and causes problems downstream.

## Commit message format

### What the message is based on

- **The staged diff is the source of truth for *what* changed.** Read `git diff --cached` before writing the message and describe what is actually in it — not what you remember doing, and not changes that ended up unstaged.
- **The conversation is the source for *why*.** Use what the user asked for, the problem they described, and the reasoning behind decisions to explain motivation. Don't restate the request itself or narrate the exchange.
- **Describe the end state, not the journey.** If you tried one approach and replaced it with another, describe only the final approach. No "switched from X to Y" unless X was already in the codebase.

### Title line

- Write in **present-tense imperative mood** ("Add", "Fix", "Remove" — not "Added", "Fixes", "Removed")
- Keep it under **80 characters**; shorter is better when it costs no meaning
- Use **plain language** that describes the change at a human level. Avoid code-like references in the title (write "user list endpoint" not "`/api/users`", write "settings page" not "`SettingsPage.tsx`")
- When it adds clarity, hint at the **why** — not just what changed but what problem it solves (e.g. "Paginate user list to fix memory issues on large datasets")
- No conventional commit prefixes (`feat:`, `fix:`, `chore:`, etc.)
- No trailing period
- No emoji
- Sentence case (capitalize the first word only, unless a proper noun follows)

### Message body

The body is for someone who reaches this commit through `git blame`, `git bisect`, or `git log -S`: they are already looking at the code and want to know what the change does and why. The diff carries the implementation.

- **Omit the body when the title says it all.** A typo fix, a one-line config change, or a rename needs no bullets. A body that only restates the title is noise.
- **Select changes.** A change earns a bullet when that reader would want to know it before opening the diff, or would misread the diff without it. Breaking changes, migrations, and required deploy steps always earn one. Fold mechanical edits — call-site updates, follow-on renames, renumbering, test fixes, version bumps — into the change they support.
- **Size the body to the change.** A small fix gets a bullet or two; a larger change gets more. Collapse related changes into one bullet so the count tracks distinct changes, not files or lines touched.
- **Write flat bullets by default.** A commit usually holds one concern (see "Split unrelated work"), which a flat list covers. Group only when the change spans several distinct areas that each have more than one change worth a bullet: the top-level bullet names the area and nested bullets give its changes, while single-change areas sit alongside as flat bullets.
- **One sentence per bullet**, describing one change in present-tense imperative mood, matching the title. Run to a second sentence only when one can't carry something critical, such as a breaking change's migration path.
- Add the **why** as a short clause when the reason isn't obvious.
- **Name the code a reader would search history for** — functions, parameters, config keys, tables, values that drove a decision. Describe what the diff already shows plainly in a few words, or not at all.
- Separate the body from the title with a blank line, use bullet points (` - ` prefix), and wrap lines at ~72 characters for readability in terminals
- No emoji

### Examples

**Example 1** — Why-oriented title, two bullets:
```
Paginate user list endpoint to fix memory issues on large datasets

- Replace the unbounded query with cursor pagination (`cursor` and
  `limit` params, default 50, `next_cursor` in the response)
- Add an index on `users.created_at` so paging doesn't scan the table
```

**Example 2** — Bug fix, one bullet carrying the cause:
```
Fix dark mode not persisting across page reloads

- Read the saved theme on mount instead of always starting in light
  mode, falling back to `prefers-color-scheme` when none is saved
```

**Example 3** — Change touching many files, with a breaking step:
```
Apply the upload size limit to all attachment types

- Rename `MAX_IMAGE_UPLOAD_MB` to `MAX_ATTACHMENT_MB` and enforce it
  for documents and video, which previously had no limit
- Rename the env var in each deployment before upgrading; the old
  name is no longer read
```

**Example 4** — One concern spanning several areas, grouped:
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

**Example 5** — Self-explanatory change, title only:
```
Fix typo in onboarding email subject line
```

## Making the commit

- **Pass the message through a quoted heredoc** so backticks and `$` in the body are never interpreted by the shell:
  ```bash
  git commit -m "$(cat <<'EOF'
  Title line

  - Body bullet
  EOF
  )"
  ```
- **Don't bypass safeguards.** Never pass `--no-verify`. Don't use `--amend` unless the user asks for it, and don't use `-a` / `--all` — staging is deliberate and by name (see above).
- **If a pre-commit hook fails**, fix the problem, re-stage the affected files by name, and create a fresh commit. Don't skip the hook and don't amend.
- **Verify the result.** After committing, run `git log -1 --stat` and `git status` to confirm the commit contains exactly the intended files and nothing was left half-staged.
