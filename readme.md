Interactive code: \
https://replit.com/@alexandresouto/rpncalc#main.cr


A Reverse Polish Notation Calculator, with expression/macro functionality.  

Operators:

Math: [+] [-] [*] [/] [**|pow] sq sqrt opo inv sum mult max min \
Stack Handling: dup cpy cpyn cpyto pop del deln [clr|clear] [swp|swap] \
Qtty of numbers in the line until the comma: [,]  Stack size: [.|qtt|qtty] \
Create Expression: { \<w1> \<w2> \<w3> ... } \<name>   List Expressions: expr \
Repeat \<w1> N times: repeat_\<w1> \
Execute \<w1> or \<w2> conditionally: doif_\<w1>_\<w2> \
Exit: [exit|out] \
Help: [help|cmds] \


There are two programming Operators: repeat_\<value1> and doif_\<value1>_\<value2>
  
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
