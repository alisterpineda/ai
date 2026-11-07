# /// script
# requires-python = ">=3.9"
# ///
"""Estimate how many tokens each skill puts in a model's context.

For every plugins/<plugin>/skills/<skill>/, count the SKILL.md body (Claude
Code strips the frontmatter before the model sees it) and each file under
references/. Tokens are estimated as characters / 3.8, which tracks Claude's
tokenizer closely enough to compare a skill before and after an edit; it is
not an exact count.

Run from anywhere: uv run scripts/skill-tokens.py [plugin ...]
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHARS_PER_TOKEN = 3.8


def tokens(text: str) -> int:
    return round(len(text) / CHARS_PER_TOKEN)


def body(path: Path) -> str:
    text = path.read_text()
    if text.startswith("---"):
        parts = text.split("---", 2)
        if len(parts) == 3:
            return parts[2]
    return text


def main() -> None:
    wanted = set(sys.argv[1:])
    grand = 0
    for plugin in sorted((ROOT / "plugins").iterdir()):
        if wanted and plugin.name not in wanted:
            continue
        skills = sorted((plugin / "skills").glob("*/SKILL.md"))
        if not skills:
            continue
        print(f"{plugin.name}")
        plugin_total = 0
        for skill_md in skills:
            skill = skill_md.parent
            rows = [("SKILL.md", tokens(body(skill_md)))]
            rows += [
                (f"references/{ref.name}", tokens(ref.read_text()))
                for ref in sorted((skill / "references").glob("*.md"))
            ]
            total = sum(n for _, n in rows)
            plugin_total += total
            print(f"  {skill.name:<24} {total:>6}")
            if len(rows) > 1:
                for name, n in rows:
                    print(f"    {name:<34} {n:>6}")
        print(f"  {'total':<24} {plugin_total:>6}")
        grand += plugin_total
    if not wanted or len(wanted) > 1:
        print(f"all {grand:>6}")


if __name__ == "__main__":
    main()
