---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?git\s+add\b(?:[^"\\|;&]|\\[^n])*?(?:\s|\\"|''|/)\.env(?![\w.-])|"command"\s*:\s*"(?:[^"\\]|\\.)*?git\s+commit\b[^"\\|;&$<'']*?(?:\s|/)\.env(?![\w.-])|git\s+add\s+(?:\.(?=[\s"'']|$)|-A\b|--all\b|-u\b|--update\b)|git\s+commit\b[^|;&]*?(?:\s-[a-zA-Z]*a[a-zA-Z]*\b|\s--all\b)'
min: 0
max: 0
---
