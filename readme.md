Interactive code: \
https://replit.com/@alexandresouto/rpncalc#main.cr


A Reverse Polish Notation Calculator, with expression/macro functionality.  

Operators:

Math: [+] [-] [*] [/] [**|pow] sq sqrt [opo|neg] inv sum mult max min rand(0~1) randi(0 to \<N-1>) \
Stack Handling: dup cpy cpyn cpyto pop del deln [clr|clear] [swp|swap]  \
Qtty of numbers in the line until the comma: [,]   \
Stack size: [.|qtt|qtty]  
Create Expression: { \<w1> \<w2> \<w3> ... } \<name>  
List Expressions: expr or expri(for indexes) \
Delete Expression: \<N> delxpr  \
Repeat \<w1> N times: repeat_\<w1>  
Execute \<w1> or \<w2> conditionally: doif_\<w1>_\<w2>   
Help: [help|cmds]   
Exit: [exit|out] 

There are two programming Operators: repeat_\<value1> and doif_\<value1>_\<value2>
  
Values can be Numeric Values, Operators, or Expressions
  
repeat_value1 consumes the last value as a quantity N  \
And apply value1 N times in the stack   \
  
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
