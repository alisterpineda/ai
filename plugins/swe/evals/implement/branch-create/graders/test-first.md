---
type: regex
target: trace
pattern: '(FAILED \((failures|errors)=\d+[^)]*\)|(FAIL|ERROR): test_\w+)[\s\S]*(\\n|")OK(\\n|")'
---
