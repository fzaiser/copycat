#import "setup.typ": *
#show: setup

#fig("quick-start")[
  $ #sd(serial(state("Camera"), wire("photo"), process("Describe"), wire("text"))) $

  $ #sd(serial(copy, parallel(discard, wire()))) = #sd(wire()) $
]
