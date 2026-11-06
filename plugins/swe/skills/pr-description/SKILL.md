---
name: pr-description
description: Generates a pull-request title and description based on the diff between a source and target branch. Use this skill whenever the user asks to create, write, draft, or generate a PR title, PR description, pull request message, or pull-request summary — even if they phrase it casually like "write me a PR" or "what should the PR say". This is the go-to skill for any PR content generation task.
---

# PR Description Generator

Generate a pull-request title and formatted description by analyzing the full diff between a source and target branch. The goal is to communicate the **end result** of the changes clearly — not a play-by-play of individual commits.

## Step 1: Determine the branches

- **Source branch**: Use the current branch (HEAD) unless the user specifies otherwise
- **Target branch**: Use the branch the user specifies. If they don't, default to `main` — if `main` doesn't exist, fall back to `master`

Confirm which branches you're comparing if there's any ambiguity.

## Step 2: Gather the full context

Run these git commands to understand the complete picture:

```bash
# The cumulative diff — this is your primary source of truth
git diff <target>...<source>

# Commit history for narrative context
git log --oneline <target>...<source>

# See which files changed and how much
git diff --stat <target>...<source>
```

Read the diff carefully. When the diff is large, also read the key changed files directly to understand the broader context (what the file does, what surrounds the changed code).

**Focus on the end result, not the journey.** If a function was added in one commit and renamed in a later commit, describe only the final state. If a file was modified back and forth across commits, describe only the net change. The PR description should reflect the state of the world after merging — not the sequence of events that got there.

## Step 3: Write the title

Follow the same style as a good commit message title:

- **Present-tense imperative mood** ("Add", "Fix", "Remove" — not "Added", "Fixes")
- Keep it under 60 characters when possible
- **Plain language** — describe the change at a human level, avoid code references in the title (write "user authentication" not "`AuthService.ts`")
- Hint at the **why** when it adds clarity
- No conventional commit prefixes (`feat:`, `fix:`, etc.)
- No trailing period
- Sentence case

## Step 4: Write the description

Structure the description as a markdown codeblock with two sections:

### Summary

A short paragraph (2-4 sentences) that explains what this PR does and why. This is the "elevator pitch" — someone skimming PRs should understand the motivation and scope from this alone.

### Changes

A short bullet list for a reviewer about to open the diff, and for someone reading the PR months later. The diff carries the implementation detail; each bullet tells the reader what changed in behavior or capability.

**Selecting changes.** A change earns a bullet when a reviewer would be surprised not to be told about it, or would read the diff differently knowing it. Breaking changes, migrations, and required deploy steps always earn one — they affect people who never open the diff.

**Sizing the list.** Size by the number of distinct concerns, not lines changed — a 2,000-line rename is one concern.

| PR | Shape |
|---|---|
| One concern | 1–3 flat bullets |
| 2–3 concerns | 3–6 flat bullets |
| Several distinct areas | Grouped: 2–3 groups of 2–3 nested bullets, plus flat bullets for single-change areas |

Hard cap at any size: 6 top-level bullets and 15 bullets in total, counting group headings. When the selected changes exceed it, describe them at a higher level, collapsing related changes into one bullet, until the list fits — and add the split note (see Output format).

**Structure.** Write a flat list by default. Group only when several distinct areas each have more than one change worth a bullet: the top-level bullet names the area and the nested bullets give its changes. Areas with a single change sit alongside the groups as flat bullets. Order by importance or logical flow.

**Wording.**
- One sentence per bullet, describing one change, in present-tense imperative mood matching the title. Run to a second sentence only when a single sentence can't carry something critical, such as a breaking change's migration path.
- Add the why as a short clause when the reason isn't obvious.
- Name code only when the reader will type, call, configure, or search for it: endpoints, CLI flags, config keys, env vars, public API names, table and migration names.

## Output format

Present the result as:

1. The **title** on its own line
2. A **markdown codeblock** containing the formatted description
3. **Only when the selected changes exceeded the hard cap:** one line after the codeblock, addressed to the user and not part of the PR, noting that the PR spans N separate concerns and could be split

Like this:

```
<the PR title>
```

````markdown
## Summary

<2-4 sentence summary of what and why>

## Changes

- <Change>
- <Change, with why if the reason isn't obvious>
````

A grouped list for a PR spanning several areas:

````markdown
- <Area>
  - <Change>
  - <Change>
- <Area>
  - <Change>
  - <Change>
- <Single change from another area>
````

## Examples

**Example 1** — Small (one concern):

```
Fix dark mode not persisting across page reloads
```

````markdown
## Summary

The dark mode toggle reset to light mode on every page reload because the component always initialized with the default value instead of reading the stored preference. The theme now loads from the saved preference, falling back to the operating system's color scheme when none is saved.

## Changes

- Restore the saved theme on page load instead of always starting in light mode
- Fall back to the operating system's color scheme when no preference is saved
````

**Example 2** — Medium (2–3 concerns):

```
Add cursor-based pagination to the user list API
```

````markdown
## Summary

Replaces the unbounded query in the user list endpoint with cursor-based pagination. The previous implementation loaded all users into memory, causing OOM errors for organizations with large datasets.

## Changes

- Paginate the user list endpoint with `cursor` and `limit` parameters (default 50)
- Add an index on `users.created_at` so paging doesn't scan the whole table
- Auto-paginate in the SDK's `listUsers()` and add `iterateUsers()` for large result sets
````

**Example 3** — Large (several distinct areas):

```
Add SAML single sign-on for organization accounts
```

````markdown
## Summary

Lets organization admins set up SAML single sign-on so members log in through their company's identity provider instead of managing a separate password. Password login stays available unless an admin enforces SSO.

## Changes

- Login
  - Add a SAML login flow at `/auth/saml/{org}` that creates accounts on first login for the org's verified domain
  - Reject password login for orgs that enforce SSO, pointing users to their SSO login page
- Admin settings
  - Add an SSO page where admins upload their identity provider's metadata and test the connection
  - Add an "Enforce SSO" toggle, available only after a successful test login
- Add the `sso_connections` table and `orgs.sso_enforced` column — run the migration before deploying
- Require a new `SAML_SP_PRIVATE_KEY` env var for signing SAML requests — set it before deploying
````

## What to leave out

- No emoji in the title or description
- Don't list every file that changed — group by logical concern
- Don't describe intermediate states or back-and-forth changes — only the net result
- Don't include commit hashes or refer to specific commits
- Don't add boilerplate like "This PR..." at the start of the summary — just state what it does directly
- Internal names (private functions, classes, variables) — describe what the code does instead
- A group with a single nested bullet — write that change as one flat bullet
- One bullet per mechanical edit (call-site updates, follow-on renames, test fixes) — fold them into the change they support
- Nested bullets that restate their group heading — the heading names the area, the bullets say what changed
