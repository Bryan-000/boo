"""
BCE0045-5.boo(5,1): BCE0045: Macro expansion error: print was given sep= more than once.
BCE0045-5.boo(6,1): BCE0045: Macro expansion error: print was given an argument after end=.
"""
print "a", sep="-", sep="+"
print "a", end="!", "b"
