#!/usr/bin/python3
# Print line from stdin in reverse order

import sys

lines = []
for line in sys.stdin:
    lines.append(line)
    
i = len(lines) - 1
while i >= 0:
    print(lines[i], end='')
    i = i - 1
