---
type: llm
focus: trace
---
PASS if, near the end of the run (after the last code change), the agent ran the project's full test
suite (`make test` or `python3 -m unittest discover -s tests`) and every test it added passed. A
pre-existing failure in tests/test_legacy.py, if present, does not count against this. FAIL if no full
suite run follows the last code change, or a test the run added fails in it.
