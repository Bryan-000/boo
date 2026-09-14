namespace Boo.Lang.Parser.Tests

import System.Collections.Generic
import System.IO
import NUnit.Framework
import Boo.Lang.Compiler
import Boo.Lang.Compiler.IO
import Boo.Lang.Parser

[TestFixture]
class LexerErrorTestFixture:
	"""
	A character the lexer cannot read is an error even when the parser gets past
	it, and it is reported to the compiler rather than to the console.
	"""
	// The lexer skips the stray character, so the tokens left parse cleanly.
	private static final StrayCharacter = "x = 1 §\nprint x\n"

	[Test]
	def ParsingStepReportsIt():
		compiler = BooCompiler()
		pipeline = Boo.Lang.Compiler.Pipelines.Parse()
		pipeline.Replace(Boo.Lang.Compiler.Steps.Parsing, BooParsingStep())
		compiler.Parameters.Pipeline = pipeline
		compiler.Parameters.Input.Add(StringInput("code", StrayCharacter))
		errors as CompilerErrorCollection
		console = ConsoleOutput({ errors = compiler.Run().Errors })
		Assert.AreEqual(1, errors.Count, errors.ToString())
		Assert.AreEqual("code", errors[0].LexicalInfo.FileName)
		Assert.AreEqual(1, errors[0].LexicalInfo.Line)
		Assert.IsEmpty(console)

	[Test]
	def ParseReaderReportsIt():
		lines = List[of int]()
		settings = ParserSettings()
		settings.ErrorHandler = { recognizer, symbol, file, line as int, column, message, e | lines.Add(line) }
		console = ConsoleOutput({ BooParser.ParseReader(settings, "code", StringReader(StrayCharacter)) })
		Assert.AreEqual((1,), lines.ToArray())
		Assert.IsEmpty(console)

	// What the block writes to standard output and error.
	private static def ConsoleOutput(block as callable()) as string:
		written = StringWriter()
		output = System.Console.Out
		error = System.Console.Error
		System.Console.SetOut(written)
		System.Console.SetError(written)
		try:
			block()
		ensure:
			System.Console.SetOut(output)
			System.Console.SetError(error)
		return written.ToString()
