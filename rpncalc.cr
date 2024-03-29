#crystal build --release rpncalc.cr

class Array(T)
	def <<(arr : Array(T)) : Array(T)
		self.concat(arr)
	end
end
class Deque(T)
	def <<(arr : Array(T)) : Deque(T)
		self.concat(arr)
	end
end

macro backup_from_error
	@stack = backupArr
	@input_queue.clear
end

macro addFromTwo (num)
	consume 2
	stack << {{num}}
end
macro addFromOne (num)
	consume 1
	stack << {{num}}
end

enum Operator
	Sum                             #    1 2 -> 3
	SumN                            #    20 12 17 3 -> 49
	Sub                             #    1 2 -> -1
	Mult                            #    10 2 -> 20
	MultN                           #    4 10 7 3 -> 280
	Div                             #    10 2 -> 5
	Pow                             #    2 3 -> 8
	Sq                              #    2 -> 4
	Sqrt                            #    4 -> 2
	Inv                             #    2 -> 0.5
	Clear                           #    4 10 7 -> 
	Swap                            #    1 2 -> 2 1
	Dup                             #    1 -> 1 1
	Copy                            #    80 19 53 123 4 -> 80 19 53 123 80
	CopyN                           #    80 19 53 123 4 -> 80 19 53 123 80 19 53 123
	CopyTo                          #    80 19 53 123 3 -> 123 80 19 53 123 
	MoveTo                          #    80 19 53 123 3 -> 123 80 19 53  
	Pop                             #    1 2 -> 1
	Del                             #    80 19 53 123 2 -> 80 19 123
	DelN                            #    80 19 53 123 2 -> 80 19 
	CurrQtty    
	StackQtty                       #    80 19 53 123 -> 80 19 53 123 4
	Opposite                        #    1 -> -1
	Max                             #    80 19 53 123 4 -> 123
	Min                             #    80 19 53 123 4 -> 19
	ListExpr	 
	ListExprIdx
	DelExpr 
	Exit 
	RandF	
	RandI 
	PrintQueue
	PrintStack
	Help
	BracketBegin
	BracketEnd
	Floor                          #   1.5 -> 1
	Ceil                           #   1.5 -> 2
	Mod                            #   10 2 -> 0, 11 2 -> 1, 20 7 -> 6
	Ln
	Log
	def self.from_string(value)
		case value
		when "+"
			Sum
		when "sum"
			SumN
		when "-"
			Sub
		when "*"
			Mult
		when "mult"
			MultN
		when "/"
			Div
		when "**", "pow"
			Pow
		when "sq"
			Sq
		when "sqrt"
			Sqrt
		when "inv"
			Inv
		when "clr", "clear"
			Clear
		when "swap"
			Swap
		when "dup"
			Dup
		when "cpy"
			Copy
		when "cpyn"
			CopyN
		when "cpyto"
			CopyTo
		when "mvto", "mov"
			MoveTo
		when "pop"
			Pop
		when "del"
			Del
		when "deln"
			DelN
		when ","
			CurrQtty
		when ".", "qtt", "qtty"
			StackQtty
		when "opo", "neg"
			Opposite
		when "max"
			Max
		when "min"
			Min
		when "expr"
			ListExpr
		when "expri"
			ListExprIdx
		when "delxpr"
			DelExpr
		when "out", "exit"
			Exit
		when "rand"
			RandF
		when "randi"
			RandI
		when "prtqueue"
			PrintQueue
		when "prtstack", "#"
			PrintStack
		when "cmds", "help"
			Help
		when "{"
			BracketBegin
		when "}"
			BracketEnd
		when "floor"
			Floor
		when "ceil"
			Ceil
		when "mod", "%"
			Mod
		when "ln", "log"
			Ln
		when "log_"
			Log
		else
			nil
		end
	end
end
enum Control
	Repeat
	DoIf
	Set
	def self.from_string(value)
		if value.starts_with?("repeat_")
			Repeat
		elsif value.starts_with?("doif_")
			DoIf
		elsif value.starts_with?("set_")
			Set
		else 
			nil
		end
	end
end

class RPNCalc
	INVALID_ARGUMENT = "Error: Invalid argument"
	INVALID_EXPRESSION_NAME = ->(val : Word) {"Error: Invalid expression name, #{val}"}
	INVALID_INDEX = "Error: Invalid index"
	ZERO_DIVISION = "Error: Can't divide by 0"
	MAX_DECIMAL_PLACES = 8
	alias ExpressionName = String
	alias SimpleWord = Operator | ExpressionName | Float64
	alias ControlType = Tuple(Control, SimpleWord, SimpleWord | Nil)
	alias Word = SimpleWord | ControlType
	property stack
	def initialize
		@operations_dict = %w(+ sum - * mult / ** sq sqrt inv clr swap dup cpy cpyn cpyto mvto pop del deln , . opo max min expr expri delxpr out rand randi prtqueue prtstack # help { } floor ceil % ln log log_)
		@operations_string = "Math (1 operator): sq sqrt [ln|log] [neg|opo] inv floor ceil\n"
		@operations_string+= "Math (2 operators): [+] [-] [*] [/] [**|pow] [%|mod] log_\n"
		@operations_string+= "Math (N operators): sum mult max min\n"
		@operations_string+= "Random Numbers: 'rand' returns a random float 0~1, 'randi' returns a random integer 0~(N-1), \n"
		@operations_string+= "Stack Handling: dup cpy cpyn cpyto [mov|mvto] pop del deln [clr|clear] [swp|swap]\n"
		@operations_string+= "Qtty of numbers in the line until the comma: [,]   Stack size: [.|qtt|qtty]\n"
		@operations_string+= "Create Expression: { <w1> <w2> <w3> ... } <name>   List Expressions: expr or expri(for indexes)\nDelete Expression: <N> delxpr\n"
		@operations_string+= "Repeat <w1> N times: repeat_<w1>    Execute <w1> or <w2> conditionally: doif_<w1>_<w2>\n"
		@operations_string+= "Set a variable <w1>: set_<w1>   Example: 5 set_x\n"
		@operations_string+= "Help: [help|cmds]\n"
		@operations_string+= "Exit: [exit|out] \n"
		@stack = Array(Float64).new
		@auxArr = Array(Float64).new
		@op = ""
		@numbers_in_line = 0
		@reading_expression = false
		@expression = [] of Word
		@expressions = Hash(ExpressionName,Array(Word)).new
		@input_queue = Deque(Word).new
	end
	def start
		print "\e[H\e[2J" # scroll down
		while(input = read_input)
			print "\e[H\e[2J" # scroll down
			backupArr = stack.map(&.dup) 
			@numbers_in_line = 0
			strs = input.gsub('\t', " ").split(" ", remove_empty: true)
			strs.each do |str|
				begin
					if word = stringToWord(str)
						@input_queue << word
					end
				rescue e
					@input_queue << str
				end
			end 
			while(word = @input_queue.shift?)
				# READ EXPRESSION
				if(@reading_expression && word.is_a?(Word))
					if(word == Operator::BracketBegin)
						puts "Error: Expression already started"
						backup_from_error
						next
					end
					unless(word == Operator::BracketEnd)
						@expression << word
					else
						@reading_expression = false
					end
					next
				end
				if(!@reading_expression && !@expression.empty?)
					unless( word.is_a?(Operator) || word.is_a?(Float64))
						unless @expression.includes?(word)
							if(word.is_a?(ExpressionName))
								@expressions[word] = @expression
								@expression = [] of Word
							end
						else
							puts "Error: Circular reference"
							backup_from_error
						end
					else
						puts "Error: Invalid expression name \"#{word}\""
						backup_from_error
					end
					next
				end	
				# READ VALUES AND OPERATIONS
				if word.is_a?(Float64) 
					stack << word
					@numbers_in_line += 1
				elsif  word == Operator::BracketBegin  # expression begin
					if !@reading_expression
						@reading_expression = true
					end
				elsif word.is_a?(ControlType)
					controlName = word.first
					if controlName == Control::Repeat && len(1)
						consume 1
						repeat_expr = word[1]
						a.to_i64.times do 
							@input_queue.insert(0, repeat_expr)
						end
					elsif controlName == Control::DoIf && len(1)
						consume 1
						doif_exprs = word[1..2]
						if (a > 0 && doif_exprs.size > 0)
							if ifword = doif_exprs[0]
								@input_queue.insert(0, ifword) 
							end
						elsif(a <= 0 && doif_exprs.size > 1)
							if elseword = doif_exprs[1]
								@input_queue.insert(0, elseword) 
							end
						end
					elsif controlName == Control::Set && len(1)
						consume 1
						set_target = word[1]
						if(set_target.is_a?(ExpressionName) && a.is_a?(Float64))
							expr = [] of Word
							expr << a
							@expressions[set_target]=expr
						elsif !set_target.is_a?(ExpressionName)
							puts INVALID_EXPRESSION_NAME.call(set_target)
							backup_from_error 
						end
					end
				elsif word.is_a?(Operator)
					if notEnoughArgumentsError = execute(word)
						puts notEnoughArgumentsError
						backup_from_error 
					else
						@numbers_in_line = 0 #executed with success
					end
				elsif word.is_a?(ExpressionName)
					if expression = @expressions[word]?
						apply_expression(expression) 
					elsif word != ""
						puts "Error: Invalid expression \"#{word}\""
						backup_from_error 
					end
				end
			end
			printStack
		end	
	end
	def execute (@op : Operator) : String | Nil

		if check Operator::Sum, 2 
			addFromTwo a + b
		elsif check Operator::Sub, 2
			addFromTwo a - b 
		elsif check Operator::Mult, 2 
			addFromTwo a * b
		elsif check Operator::Pow, 2 
			addFromTwo a ** b
		elsif check Operator::Div, 2 
			consume 2
			return ZERO_DIVISION if b == 0
			stack << a / b
		elsif check Operator::Mod, 2 
			consume 2
			return ZERO_DIVISION if b == 0
			stack << a % b
		elsif check Operator::Swap, 2 
			addFromTwo b << a
		elsif check Operator::Log, 2
			addFromTwo Math.log(a,b)
		elsif check Operator::Sq, 1
			addFromOne a ** 2.0
		elsif check Operator::Sqrt, 1
			addFromOne a ** 0.5
		elsif check Operator::Opposite, 1
			addFromOne -a
		elsif check Operator::Floor, 1
			addFromOne a.floor
		elsif check Operator::Ceil, 1
			addFromOne a.ceil
		elsif check Operator::Ln, 1
			addFromOne Math.log (a)
		elsif check Operator::Inv, 1
			consume 1
			return ZERO_DIVISION if a == 0
			stack << 1.0 / a
		elsif check Operator::RandF
			stack << Random.rand
		elsif check Operator::RandI, 1
			consume 1
			vi = a.to_i64
			stack << Random.rand(vi > 0 ? vi : 1).to_f64
		elsif check Operator::SumN, 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.reduce(0.0.to_f64){|acc, el| el+acc} 
		elsif check Operator::MultN, 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.reduce(1.0.to_f64){|acc, el| el*acc} 
		elsif check Operator::Max, 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.max 
		elsif check Operator::Min, 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.min
		elsif check Operator::Clear
			stack.clear
		elsif check Operator::Del, 1
			return INVALID_INDEX unless len(qtty) || qtty<=1
			stack.delete_at(stack.size-qtty) 
			stack.pop
		elsif check Operator::DelN, 1
			return INVALID_ARGUMENT unless len(qtty)
			stack.pop qtty
		elsif check Operator::Pop
			stack.pop
		elsif check Operator::Dup, 1
			stack << stack.last
		elsif check Operator::Copy, 1
			if len(qtty)
			 stack[-1] = stack[-(qtty)]
			else
				return INVALID_INDEX 
	 		end
		elsif check Operator::CopyN, 1
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.map(&.dup) << numbers.map(&.dup)
		elsif check Operator::CopyTo, 2
			consume 2
			if len(b-1)
			  	stack.insert(-(b.to_i64), a)
				stack << a
			else
				return INVALID_INDEX 
	 		end
		elsif check Operator::MoveTo, 2
			consume 2
			if len(b-1)
			  	stack.insert(-(b.to_i64), a)
			else
				return INVALID_INDEX 
	 		end
		elsif check Operator::StackQtty
			stack << stack.size.to_f64
		elsif check Operator::CurrQtty
			stack << @numbers_in_line.to_f64
		elsif check Operator::Help
			puts @operations_string
		elsif check Operator::PrintQueue
			puts  "queue[#{@input_queue.join(" ")}]"
		elsif check Operator::PrintStack
			printStack
		elsif check Operator::Exit
			exit
		elsif check Operator::ListExpr
			@expressions.each do |name,words|
				puts "{ #{words.map{|w| formatWord(w) }.join(" ")} } #{name}"
			end
		elsif check Operator::ListExprIdx
			@expressions.keys.each_with_index do |name,idx|
				words = @expressions[name]
				puts "#{idx}: { #{words.map{|w| formatWord(w) }.join(" ")} } #{name}"
			end
		elsif check Operator::DelExpr, 1
			keys = @expressions.keys
			return INVALID_INDEX unless stack.last.to_i64 < keys.size && stack.last.to_i64 >= 0
			consume 1
			@expressions.delete(keys[a.to_i64])
			@input_queue.insert(0, Operator::ListExprIdx)
		else
			return "Error: Not enough arguments for #{@op}."
		end
		return nil
	end
	def consume (operands : Number)
		@auxArr = @stack[(stack.size-operands)...stack.size]
		@stack.pop operands
	end
	def consume_pop (operands : Number)
		consume(operands)
		@auxArr.pop # remove tail, usually argument
	end
	def check (operator : Operator, operands = 0)
		len(operands) && @op == operator
	end
	def len (num_elements)
		stack.size >= num_elements
	end
	def qtty
		stack.last.to_i64 + 1
	end
	def a
		@auxArr[0]
	end
	def b
		@auxArr[1]
	end
	def numbers
		@auxArr
	end
	def apply_expression(expression)
		expression.each_with_index do |word,idx|
			@input_queue.insert(idx, word)
		end
	end
	def read_input()
		prompt(">> ")
	end
	def prompt(str)
		print str
		return gets.not_nil!.chomp.gsub('{', " { ").gsub('}', " } ")    
	end
	def printStack
		puts "[#{stack.map{|n| formatNumber(n)}.join(" ")}>"
	end
	def formatNumber(num : Float64) : String
		num % 1 == 0 ? num.to_i64.to_s : num.format(decimal_places: MAX_DECIMAL_PLACES, only_significant: true)
	end
	def formatControl(w : ControlType) : String
		str = ""
		if(w[0] == Control::DoIf)
			str += "doif_" + formatWord(w[1])
			if second_argument = w[2]
				str += "_" + formatWord(second_argument)
			end
		elsif(w[0] == Control::Repeat)
			str += "repeat_" + formatWord(w[1])
		elsif(w[0] == Control::Set)
			str += "set_" + formatWord(w[1])
		end
		return str
	end
	def formatWord(w : Word) : String
		w.is_a?(Operator) ? @operations_dict[w.to_i] : (w.is_a?(Float64) ? formatNumber(w) : ( w.is_a?(ControlType) ? formatControl(w) : w ))
	end
	def stringToWord(str : String) : Word | Nil
		if control = Control.from_string(str)
			stringToControlWord(str, control)
		elsif word = stringToSimpleWord(str)
			word
		else
			raise "Invalid word: #{str}"
		end
	end
	def stringToControlWord(str : String, control : Control) : ControlType | Nil
		if control == Control::Repeat
			str = str.split("repeat_").last
			if firstWd = stringToSimpleWord(str)
				{control,firstWd, nil}
			end
		else 
			wds = str.split("_")
			wds.shift
			if firstWd = stringToSimpleWord(wds[0])
				if wds.size == 2
					if secondWd = stringToSimpleWord(wds[1])
						{control,firstWd, secondWd}
					else
						{control,firstWd, nil}
					end
				else
					{control,firstWd, nil}
				end
			end
		end
	end
	def stringToSimpleWord(str : String) : SimpleWord | Nil
		if op = Operator.from_string(str)
			op
		elsif number = str.to_f64?
			number
		elsif str.is_a?(ExpressionName)
			str
		else
			nil
		end
	end
end



RPNCalc.new.start

# example of expressions:
# { dup doif__opo } abs
# { 2 cpyn - dup abs dup doif_/_pop } greater
# { swap greater } lesser or { greater opo } lesser
# { . . cpyto  } storeSize
# { . cpy  } getSize
# { storeSize getSize sum swap / } mean

