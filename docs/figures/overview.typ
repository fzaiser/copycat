#import "setup.typ": *
#show: setup

#fig("overview")[
  $ #sd(program)
    quad quad
    #sd(serial(copy, parallel(discard, wire()))) = #sd(wire(length: 2)) = #sd(serial(copy, parallel(wire(), discard)))
    quad quad
    #sd(serial(parallel(wire($X$), wire($Y$)), bundle, copy, parallel(unbundle, unbundle)))
    = #sd(serial(parallel(copy, copy), parallel(wire(), swap, wire()))) $
]
