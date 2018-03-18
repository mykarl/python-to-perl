#!/usr/bin/python3

x = 1
while x <= 10:
   print(x)
   x  =x+2      # bad formatting
   if (x == 7):
      break
   if (x == 3 and not x < 0):
      x = x + 4   # adds four to x
      y = 1
      while y < 5:   print ("hello"); y = y + 1    # prints hello four times

for i in range(5):   # prints 0-4
   print(i)
   
a = 44           
b = 5           
c = 0

c = a | b
print (c)

c = (a ^ b) << 2
print (c)

c = ~(a & b)
print (c)
