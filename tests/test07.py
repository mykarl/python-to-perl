#!/usr/bin/python3

lines = [1, 2, 3, 4, 5, 6, 7, 8, 9]
i  = len(lines + lines) +len("me") + len(lines) - 1 + len("")
j = len("hello")

k = int("5") + int(5)
string = "string"
print (len("string"))

print ("%d %s length, %d integer sum" % (i+j, string, k), end = ' end\n')

a = [3, 6, 8, 2, 78, 1, 23, 45, 9]
b = sorted(a)
print (b)
print (sorted(a))
