require "string_pool"

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
end
class RPNCalc
	INVALID_ARGUMENT = "Error: Invalid argument"
	INVALID_INDEX = "Error: Invalid index"
	ZERO_DIVISION = "Error: Can't divide by 0"
	property stack, operations
	def initialize
		@operations = %w(+ - * / ** pow sq sqrt clr clear dup cpy cpyn cpyto pop sum mult del deln , . qtt qtty opo inv max min swp swap cmds help { } expr expri delxpr exit out repeat_ doif_ rand randi)
		@operations_string = "Math: [+] [-] [*] [/] [**|pow] sq sqrt opo inv sum mult max min rand(0~1) randi(0 to <N-1>)            Help: [help|cmds]\n"
		@operations_string+= "Stack Handling: dup cpy cpyn cpyto pop del deln [clr|clear] [swp|swap]                                 Exit: [exit|out] \n"
		@operations_string+= "Qtty of numbers in the line until the comma: [,]   Stack size: [.|qtt|qtty]\n"
		@operations_string+= "Create Expression: { <w1> <w2> <w3> ... } <name>   List Expressions: expr or expri(for indexes)\nDelete Expression: <N> delxpr\n"
		@operations_string+= "Repeat <w1> N times: repeat_<w1>    Execute <w1> or <w2> conditionally: doif_<w1>_<w2>\n"
		@stack = Array(Float64).new
		@auxArr = Array(Float64).new
		@op = ""
		@numbers_in_line = 0
		@reading_expression = false
		@expression = [] of String
		@expressions = Hash(String,Array(String)).new
		@input_queue = Deque(String).new
		@pool = StringPool.new
	end
	def start
		print "\e[H\e[2J" # scroll down
		while(input = read_input)
			print "\e[H\e[2J" # scroll down
			backupArr = stack.map(&.dup) 
			@numbers_in_line = 0
			@input_queue << input.split(" ").select{|e|!e.empty?}
			
			while(word = @input_queue.shift?)
				word = @pool.get(word)
				# READ EXPRESSION
				if(@reading_expression)
					if(word == "{")
						puts "Error: Expression already started"
						backup_from_error
						next
					end
					unless(word == "}")
						@expression << word
					else
						@reading_expression = false
					end
					next
				end
				if(!@reading_expression && !@expression.empty?)
					unless(@operations.includes?(word) || word.to_f64? != nil)
						unless @expression.includes?(word)
							@expressions[word] = @expression
							@expression = [] of String
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
				if( number = word.to_f64?)
					stack << number
					@numbers_in_line += 1
				elsif(  word == "{") # expression begin
					if( !@reading_expression)
						@reading_expression = true
					end
				elsif expression = @expressions[word]? 
					apply_expression(expression)
				elsif error = execute(word) 
					puts error
					backup_from_error 
				else
					@numbers_in_line = 0 #executed with success
				end
			end
			puts "[#{stack.map{|n| n % 1 == 0 ? n.to_i32.to_s : n.to_s}.join(" ")}>"
		end	
	end
	def execute (@op : String) : String | Nil
		return "Error: Invalid operation \"#{@op}\" " unless operations.includes?(@op) || @op.starts_with?("repeat_") || @op.starts_with?("doif_") 
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
		elsif check "opo", 1
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
			vi = a.to_i32
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
			  	stack.insert(-(b.to_i32), a)
			else
				return INVALID_INDEX 
	 		end
		elsif check [".", "qtty", "qtt"]
			stack << stack.size.to_f64
		elsif check [","]
			stack << @numbers_in_line.to_f64
		elsif check ["help","cmds"]
			puts @operations_string
		elsif check ["exit","out"]
			exit
		elsif check "expr"
			@expressions.each do |name,words|
				puts "{ #{words.join(" ")} } #{name}"
			end
		elsif check "expri"
			@expressions.keys.each_with_index do |name,idx|
				words = @expressions[name]
				puts "#{idx}: { #{words.join(" ")} } #{name}"
			end
		elsif check "delxpr", 1
			keys = @expressions.keys
			return INVALID_INDEX unless stack.last.to_i32 < keys.size && stack.last.to_i32 >= 0
			consume 1
			@expressions.delete(keys[a.to_i32])
			@input_queue.insert(0, "expri")
		elsif @op.starts_with?("repeat_") && len(1)
			consume 1
			repeat_expr = @op.split("repeat_").last
			a.to_i32.times do 
				@input_queue.insert(0, repeat_expr)
			end
		elsif @op.starts_with?("doif_") && len(1)
			consume 1
			doif_exprs = @op.split("_")
			if (a > 0 && doif_exprs.size > 1)
				@input_queue.insert(0, doif_exprs[1]) if !doif_exprs[1].empty?
			elsif(a <= 0 && doif_exprs.size > 2)
				@input_queue.insert(0, doif_exprs[2]) if !doif_exprs[2].empty?
			end
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
	def check (operators : Array(String), operands = 0)
		operators.includes?(@op) && len(operands)
	end
	def check (operator : String, operands = 0)
		check([operator], operands)
	end
	def len (num_elements)
		stack.size >= num_elements
	end
	def qtty
		stack.last.to_i32 + 1
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
		expression.reverse.each do |word|
			@input_queue.insert(0, word)
		end
	end
	def read_input()
		prompt(">> ")
	end
	def prompt(str)
		print str
		return gets.not_nil!.chomp
	end
end



RPNCalc.new.start

# exemple of expressions:
# { dup doif__opo } abs
# { 2 cpyn - dup abs dup doif_/_pop } greater
# { swap greater } lesser or { greater opo } lesser

