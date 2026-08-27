#import "lib.typ": copy, diagram, discard, effect, merge, morph, seq, split, state, styled, swap, tensor, wire

#set page(width: 16cm, height: auto, margin: 1.2cm)
#set text(size: 11pt)
#set par(justify: false)

= copycat examples

A kernel $f : X arrow.squiggly Y$, and sequential composition:

$ #diagram(seq(wire($X$), morph($f$), wire($Y$))) quad quad
  #diagram(seq(wire($X$), morph($f$), wire($Y$), morph($g$), wire($Z$))) $

Parallel composition:

$ #diagram(tensor(
    seq(wire($X$), morph($f$), wire($Y$)),
    seq(wire($X'$), morph($g$), wire($Y'$)),
  )) $

A product wire $X times Y$ may be drawn as two wires, and back:

$ #diagram(seq(wire($X times Y$), split, tensor(wire($X$), wire($Y$)))) quad quad
  #diagram(seq(tensor(wire($X$), wire($Y$)), merge, wire($X times Y$))) $

The swap:

$ #diagram(seq(tensor(wire($X$), wire($Y$)), swap, tensor(wire($Y$), wire($X$)))) $

The Dirac kernel is the bare wire:

$ #diagram(seq(wire($X$), morph("Dirac"), wire($X$))) = #diagram(wire($X$, length: 2)) $

A state is a kernel with trivial input:

$ #diagram(seq(state("FairCoin"), wire($"Bool"$)))
  = #diagram(seq(wire($1$), morph("FairCoin"), wire($"Bool"$))) $

A little probabilistic program:

$ #diagram(seq(state("Uniform"), wire($[0,1]$), morph("Bernoulli"), wire($"Bool"$))) $

Copying:

$ #diagram(seq(wire($X$), copy, tensor(wire($X$), wire($X$)))) $

Sampling a bias, then flipping a coin with it:

$ #diagram(seq(
    state("Uniform"),
    copy,
    tensor(wire($"bias"$, length: 1, side: "left"), morph("Bernoulli")),
    tensor(wire(), wire($"flip"$)),
  )) $

Coassociativity and cocommutativity of copying:

$ #diagram(seq(copy, tensor(copy, wire()))) = #diagram(seq(copy, tensor(wire(), copy)))
  quad quad
  #diagram(seq(copy, swap)) = #diagram(copy) $

Counitality:

$ #diagram(seq(copy, tensor(discard, wire()))) = #diagram(wire(length: 2))
  = #diagram(seq(copy, tensor(wire(), discard))) $

Discarding, and the fact that every kernel is discarded to nothing:

$ #diagram(seq(wire($X$), discard)) quad quad
  #diagram(seq(wire($X$), morph("f"), discard)) = #diagram(seq(wire($X$), discard)) $

Copying and discarding a product:

$ #diagram(seq(tensor(wire($X$), wire($Y$)), merge, copy, tensor(split, split)))
  = #diagram(seq(tensor(copy, copy), tensor(wire(), swap, wire()))) $

$ #diagram(seq(tensor(wire($X$), wire($Y$)), merge, discard))
  = #diagram(tensor(seq(wire($X$), discard), seq(wire($Y$), discard))) $

An effect (the mirror image of a state):

$ #diagram(seq(wire($X$), effect("e"))) $

Flexible wiring: the arms of `copy`, `split` and `merge` run straight to wherever the layer
above or below needs them, instead of being bent once inside the fork and once again in a
connector band.

$ #diagram(seq(copy, tensor(morph("Bernoulli"), wire()))) quad
  #diagram(seq(copy, tensor(copy, wire()))) quad
  #diagram(seq(tensor(morph("f"), wire($Y$)), merge, wire($X times Y$))) quad
  #diagram(seq(copy, tensor(split, wire()))) $

Wires find their own x: a narrow wire layer over a wide box, a stack of three such layers, and the
coin-bias program written with the bias wire and the sampled value on separate layers. None of these
needs a connector band.

$ #diagram(seq(morph("Bernoulli"), wire($"Bool"$))) quad
  #diagram(seq(morph("Bernoulli"), wire(), wire(), wire($"Bool"$))) quad
  #diagram(seq(state("Uniform"), copy, tensor(wire(), morph("Bernoulli")), tensor(wire($[0,1]$), wire($"Bool"$)))) $

A wire held at different x at both ends bends by itself, with no band inserted:

$ #diagram(seq(
    tensor(morph("f"), morph("Bernoulli")),
    tensor(wire(), wire()),
    tensor(morph("Bernoulli"), morph("g")),
  )) $

== Inline diagrams

The copy map #diagram(copy, style: (unit: 0.45cm)) and the discard map
#diagram(discard, style: (unit: 0.45cm)) satisfy #diagram(seq(copy, tensor(wire(), discard)), style: (unit: 0.45cm))
$=$ #diagram(wire(), style: (unit: 0.45cm)), so they make every object a comonoid. At the default unit
the same term, #diagram(seq(copy, swap)), is rather large for running text, which is why inline uses
should pass a smaller `unit`, and a smaller label size when the diagram carries labels:
#diagram(seq(wire($X$), morph("f"), wire($Y$)), style: (unit: 0.5cm, label: (size: 0.8em))).

== Style overrides

A style override can target a whole diagram (the `style:` argument of `diagram`), where element
groups inherit the root `stroke` and `fill` and partial strokes fold, cetz-style:

$ #diagram(
    seq(state("Uniform"), copy, tensor(wire($"bias"$, side: "left"), morph("Bernoulli")), tensor(wire(), discard)),
    style: (unit: 1.1cm, discard: (kind: "ground"), bend: 0.7, box: (fill: rgb("#eef3ff"))),
  ) $

It can target a sub-diagram, via `styled` or the `style:` argument of `seq` and `tensor`:

$ #diagram(seq(
    state("Uniform"),
    styled(seq(copy, tensor(wire(), discard), style: (discard: (kind: "ground"))), stroke: (paint: red)),
    wire($[0,1]$),
  )) $

Or it can target a single element, whose inline `stroke` and `fill` restyle just that element:

$ #diagram(seq(wire($X$), morph("f", stroke: (paint: blue), fill: rgb("#e7f0fe")), wire($Y$, stroke: (dash: "dashed")))) $
