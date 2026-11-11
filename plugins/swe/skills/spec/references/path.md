# Where swe writes its files

- **Directory**: the location for specs named in the repo's `CLAUDE.md` or `AGENTS.md`, if any. Otherwise the scratch directory.
- **Scratch directory**: `.local/` at the git repo root when it already exists, git already ignores it (`git check-ignore -q .local/` succeeds), and there is no `.scratch/`. Otherwise `.scratch/` at the git repo root, or in the current directory outside a repo.
- **`.scratch/`**: before writing anything into it, create `.scratch/` if it is missing. Then, unless git already ignores it (`git check-ignore -q .scratch/` succeeds), make sure it holds a `.gitignore` whose content is `*`, creating the file if needed. Either way, nothing written there shows in `git status`, a diff, or a review. Never add a `.gitignore` to `.local/`.
- **Filename**: `YYYYMMDD-<slug>-<kind>.md`, with today's date and the kind your skill names (`spec`, `plan`). The slug is two to five kebab-case words, from the context or the subject.
- **Every run writes a new file.** If the name is taken, append `-2`, `-3`, and so on before `.md`.
