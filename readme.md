Interactive code: \
https://replit.com/@alexandresouto/rpncalc#main.cr


A Reverse Polish Notation Calculator, with expression/macro functionality.  

<h1> All Operators: </h1>

Math: [+] [-] [*] [/] [**|pow] [%|mod] sq sqrt [opo|neg] inv floor ceil sum mult max min rand(0~1) randi(0 to \<N-1>) \

Math (1 operator): sq sqrt [ln|log] [neg|opo] inv floor ceil \
Math (2 operators): [+] [-] [*] [/] [**|pow] [%|mod] log_ \
Math (N operators): sum mult max min \
Random Numbers: 'rand' returns a random float 0~1, 'randi' returns a random integer 0~(N-1) \
Stack Handling: dup cpy cpyn cpyto pop del deln [clr|clear] [swp|swap]  \
Qtty of numbers in the line until the comma: [,]   </br>
Stack size: [.|qtt|qtty]  
Create Expression: { \<w1> \<w2> \<w3> ... } \<name>  
List Expressions: expr or expri(for indexes) </br>
Delete Expression: \<N> delxpr  </br>
Repeat \<w1> N times: repeat_\<w1>  
Execute \<w1> or \<w2> conditionally: doif_\<w1>_\<w2>   
Set a variable \<w1>: set_\<w1>   Example: 5 set_x </br> 
Help: [help|cmds]   
Exit: [exit|out] 

<h2>There are two programming Operators: repeat_value1 and doif_value1_value2 </h2>
  
Values can be Numeric Values, Operators, or Expressions
  
repeat_value1 consumes the last value as a quantity N  </br>
And apply value1 N times in the stack  </br>
  
doif_value1_value2 consumes the last value as a condition  </br>
Any positive number is considered true, otherwise it is considered false  </br>
if true apply value1 on the stack, if false apply value2 on the stack  </br>
_value2 is optional  </br>
_value1 can be omited with a doif__value2
  
<h2> Definining expressions example:  </h2>
  Type "{ 2 * } double" to define the "double" expression</br>
  With the stack "[5]", typing "double" results in "[10]" </br>
  With the stack "[10]", typing "8 + double" results in "[36]" </br>
