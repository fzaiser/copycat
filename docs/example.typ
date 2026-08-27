#import "@preview/copycat:0.1.0": *

// Rendered once per theme by scripts/render-docs.sh: `--input theme=dark` draws
// in white on a transparent page, for the README's dark-mode variant.
#let ink = if sys.inputs.at("theme", default: "light") == "dark" { white } else { black }
#let sd = string-diagram.with(style: (stroke: (paint: ink), fill: none))

#set page(width: auto, height: auto, margin: 10pt, fill: none)
#set text(size: 11pt, fill: ink)

$ #sd(serial(
    state("Uniform"),
    copy,
    parallel(wire($"bias"$, side: "left"), process("Bernoulli")),
    parallel(wire(), wire($"flip"$)),
  ))
  quad quad
  #sd(serial(copy, parallel(discard, wire()))) = #sd(wire(length: 2)) = #sd(serial(copy, parallel(wire(), discard)))
  quad quad
  #sd(serial(parallel(wire($X$), wire($Y$)), bundle, copy, parallel(unbundle, unbundle)))
  = #sd(serial(parallel(copy, copy), parallel(wire(), swap, wire()))) $
