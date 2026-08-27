// error: `input-positions` must have one entry per input
#import "../../src/lib.typ": *
#let d = primitive(inputs: 2, input-positions: (0.5,), draw: (st, g) => ())
