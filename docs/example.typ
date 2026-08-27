#import "../src/lib.typ": *

#set page(width: auto, height: auto, margin: 10pt)
#set text(size: 11pt)

$ #string-diagram(serial(
    state("Uniform"),
    copy,
    parallel(wire($"bias"$, side: "left"), process("Bernoulli")),
    parallel(wire(), wire($"flip"$)),
  ))
  quad quad
  #string-diagram(serial(copy, parallel(discard, wire()))) = #string-diagram(wire(length: 2)) = #string-diagram(serial(copy, parallel(wire(), discard)))
  quad quad
  #string-diagram(serial(parallel(wire($X$), wire($Y$)), bundle, copy, parallel(unbundle, unbundle)))
  = #string-diagram(serial(parallel(copy, copy), parallel(wire(), swap, wire()))) $
