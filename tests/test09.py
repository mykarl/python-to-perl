#!/usr/bin/python3
# Count the number of lines on standard input.

import sys

lines = sys.stdin.readlines()
line_count = len(lines)
print("%d lines" % line_count)
