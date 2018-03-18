#!/usr/bin/python3

import sys

a = 1
b = []

b.append(0)
b.append(1)
b.append(2)
b.append(3)             # 0 -> 1 -> 2 -> 3
b.pop(b[2])             # 0 -> 1 -> 3
b.append([a, 2, 4])     # 0 -> 1 -> 3 -> [1, 2, 4]
b.append(b[2])          # 0 -> 1 -> 3 -> [1, 2, 4] -> 3
b.append(10)            # 0 -> 1 -> 3 -> [1, 2, 4] -> 3 -> 10
print (b[2])            # note: perl counts [1, 2, 4] as seperate elements in the list
print (b[5])            # whereas python treats it as one element

for elem in b:
   print("Array element is:", elem)

c = b[a]
d = c + b[0]
print(d + b[2])

b = ["Hello", "Hi"]
b.pop()
print (b[0])


   
