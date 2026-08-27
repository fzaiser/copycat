#import "../src/lib.typ": copy, discard, state, effect, primitive, bundle, process, serial, unbundle, string-diagram, styled, swap, parallel, wire

#set page(width: 16cm, height: auto, margin: 1.2cm)
#set text(size: 11pt)
#set par(justify: false)

= copycat gallery

A kernel $f : X arrow.squiggly Y$, and sequential composition:

$ #string-diagram(serial(wire($X$), process($f$), wire($Y$))) quad quad
  #string-diagram(serial(wire($X$), process($f$), wire($Y$), process($g$), wire($Z$))) $

Parallel composition:

$ #string-diagram(parallel(
    serial(wire($X$), process($f$), wire($Y$)),
    serial(wire($X'$), process($g$), wire($Y'$)),
  )) $

A product wire $X times Y$ may be drawn as two wires, and back:

$ #string-diagram(serial(wire($X times Y$), unbundle, parallel(wire($X$), wire($Y$)))) quad quad
  #string-diagram(serial(parallel(wire($X$), wire($Y$)), bundle, wire($X times Y$))) $

The swap:

$ #string-diagram(serial(parallel(wire($X$), wire($Y$)), swap, parallel(wire($Y$), wire($X$)))) $

The Dirac kernel is the bare wire:

$ #string-diagram(serial(wire($X$), process("Dirac"), wire($X$))) = #string-diagram(wire($X$, length: 2)) $

A state is a kernel with trivial input:

$ #string-diagram(serial(state("FairCoin"), wire($"Bool"$)))
  = #string-diagram(serial(wire($1$), process("FairCoin"), wire($"Bool"$))) $

A little probabilistic program:

$ #string-diagram(serial(state("Uniform"), wire($[0,1]$), process("Bernoulli"), wire($"Bool"$))) $

Copying:

$ #string-diagram(serial(wire($X$), copy, parallel(wire($X$), wire($X$)))) $

Sampling a bias, then flipping a coin with it:

$ #string-diagram(serial(
    state("Uniform"),
    copy,
    parallel(wire($"bias"$, length: 1, side: "left"), process("Bernoulli")),
    parallel(wire(), wire($"flip"$)),
  )) $

Coassociativity and cocommutativity of copying:

$ #string-diagram(serial(copy, parallel(copy, wire()))) = #string-diagram(serial(copy, parallel(wire(), copy)))
  quad quad
  #string-diagram(serial(copy, swap)) = #string-diagram(copy) $

Counitality:

$ #string-diagram(serial(copy, parallel(discard, wire()))) = #string-diagram(wire(length: 2))
  = #string-diagram(serial(copy, parallel(wire(), discard))) $

Discarding, and the fact that every kernel is discarded to nothing:

$ #string-diagram(serial(wire($X$), discard)) quad quad
  #string-diagram(serial(wire($X$), process($f$), discard)) = #string-diagram(serial(wire($X$), discard)) $

Copying and discarding a product:

$ #string-diagram(serial(parallel(wire($X$), wire($Y$)), bundle, copy, parallel(unbundle, unbundle)))
  = #string-diagram(serial(parallel(copy, copy), parallel(wire(), swap, wire()))) $

$ #string-diagram(serial(parallel(wire($X$), wire($Y$)), bundle, discard))
  = #string-diagram(parallel(serial(wire($X$), discard), serial(wire($Y$), discard))) $

An effect (the mirror image of a state):

$ #string-diagram(serial(wire($X$), effect($e$))) $

Flexible wiring: the arms of `copy`, `unbundle` and `bundle` run straight to wherever the layer
above or below needs them, instead of being bent once inside the fork and once again in a
connector band.

$ #string-diagram(serial(copy, parallel(process("Bernoulli"), wire()))) quad
  #string-diagram(serial(copy, parallel(copy, wire()))) quad
  #string-diagram(serial(parallel(process($f$), wire($Y$)), bundle, wire($X times Y$))) quad
  #string-diagram(serial(copy, parallel(unbundle, wire()))) $

Wires find their own x: a narrow wire layer over a wide box, a stack of three such layers, and the
coin-bias program written with the bias wire and the sampled value on separate layers. None of these
needs a connector band.

$ #string-diagram(serial(process("Bernoulli"), wire($"Bool"$))) quad
  #string-diagram(serial(process("Bernoulli"), wire(), wire(), wire($"Bool"$))) quad
  #string-diagram(serial(state("Uniform"), copy, parallel(wire(), process("Bernoulli")), parallel(wire($[0,1]$), wire($"Bool"$)))) $

A wire held at different x at both ends bends by itself, with no band inserted:

$ #string-diagram(serial(
    parallel(process($f$), process("Bernoulli")),
    parallel(wire(), wire()),
    parallel(process("Bernoulli"), process($g$)),
  )) $

== Inline diagrams

The copy map #string-diagram(copy, style: (unit: 0.45cm)) and the discard map
#string-diagram(discard, style: (unit: 0.45cm)) satisfy #string-diagram(serial(copy, parallel(wire(), discard)), style: (unit: 0.45cm))
$=$ #string-diagram(wire(), style: (unit: 0.45cm)), so they make every object a comonoid. At the default unit
the same term, #string-diagram(serial(copy, swap)), is rather large for running text, which is why inline uses
should pass a smaller `unit`, and a smaller label size when the diagram carries labels:
#string-diagram(serial(wire($X$), process($f$), wire($Y$)), style: (unit: 0.5cm, label: (size: 0.8em))).

== Style overrides

A style override can target a whole diagram (the `style:` argument of `string-diagram`), where element
groups inherit the root `stroke` and `fill` and partial strokes fold, cetz-style:

$ #string-diagram(
    serial(state("Uniform"), copy, parallel(wire($"bias"$, side: "left"), process("Bernoulli")), parallel(wire(), discard)),
    style: (unit: 1.1cm, discard: (kind: "ground"), bend: 0.7, box: (fill: rgb("#eef3ff"))),
  ) $

It can target a sub-diagram, via `styled` or the `style:` argument of `serial` and `parallel`:

$ #string-diagram(serial(
    state("Uniform"),
    styled(serial(copy, parallel(wire(), discard), style: (discard: (kind: "ground"))), stroke: (paint: red)),
    wire($[0,1]$),
  )) $

Or it can target a single element, whose inline `stroke` and `fill` restyle just that element:

$ #string-diagram(serial(wire($X$), process($f$, stroke: (paint: blue), fill: rgb("#e7f0fe")), wire($Y$, stroke: (dash: "dashed")))) $

== Reading direction

The style key `direction` reads the same diagram bottom to top (the default), top to bottom, left to right, or right to left.
For horizontal directions, a wire label with `side: "right"` sits below its wire and one with `side: "left"` above it.

#let program = serial(
  state("Uniform"),
  copy,
  parallel(wire($"bias"$, side: "left"), process("Bernoulli")),
  parallel(wire(), wire($"flip"$)),
)
$ #string-diagram(program) quad
  #string-diagram(program, style: (direction: "down")) $
$ #string-diagram(program, style: (direction: "right")) quad quad
  #string-diagram(program, style: (direction: "left")) $

== Custom primitives

`primitive` turns a cetz drawing into a rigid element that composes like any other.
The drawing function receives the resolved style and the element's geometry, and draws in unit coordinates with the origin at the bottom-left corner.

#import "@preview/cetz:0.5.2": draw

#let cap = primitive(inputs: 0, outputs: 2, width: 2, height: 1, draw: (style, geometry) => {
  draw.bezier((0.5, 1), (1.5, 1), (0.5, 0.2), (1.5, 0.2), stroke: style.wire.stroke)
})
#let cup = primitive(inputs: 2, outputs: 0, width: 2, height: 1, draw: (style, geometry) => {
  draw.bezier((0.5, 0), (1.5, 0), (0.5, 0.8), (1.5, 0.8), stroke: style.wire.stroke)
})
#let spider(n, m) = primitive(inputs: n, outputs: m, draw: (style, geometry) => {
  let c = (geometry.width / 2, geometry.height / 2)
  for x in geometry.input-positions { draw.line((x, 0), c, stroke: style.wire.stroke) }
  for x in geometry.output-positions { draw.line(c, (x, geometry.height), stroke: style.wire.stroke) }
  draw.circle(c, radius: style.dot.radius, fill: style.dot.fill, stroke: none)
})

The snake equation of a compact closed category, and a spider:

$ #string-diagram(serial(parallel(wire($X$), cap), parallel(cup, wire($X$)))) = #string-diagram(wire($X$, length: 2))
  quad quad
  #string-diagram(serial(parallel(wire(), wire(), wire()), spider(3, 2))) $

An element can size itself to its label by giving `width` or `height` as a function of the style and a `measure` function.
`measure` reports the label's extent along the element's width and height, so this trapezoid fits its label in every reading direction:

#let trapezoid(label) = primitive(
  width: (style, measure) => calc.max(1.0, measure(label).width + 2 * (style.box.inset + style.box.margin)),
  height: (style, measure) => calc.max(style.box.height, measure(label).height + 2 * style.box.inset) + 2 * style.stub,
  draw: (style, geometry) => {
    let (w, h, m) = (geometry.width, geometry.height, style.box.margin)
    let (y0, y1) = (style.stub, h - style.stub)
    draw.line((w / 2, 0), (w / 2, y0), stroke: style.wire.stroke)
    draw.line((w / 2, y1), (w / 2, h), stroke: style.wire.stroke)
    draw.line((m, y0), (w - m, y0), (w - m - 0.2, y1), (m + 0.2, y1), close: true, fill: style.box.fill, stroke: style.box.stroke)
    draw.content((w / 2, (y0 + y1) / 2), text(size: style.label.size, label))
  },
)

$ #string-diagram(serial(wire($X$), trapezoid("Bernoulli"), wire($"Bool"$))) quad
  #string-diagram(serial(wire($X$), trapezoid("Bernoulli"), wire($"Bool"$)), style: (direction: "right")) $
