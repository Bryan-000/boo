#region license
// Copyright (c) 2004, Rodrigo B. de Oliveira (rbo@acm.org)
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//     * Neither the name of Rodrigo B. de Oliveira nor the names of its
//     contributors may be used to endorse or promote products derived from this
//     software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#endregion

namespace Boo.Lang.Extensions

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

def expandPrintMacro(macro as MacroStatement,
					write as Expression,
					writeLine as Expression):

	if len(macro.Arguments) < 2:
		mie = [| $writeLine() |]
		mie.Arguments = macro.Arguments
		return ExpressionStatement(mie)

	block = Block()

	last = macro.Arguments[-1]
	for arg in macro.Arguments:
		if arg is last: break
		block.Add([| $write($arg) |].withLexicalInfoFrom(arg))
		block.Add([| $write(' ') |])
	block.Add([| $writeLine($last) |].withLexicalInfoFrom(last))

	return block

# Optional keyword argument name for print: sep, end, file, or flush, else null.
def printOptionName(argument as Expression) as string:
	option = argument as BinaryExpression
	return null if option is null or option.Operator != BinaryOperatorType.Assign
	# o.sep = x assigns a member, so it stays an argument.
	return null if option.Left.NodeType != NodeType.ReferenceExpression
	name = (option.Left as ReferenceExpression).Name
	return (name if name in ("sep", "end", "file", "flush") else null)

# A local holding value, evaluated where it is added to the block.
def printLocal(block as Block, name as string, value as Expression) as ReferenceExpression:
	local = ReferenceExpression(value.LexicalInfo, CompilerContext.Current.GetUniqueName("print", name))
	block.Add([| $local = $value |].withLexicalInfoFrom(value))
	return local

# The option's local, set to default when null, or default itself when not given.
def printDefault(block as Block, option as Expression, default as Expression) as Expression:
	return default if option is null
	block.Add([| $option = $default if $option is null |])
	return option

# print writes its arguments to the console, or as Python's print does given sep=,
# end=, file= or flush=, where null means the default.
macro print:
	if not print.Arguments.Any({ argument | printOptionName(argument) is not null }):
		return expandPrintMacro(print,
					[| System.Console.Write |],
					[| System.Console.WriteLine |])

	# Like Python, evaluate arguments then options, in order, before writing.
	block = Block(print.LexicalInfo)
	values = List[of Expression]()
	options = {}
	last as string
	for argument in print.Arguments:
		name = printOptionName(argument)
		if name is null:
			raise "print was given an argument after ${last}=" if last is not null
			values.Add(printLocal(block, "argument", argument))
			continue
		raise "print was given ${name}= more than once" if options.ContainsKey(name)
		value = (argument as BinaryExpression).Right
		if name == "file":
			value = [| $value cast System.IO.TextWriter |].withLexicalInfoFrom(value)
		elif name in ("sep", "end"):
			value = [| $value cast string |].withLexicalInfoFrom(value)
		options[name] = printLocal(block, name, value)
		last = name

	writer = printDefault(block, options["file"], [| System.Console.Out |])
	separator = printDefault(block, options["sep"], [| ' ' |])
	ending = printDefault(block, options["end"], [| $writer.NewLine |])
	for value in values:
		block.Add([| $writer.Write($separator) |]) unless value is values[0]
		block.Add([| $writer.Write($value) |].withLexicalInfoFrom(value))
	block.Add([| $writer.Write($ending) |])
	flush = options["flush"] as Expression
	block.Add([| $writer.Flush() if $flush |]) if flush is not null
	return block
