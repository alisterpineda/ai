# Resolving the target

The target argument is a short string that could name several different things. Classify it by judgment, fetch it, and echo the resolved title before doing anything else. Everything here is read-only: fetch, never write, never close or comment.

## Classification

Work down this table; first match wins.

| Argument looks like | Kind | Resolve by |
|---|---|---|
| `conversation`, `plan`, `this`, or no argument at all | conversation | The plan is the one agreed earlier in this session. Restate it in your own words as the target text; if the session holds no such plan, stop and say so. |
| An existing file path | file | Read it. Markdown, plain text, or anything readable. |
| An existing directory path | directory | Read every `*.md` file in it (non-recursive first; descend only into subfolders whose names suggest spec content). The file named like a spec (`spec`, `SPEC`, `README`, the directory's own name) is primary; the rest are supporting notes and ADRs. If no name stands out, the largest file is primary. |
| `https://github.com/<owner>/<repo>/issues/<n>` or `<owner>/<repo>#<n>` | github | `gh issue view <n> --repo <owner>/<repo> --comments` (JSON via `--json title,body,comments,state,labels` when you need structure). Comments are part of the spec: refinements and "also handle X" live there. |
| `https://dev.azure.com/<org>/<project>/_workitems/edit/<id>`, or the `<org>.visualstudio.com` form | ado | See *Azure DevOps* below. Parse org, project, and id from the URL. |
| `#<n>` or a bare number | ambiguous | See *Bare numbers* below. |
| Anything else | unresolved | Stop. Say what you saw and ask for a file path, a GitHub issue reference, or an Azure DevOps URL. |

## Bare numbers

`#42` names an issue on *some* tracker, and a fresh session has no memory of which. Guess from the environment, in this order, and stop at the first that gives an answer:

1. **Remote host.** `git remote -v`. A `github.com` remote means GitHub, resolved against that remote's `<owner>/<repo>`. A `dev.azure.com` or `visualstudio.com` remote means Azure DevOps, with org and project taken from the remote URL (`dev.azure.com/<org>/<project>/_git/<repo>`, or `<org>.visualstudio.com/<project>/_git/<repo>`; a project with spaces is URL-encoded).
2. **Exactly one reachable tracker.** No informative remote, but `gh auth status` succeeds and the repo has a GitHub remote, or an Azure DevOps work-item tool is available. Use the one that is reachable.
3. **Neither, or both.** Ask the user for the full URL. Do not resolve a bare number against a todo file, a checklist, or any numbered list in the conversation.

## Azure DevOps

No specific client is assumed. Use, in order of preference, whichever is present:

- An MCP tool that reads work items (its name will mention Azure DevOps, ADO, or work items). Fetch the item by id; read title, description, acceptance criteria, and the discussion thread.
- The `az` CLI with the `azure-devops` extension: `az boards work-item show --id <id> --org https://dev.azure.com/<org>` and, for discussion, `az boards work-item relation show` or the REST endpoint through `az rest`.
- **Neither present**: ask the user to paste the work item — title, description, acceptance criteria, and any relevant discussion — and wait. Do not proceed on the id alone.

Work-item fields arrive as HTML. Read through the markup; the acceptance-criteria field, when populated, is taken verbatim into `criteria.md`.

## Children and linked items

The target is the unit of work for this run. A ticket's child tasks, sub-issues, or task-list checkboxes are context, not automatically scope. Decide from their content: children that merely decompose the target's own acceptance criteria are already covered; children that add distinct requirements are a scope question. Put scope questions to the user once, in step 5 of the skill, together with any other scope questions. Linked items that are blocked-by or related are read for context only.

## Echo

Once the text is in context, print one line before any other output:

```
Implementing: <title> (<kind>: <normalized ref>)
```

where the ref is the path, `<owner>/<repo>#<n>`, `<org>/<project>#<id>`, or `conversation`. Include the item's state when the tracker reports one; an already-closed item is worth the user noticing.
