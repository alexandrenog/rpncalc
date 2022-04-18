Interactive code: \
https://replit.com/@alexandresouto/rpncalc#main.cr


A Reverse Polish Notation Calculator, with expression/macro functionality.  \
And two programming commands: repeat_value1 and doif_value1_value2
  
Values can be Numeric Values, Operators, or Expressions
  
Usage of repeat:  \
[] |  5 repeat_1 \
[1 1 1 1 1] | 2 repeat_+  \
[1 1 3] 
  
repeat_value1 consumes the last value as a quantity N  \
And apply value1 N times in the stack  \
Usage of doif:  \
[3 4 1] | doif\_+\_*  \
[7] | 8 -1 doif\_+\_*  \
[56] | 2 0 doif\_+\_*  \
[112] | 9 doif_dup  \
[112 112]
  
doif_value1_value2 consumes the last value as a condition  \
Any positive number is considered true, otherwise it is considered false  \
if true apply value1 on the stack, if false apply value2 on the stack  \
_value2 is optional  \
_value1 can be omited with a doif__value2
  
 Definining expressions, example:  \
  \{ 2 * \} double </br>
  [5] | double  \
  [10] | 8 + double  \
  [36]
  
