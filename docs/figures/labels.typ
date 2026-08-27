#import "setup.typ": *
#show: setup

#fig("label-string", sd(wire("photo")))
#fig("label-math", sd(wire($X times Y$)))
#fig("label-beside", sd(parallel(wire("photo"), process("Describe"))))
#fig("label-left", sd(parallel(wire("photo", side: "left"), process("Describe"))))
