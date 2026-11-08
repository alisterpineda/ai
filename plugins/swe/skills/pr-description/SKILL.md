---
name: pr-description
description: "Write a pull-request title and description from the diff between a source and target branch. Use whenever the user asks for a PR title, description, or summary, even casually (\"write me a PR\", \"what should the PR say\")."

# Maintainer notes (hosts that strip frontmatter never show these to the model):
# - The description is written from the cumulative diff and describes the net
#   result, because reviewers and later readers see the merged state, not the
#   commits that got there.
# - The diff is taken against `origin/<target>` because the branch was cut from
#   a fetched remote state, and remote-tracking refs only move forward: the
#   merge base is then the real branch point without a fetch. A stale local
#   target puts upstream commits into the diff.
# - The Changes list is short, selective, and light on code names, with one
#   example per size tier, because earlier examples steered output toward
#   identifier-heavy nested lists (2eebac7).
# - "No emoji" in the title and description was cut as default behavior: Opus
#   doesn't add emoji to PR text unprompted. Restore it if runs start to.
---

# PR description

## 1. Pick the branches

- Source: the current branch (HEAD), unless the user names another.
- Target: the branch the user names. Otherwise the remote's default branch, from `git symbolic-ref --short refs/remotes/origin/HEAD`; when that fails, `main`, or `master` when `main` doesn't exist.
- Compare against the target's remote-tracking branch (`origin/<target>`) when it exists, not the local branch: a local `main` that lags behind `origin/main` pulls other people's merged commits into the diff. Don't fetch.
- Confirm which branches you're comparing if there's any ambiguity.

The branches are picked when `git rev-parse --verify` succeeds for both.

## 2. Read the net change

- Run `git diff <target>...<source>`, `git diff --stat <target>...<source>`, and `git log --oneline <target>..<source>`. The diff is the source of truth; the log only gives narrative context.
- When the diff is large, read the key changed files directly to see what surrounds the changed code.
- Describe the state after merging: a function added and later renamed is described only under its final name, and a file edited back and forth only by its net change. Refer to no commits or commit hashes.

This step is done when you can say what every file in `--stat` contributes to the net change.

## 3. Write the title

- Start with the verb in present-tense imperative mood ("Add", "Fix", "Remove"), with no type prefix such as `feat:` or `fix:`.
- Sentence case, under 60 characters when possible, no trailing period.
- Name things in plain words: "user authentication", not "`AuthService.ts`".
- When it adds clarity, hint at the why.

## 4. Write the description

### Summary

Two to four sentences on what the PR does and why, enough for someone skimming PRs to understand its motivation and scope. Start with what it does ("Replaces the unbounded query…"), not with "This PR".

### Changes

A short bullet list for a reviewer about to open the diff, and for someone reading the PR months later. The diff carries the implementation; each bullet tells the reader what changed in behavior or capability.

**Selecting changes.** A change earns a bullet when a reviewer would be surprised not to be told about it, or would read the diff differently knowing it. Breaking changes, migrations, and required deploy steps always earn one. Fold mechanical edits (call-site updates, follow-on renames, test fixes) into the change they support.

**Sizing the list.** Size by the number of distinct concerns, not files or lines changed: a 2,000-line rename is one concern.

| PR | Shape |
|---|---|
| One concern | 1–3 flat bullets |
| 2–3 concerns | 3–6 flat bullets |
| Several distinct areas | Grouped: 2–3 groups of 2–3 nested bullets, plus flat bullets for single-change areas |

Hard cap at any size: 6 top-level bullets and 15 bullets in total, counting group headings. When the selected changes exceed it, describe them at a higher level, collapsing related changes into one bullet, until the list fits, and add the split note (see Output format).

**Structure.** Write a flat list by default. Group only when several distinct areas each have more than one change worth a bullet: the top-level bullet names the area and the nested bullets say what changed in it, without restating the area. Write an area with a single change as one flat bullet alongside the groups. Order by importance or logical flow.

**Wording.**
- One sentence per bullet, describing one change, in present-tense imperative mood matching the title. Run to a second sentence only when a single sentence can't carry something critical, such as a breaking change's migration path.
- Add the why as a short clause when the reason isn't obvious.
- Name code only when the reader will type, call, configure, or search for it: endpoints, CLI flags, config keys, env vars, public API names, table and migration names. Describe internal names (private functions, classes, variables) by what the code does.

The description is done when the list fits the cap and its size tier, and no group has a single nested bullet.

## Output format

Present the title on its own line, then the description in a markdown codeblock:

```
<the PR title>
```

````markdown
## Summary

<2-4 sentences on what and why>

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

Only when the selected changes exceeded the hard cap, add one line after the codeblock, addressed to the user and not part of the PR, noting that the PR spans N separate concerns and could be split.

## Examples

**Example 1** — Small (one concern):

```
Fix dark mode not persisting across page reloads
```

````markdown
## Summary

Restores the saved theme on page load, falling back to the operating system's color scheme when none is saved. The dark mode toggle had reset to light mode on every reload because the component always initialized with the default value instead of reading the stored preference.

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
