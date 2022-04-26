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
	CopyTo                          #    80 19 53 123 3 -> 123 80 19 53  # consumes the number, not just the index, it's actually a move operation
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
	def to_s(io)
		io.puts(self.to_s)
	end
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
		when "prtstack"
			PrintStack
		when "cmds", "help"
			Help
		when "{"
			BracketBegin
		when "}"
			BracketEnd
		else
			nil
		end
	end
end
enum Control
	Repeat
	DoIf
	def self.from_string(value)
		if value.starts_with?("repeat_")
			Repeat
		elsif value.starts_with?("doif_")
			DoIf
		else 
			nil
		end
	end
end

class RPNCalc
	INVALID_ARGUMENT = "Error: Invalid argument"
	INVALID_INDEX = "Error: Invalid index"
	ZERO_DIVISION = "Error: Can't divide by 0"
	MAX_DECIMAL_PLACES = 8
	alias ExpressionName = String
	alias SimpleWord = Operator | ExpressionName | Float64
	alias ControlType = Tuple(Control, SimpleWord, SimpleWord | Nil)
	alias Word = SimpleWord | ControlType
	property stack, operations
	def initialize
		@operations = %w(+ - * / ** pow sq sqrt clr clear dup cpy cpyn cpyto pop sum mult del deln , . qtt qtty neg opo inv max min swp swap cmds help { } expr expri delxpr exit out repeat_ doif_ rand randi prtqueue prtstack)
		@operations_dict = %w(+ sum - * mult / ** sq sqrt inv clr swap dup cpy cpyn cpyto pop del deln , . opo max min expr expri delxpr out rand randi prtqueue prtstack help { } )
		@operations_string = "Math: [+] [-] [*] [/] [**|pow] sq sqrt [neg|opo] inv sum mult max min rand(0~1) randi(0 to <N-1>)            Help: [help|cmds]\n"
		@operations_string+= "Stack Handling: dup cpy cpyn cpyto pop del deln [clr|clear] [swp|swap]                                 Exit: [exit|out] \n"
		@operations_string+= "Qtty of numbers in the line until the comma: [,]   Stack size: [.|qtt|qtty]\n"
		@operations_string+= "Create Expression: { <w1> <w2> <w3> ... } <name>   List Expressions: expr or expri(for indexes)\nDelete Expression: <N> delxpr\n"
		@operations_string+= "Repeat <w1> N times: repeat_<w1>    Execute <w1> or <w2> conditionally: doif_<w1>_<w2>\n"
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

		if check "+", 2 
			consume 2
			stack << a + b
		elsif check "-", 2
			consume 2
			stack << a - b
		elsif check "*", 2 
			consume 2
			stack << a * b
		elsif check ["**", "pow"], 2 
			consume 2
			stack << a ** b
		elsif check "/", 2 
			consume 2
			return ZERO_DIVISION if b == 0
			stack << a / b
		elsif check ["swp", "swap"], 2 
			consume 2
			stack << b << a
		elsif check "sq", 1
			consume 1
			stack << a ** 2.0
		elsif check "sqrt", 1
			consume 1
			stack << a ** 0.5
		elsif check ["neg","opo"], 1
			consume 1
			stack << - a
		elsif check "inv", 1
			consume 1
			return ZERO_DIVISION if a == 0
			stack << 1.0 / a
		elsif check "rand"
			stack << Random.rand
		elsif check "randi", 1
			consume 1
			vi = a.to_i64
			stack << Random.rand(vi > 0 ? vi : 1).to_f64
		elsif check "sum", 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.reduce(0.0.to_f64){|acc, el| el+acc} 
		elsif check "mult", 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.reduce(1.0.to_f64){|acc, el| el*acc} 
		elsif check "max", 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.max 
		elsif check "min", 1 
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.min
		elsif check ["clr", "clear"]
			stack.clear
		elsif check "del", 1
			return INVALID_INDEX unless len(qtty) || qtty<=1
			stack.delete_at(stack.size-qtty) 
			stack.pop
		elsif check "deln", 1
			return INVALID_ARGUMENT unless len(qtty)
			stack.pop qtty
		elsif check "pop"
			stack.pop
		elsif check "dup", 1
			stack << stack.last
		elsif check "cpy", 1
			if len(qtty)
			 stack[-1] = stack[-(qtty)]
			else
				return INVALID_INDEX 
	 		end
		elsif check "cpyn", 1
			return INVALID_ARGUMENT unless len(qtty)
			consume_pop qtty
			stack << numbers.map(&.dup) << numbers.map(&.dup)
		elsif check "cpyto", 2
			consume 2
			if len(b-1)
			  	stack.insert(-(b.to_i64), a)
			else
				return INVALID_INDEX 
	 		end
		elsif check [".", "qtty", "qtt"]
			stack << stack.size.to_f64
		elsif check [","]
			stack << @numbers_in_line.to_f64
		elsif check ["help","cmds"]
			puts @operations_string
		elsif check "prtqueue"
			puts  "queue[#{@input_queue.join(" ")}]"
		elsif check "prtstack"
			printStack
		elsif check ["exit","out"]
			exit
		elsif check "expr"
			@expressions.each do |name,words|
				puts "{ #{words.map{|w| formatWord(w) }.join(" ")} } #{name}"
			end
		elsif check "expri"
			@expressions.keys.each_with_index do |name,idx|
				words = @expressions[name]
				puts "#{idx}: { #{words.map{|w| formatWord(w) }.join(" ")} } #{name}"
			end
		elsif check "delxpr", 1
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
	def check (operatorsStr : Array(String), operands = 0)
		len(operands) && operatorsStr.map{|operatorStr| Operator.from_string(operatorStr) == @op}.any?
	end
	def check (operatorStr : String, operands = 0)
		check([operatorStr], operands)
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
		end
		return str
	end
	def formatWord(w : Word) : String
		w.is_a?(Operator) ? @operations_dict[w.to_i] : (w.is_a?(Float64) ? formatNumber(w) : ( w.is_a?(ControlType) ? formatControl(w) : w ))
	end
	def stringToWord(str : String) : Word | Nil
		if op = Operator.from_string(str)
			op
		elsif number = str.to_f64?
			number
		elsif control = Control.from_string(str)
			if control == Control::Repeat
				str = str.split("repeat_").last
				if firstWd = stringToWordExceptControl(str)
					{control,firstWd, nil}
				end
			else 
				wds = str.split("_")
				wds.shift
				if firstWd = stringToWordExceptControl(wds[0])
					if wds.size == 2
						if secondWd = stringToWordExceptControl(wds[1])
							{control,firstWd, secondWd}
						else
							{control,firstWd, nil}
						end
					else
						{control,firstWd, nil}
					end
				end
			end
		elsif str.is_a?(ExpressionName) 
			str
		else
			raise "Invalid word: #{str}"
		end
	end
	def stringToWordExceptControl(str : String) : SimpleWord | Nil
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

