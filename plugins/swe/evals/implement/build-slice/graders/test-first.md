---
type: regex
target: trace
pattern: '(FAILED \((failures=([2-9]|\d{2,})|[^)]*errors=\d+)[^)]*\)|(FAIL|ERROR): test_(?!every_word)\w+)[\s\S]*FAILED \(failures=1\)'
---
