# copycat

A small Typst library for drawing string diagrams in the style used for Markov categories (Fritz 2020, Cho–Jacobs 2019).
It is built on [cetz](https://typst.app/universe/package/cetz) 0.4.2.

```typst
#import "copycat/lib.typ": diagram, seq, tensor, wire, morph, state, effect, copy, discard, swap, split, merge, styled, sd-style
```

Import the names explicitly: `state` shadows a Typst builtin, and the library deliberately exports nothing called `par` or `box`.

## Conventions

Diagrams are read **bottom to top**: inputs enter at the bottom edge, outputs leave at the top edge.

Layout happens in abstract **units**, and one unit is rendered as `style.unit`.
Wire slots are one unit apart, and an element with `n` wires on an edge carries them centred within its own width.
Every generator and combinator returns a *diagram value*: a dictionary with the fields `inputs`, `outputs`, `flex-in`, `flex-out`, `width`, `height`, `in-xs`, `out-xs` and `draw`, plus a `layout` function.
`flex-in` and `flex-out` mark, per slot, the wires that may be re-aimed by whatever is composed next to them: the arms of `copy`, `split` and `merge`, and both ends of a plain `wire`.
Alongside them, `kind-in` and `kind-out` record how willing each slot is to move (rigid, wire, arm) and `flex-link` records which input slot and output slot are the two ends of the same wire.
The eagerly stored `width`, `height`, `in-xs`, `out-xs` and `draw` describe the *nominal* layout, the one you get if every label were empty.
The real layout is produced by `layout(env)`, which `diagram` calls inside `context` so that labels can be measured and boxes widened to fit them.
`draw(origin)` also accepts optional `in-over` and `out-over` arguments, which the combinators use to re-aim flexible slots.
You rarely need any of this; `inputs` and `outputs` are the only fields worth reading from outside.

## Generators

| Call | Wires | Drawing |
|---|---|---|
| `wire(label, length: 1, side: "right")` | 1 → 1 | a vertical wire, `length` units tall, with `label` set beside it. The label may also be passed as `label: ...`. `wire()` is the bare identity. Both ends are free to move sideways, and the label moves with them. |
| `morph(label, inputs: 1, outputs: 1)` | n → m | a white box with `label` inside and short wire stubs above and below, so that boxes stacked by `seq` never touch. |
| `state(label, outputs: 1)` | 0 → m | a downward-pointing triangle (apex at the bottom) whose outputs leave the flat top edge: a distribution, i.e. a kernel with trivial input. |
| `effect(label, inputs: 1)` | n → 0 | the mirror image of `state`, apex at the top. |
| `copy` | 1 → 2 | a wire rising to a black dot, from which two arms curve out to the two outputs. |
| `discard` | 1 → 0 | a wire ending in a black dot, or in a ground symbol if the style's `discard.kind` is `"ground"`. It slides sideways like a wire to sit over whatever it discards, and its dot sits at the same height as a copy's dot (`dot.height`), below every arm crossing the layer. |
| `swap` | 2 → 2 | two wires crossing. |
| `split` | 1 → 2 | a fork *without* a dot, for drawing one product wire `X × Y` as two wires. |
| `merge` | 2 → 1 | the mirror image of `split`. |

The arms of `copy`, `split` and `merge` are flexible: they end wherever the neighbouring layer needs them, rather than at fixed slots.
So is a plain `wire`, which is why a narrow layer of wires stacked over a wide box comes out straight rather than kinked.

`copy`, `discard`, `swap`, `split` and `merge` are plain values, not functions: write `copy`, not `copy()`.
To restyle one of them, wrap it in `styled` (see below).
`morph`, `state` and `effect` also take `stroke` and `fill` arguments, and `wire` a `stroke` argument, restyling just that element, including its wire stubs; `auto` inherits from the style and `none` disables.

Boxes and triangles grow to fit their labels, so `morph("Bernoulli")` is a wide box, not a clipped one.
Labels are ordinary Typst content: a string is typeset upright as it stands, and `$X$` gets you math.

## Combinators

`seq(..ds)` composes sequentially, with **the first argument at the bottom**.
Output slot j of each diagram is connected to input slot j of the one above it, and composing diagrams whose wire counts disagree is an error.
Children are centred horizontally within the widest of them, so connected slots often do not line up, and rather than bending the connection, `seq` moves the wires that are free to move.
It sweeps the stack twice, once upwards and once downwards.
A box holds its slots where they are, a wire follows the box or wire it faces and carries its whole column, including its label, along with it, and the arm of a `copy` yields to either.
A wire that is held at two different x, by a box below and another box above, becomes a smooth S-curve over its own length, and a `copy` arm runs from its dot straight to its target, leaving the dot at an angle and arriving vertically, which is how these diagrams are drawn on paper.
What is left over is a pair that is rigid on both sides, which is rare; only then is a band of `style.bend` units inserted.
Every slot at such a junction is carried across the band: flexible wires reach through it themselves, and each rigid pair is drawn as an S-curve, or as a straight line where its two slots agree.
A wire refuses to move into a box standing next to it, and falls back to the band instead.

`tensor(..ds)` composes in parallel, left to right, adding widths and inserting `style.gap` between neighbours.
Children shorter than the tallest one are centred vertically and their wires are extended straight to the common bottom and top edges.
A child with no outputs (such as `discard`) is aligned with the bottom edge instead, and one with no inputs (such as a state) with the top edge, since their only connections are on that side.

Both combinators return a single argument unchanged, and both accept no arguments at all, which gives the empty diagram.
Both also accept a `style:` argument that overrides style keys for the sub-diagram they build.

`styled(d, ..overrides)` is the same thing as a standalone wrapper: `styled(copy, stroke: red)` is a red copy, and `styled(d, box: (fill: blue))` restyles every box inside `d`.
`unit` and `padding` describe the diagram as a whole, so overriding them for a sub-diagram is an error; pass them to `diagram` instead.

## Rendering

`diagram(d, style: (:), baseline: auto)` turns a diagram value into content.
`style` is merged over `sd-style` with cetz's folding rules (see below), so `style: (stroke: (paint: red))` keeps the default thickness.
The result is a box whose baseline is shifted so that the diagram's vertical centre lands on the math axis, which is what makes `$ #diagram(a) = #diagram(b) $` put the `=` between the two diagrams rather than under them.
Pass `baseline` explicitly to override that.

## Style

The style follows [cetz's model](https://cetz-package.github.io/docs/basics/custom-types/style): generic keys at the root, one group of keys per kind of element, and `auto` meaning "inherit the root key of the same name".
Strokes fold like in cetz: a partial stroke such as `(paint: red)` or `(dash: "dashed")` changes only what it names, while a full stroke like `red + 1pt` replaces the inherited one.
A partial stroke without a paint disappears together with the stroke it folds onto, so `stroke: none` hides boxes, triangles and dots along with the wires, and a more local override brings an element back only by naming a paint.
Unknown keys are rejected with an error, so typos do not pass silently.

Root keys:

| Key | Meaning |
|---|---|
| `unit` | length of one abstract unit; may be given in `em` to scale with the text |
| `stroke` | base stroke, inherited by every element stroke that is `auto` |
| `fill` | base fill of solid shapes (boxes and triangles) |
| `inset` | padding around a label inside a box or triangle |
| `margin` | horizontal gap between a shape and its slot boundary, so that neighbours keep their distance |
| `stub` | length of the wire stubs above and below a box |
| `bend` | height of the S-bend band inserted by `seq` |
| `gap` | extra space between `tensor` factors |
| `padding` | canvas padding, so that strokes are not clipped |

Element groups:

| Key | Meaning |
|---|---|
| `wire.stroke` | stroke of all wires |
| `wire.arm-angle` | sideways reach, in multiples of the rise, at which a fork's arm starts leaving the dot at an angle rather than vertically |
| `box.stroke`, `box.fill` | stroke and fill of morphism boxes |
| `box.height` | minimum height of a morphism box |
| `box.inset`, `box.margin` | inset and margin of boxes; `auto` inherits the root keys |
| `triangle.stroke`, `triangle.fill` | stroke and fill of state and effect triangles |
| `triangle.height` | minimum height of a triangle |
| `triangle.aspect` | width/height a triangle aims for before it grows taller instead |
| `triangle.inset`, `triangle.margin` | as for boxes |
| `dot.radius` | radius of the copy and discard dots |
| `dot.height` | height of the dots above their junction, and of the branch point of `split` and `merge` |
| `dot.fill` | fill of the dots; `auto` follows the wire paint rather than the root fill |
| `discard.kind` | `"dot"` or `"ground"` |
| `label.size` | text size of all labels |
| `label.sep` | distance of a wire label from its wire |

Plain numbers are in units; `unit`, `label.size` and stroke thicknesses are Typst lengths.
The default values live in `sd-style` at the top of `lib.typ`.

A style can be overridden at three levels: the whole diagram, a sub-diagram, or a single element.

```typst
#diagram(d, style: (stroke: red))  // recolours wires, boxes and dots alike
styled(d, box: (fill: blue))       // likewise seq(a, b, style: (bend: 0.8))
morph("f", stroke: red)            // this box only, stubs included
```

## Examples

```typst
$ #diagram(seq(state("Uniform"), wire($[0,1]$), morph("Bernoulli"), wire($"Bool"$))) $

$ #diagram(seq(copy, tensor(discard, wire()))) = #diagram(wire()) $
```

`examples.typ` in this directory renders the full repertoire and can be compiled on its own.

## Diagrams in running text

Inline diagrams keep the default unit, which is generous for 11 pt text, so pass a smaller one:
`#diagram(copy, style: (unit: 0.45cm))`.
Labels do not shrink with `unit`, because their size follows the surrounding text; shrink them too with `label: (size: 0.8em)` if a labelled diagram looks top-heavy inline.

A wire label is placed to the right of its wire by default, which collides with whatever stands to the right of it in a `tensor`.
Move it with `wire($X$, side: "left")`.
