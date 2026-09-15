"""
a-b-c!
x y
no newline|
flushed
1:2
defaults for null
also "" and ""
[eggs 42

ham
]
[]
member=assignment
member
7 indexed
1:2;
1 2 : ;
"""
import System
import System.Collections.Generic
import System.IO

class Holder:
	public sep as string

print "a", "b", "c", sep="-", end="!\n"
print "x", "y", end="\n"
print "no newline", end="|"
print
print "flushed", flush=true, file=Console.Out
print 1, 2, end="\n", sep=":"
nothing as string = null
print "defaults", "for", "null", sep=nothing, end=null, file=null
print "also", '""', "and", '""', sep=null

writers = Queue[of StringWriter]((StringWriter(), StringWriter()))
first = writers.Peek()
print "eggs", 42, file=writers.Dequeue()
print file=first
print "ham", file=first
print "[${first.ToString().Replace('\r\n', '\n')}]"
# file= is evaluated once, so the second writer is still queued and empty.
print "[${writers.Dequeue()}]"
print "hidden", file=TextWriter.Null

# Assignments to members and items are arguments, not options.
holder = Holder()
print holder.sep = "member", "assignment", sep="="
print holder.sep
items = array(int, 1)
print items[0] = 7, end=" indexed\n"

# Arguments then options are evaluated once, in order, before writing.
evaluated = []
trace = def(value as string):
	evaluated.Add(value)
	return value
print trace("1"), trace("2"), sep=trace(":"), end=trace(";")
print
print join(evaluated, " ")
