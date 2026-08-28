// Behavioural tests of the public interface. They avoid pixel comparisons and
// internal fields, so that they survive changes to the drawing code.

#import "../src/lib.typ": *
#import "../src/lib.typ" as drawstring
#import "@preview/cetz:0.5.2": draw

// The exported surface is exactly the documented one, and nothing leaks.
#let exported = dictionary(drawstring).keys().sorted()
#assert.eq(
  exported,
  ("bundle", "copy", "default-style", "discard", "effect", "parallel", "primitive", "process", "serial", "state", "string-diagram", "styled", "swap", "unbundle", "wire"),
)

// Collision audit: `state` shadows Typst's builtin on purpose. A new collision,
// for instance after a Typst release, should be a deliberate decision, not a surprise.
#let shadowing = ("state",)
#for name in exported {
  assert(name in shadowing or name not in dictionary(std), message: "`" + name + "` shadows a Typst builtin")
}
#for name in shadowing {
  assert(name in dictionary(std), message: "`" + name + "` no longer shadows anything; drop it from the list")
}

// Wire counts.
#let counts(d) = (d.inputs, d.outputs)
#assert.eq(counts(wire()), (1, 1))
#assert.eq(counts(wire($X$, length: 2, side: "left")), (1, 1))
#assert.eq(counts(process("f", inputs: 2, outputs: 3)), (2, 3))
#assert.eq(counts(state("p", outputs: 2)), (0, 2))
#assert.eq(counts(effect("e", inputs: 2)), (2, 0))
#assert.eq(counts(copy), (1, 2))
#assert.eq(counts(discard), (1, 0))
#assert.eq(counts(swap), (2, 2))
#assert.eq(counts(unbundle), (1, 2))
#assert.eq(counts(bundle), (2, 1))
#assert.eq(counts(serial()), (0, 0))
#assert.eq(counts(parallel()), (0, 0))
#assert.eq(counts(serial(copy)), (1, 2))
#assert.eq(counts(serial(copy, parallel(discard, wire()))), (1, 1))
#assert.eq(counts(parallel(copy, discard, state("p"))), (2, 3))
#assert.eq(counts(styled(copy, stroke: red)), (1, 2))
#assert.eq(counts(serial(copy, swap, style: (bend: 1))), (1, 2))
#assert.eq(counts(parallel(wire(), wire(), style: (gap: 1))), (2, 2))

#let cup = primitive(inputs: 0, outputs: 2, width: 2, draw: (st, g) => ())
#let cap = primitive(inputs: 2, outputs: 0, width: 2, draw: (st, g) => ())
#assert.eq(counts(cup), (0, 2))
#assert.eq(counts(serial(parallel(wire(), cup), parallel(cap, wire()))), (1, 1))
#assert.eq(counts(primitive(inputs: 3, outputs: 1, input-positions: (0.5, 1.5, 2.5), draw: (st, g) => ())), (3, 1))

// Rendering. Sizes are compared with a tolerance, since strokes and padding
// contribute a little on top of the unit-proportional layout.
#let close(a, b, tolerance: 0.1) = calc.abs(a / b - 1) < tolerance
#context {
  let d = serial(copy, swap, parallel(discard, wire()))
  let size(..args) = measure(string-diagram(d, ..args))
  let up = size(style: (unit: 1cm))

  // An unlabelled diagram scales with the unit.
  let big = size(style: (unit: 2cm))
  assert(close(big.width, 2 * up.width), message: "width does not scale with unit")
  assert(close(big.height, 2 * up.height), message: "height does not scale with unit")

  // Flipping keeps the size; turning swaps width and height.
  let down = size(style: (unit: 1cm, direction: "down"))
  assert(close(down.width, up.width) and close(down.height, up.height), message: "direction: down changes the size")
  let right = size(style: (unit: 1cm, direction: "right"))
  assert(close(right.width, up.height) and close(right.height, up.width), message: "direction: right does not turn the diagram")
  let left = size(style: (unit: 1cm, direction: "left"))
  assert(close(left.width, right.width) and close(left.height, right.height), message: "direction: left differs from right")

  // Boxes grow to fit their labels.
  let narrow = measure(string-diagram(process("f")))
  let wide = measure(string-diagram(process("Bernoulli")))
  assert(wide.width > narrow.width * 1.5, message: "a long label does not widen its box")
  assert(close(wide.height, narrow.height), message: "a long label changes the box height")

  // A labelled wire makes room for its label. Beside it, on either side: a
  // parallel neighbour is placed after the label, so the composition is as
  // wide as its two parts, less the canvas padding they no longer have
  // between them. Along it: read sideways, the wire is as long as the label
  // plus a margin at each end, so it lengthens the diagram by that much
  // beyond the one unit an unlabelled wire has.
  let u = 1cm
  let lab = measure(string-diagram(wire("a long label"), style: (unit: u)))
  let proc = measure(string-diagram(process("f"), style: (unit: u)))
  for side in ("right", "left") {
    let both = measure(string-diagram(parallel(wire("a long label", side: side), process("f")), style: (unit: u)))
    assert(
      close(both.width, lab.width + proc.width - 2 * default-style.padding * u, tolerance: 0.02),
      message: "a parallel neighbour is not placed after a wire label on the " + side,
    )
  }
  let lw = measure(text("a long label")).width
  let plain = measure(string-diagram(serial(process("f"), wire(), process("g")), style: (unit: u, direction: "right")))
  let long = measure(string-diagram(serial(process("f"), wire("a long label"), process("g")), style: (unit: u, direction: "right")))
  assert(
    close(long.width - plain.width, lw + 2 * default-style.margin * u - u, tolerance: 0.02),
    message: "a sideways wire is not as long as its label",
  )

  // Routing keeps labels clear. Stacked on a box whose slots are a unit
  // apart, the wires and arms of the next layer follow the box's slots; one
  // whose label would then run into a neighbour, or that would run into a
  // neighbour's label, stays where it is and is carried across a connector
  // band instead. The unlabelled versions need no band, so the band is
  // exactly the labelled versions' extra height.
  let band = default-style.bend * u
  let wide = process("A very wide process", outputs: 3)
  let above(top) = measure(string-diagram(serial(wide, top), style: (unit: u))).height
  assert(
    close(above(parallel(wire("a long label"), wire(), wire())) - above(parallel(wire(), wire(), wire())), band, tolerance: 0.02),
    message: "a routed wire runs through a wire label",
  )
  let short = box(width: 0.6 * u)
  assert(
    close(above(parallel(wire(short), process("f"), wire(short, side: "left"))) - above(parallel(wire(), process("f"), wire())), band, tolerance: 0.02),
    message: "a routed wire label runs into a box",
  )
  let tall = process("A very wide process", inputs: 3)
  let below(bottom) = measure(string-diagram(serial(bottom, tall), style: (unit: u))).height
  assert(
    close(below(parallel(copy, wire("a long label", side: "left"))) - below(parallel(copy, wire())), band, tolerance: 0.02),
    message: "a routed arm ends in a wire label",
  )

  // Style overrides at every level render, in every direction.
  for dir in ("up", "down", "right", "left") {
    let styled-d = serial(
      state("Uniform"),
      styled(serial(copy, parallel(wire(), discard), style: (discard: (kind: "ground"))), stroke: (paint: red)),
      wire($[0,1]$, stroke: (dash: "dashed")),
      process("f", stroke: (paint: blue), fill: rgb("#e7f0fe")),
    )
    let s = measure(string-diagram(styled-d, style: (direction: dir, stroke: none, box: (stroke: (paint: black)))))
    assert(s.width > 0pt and s.height > 0pt)
  }

  // Edge values of numeric style keys render.
  let swapped = serial(parallel(process("Bernoulli"), process("f")), parallel(process("f"), process("Bernoulli")))
  let with-band = measure(string-diagram(swapped))
  let no-band = measure(string-diagram(swapped, style: (bend: 0)))
  assert(no-band.height < with-band.height, message: "bend: 0 does not remove the band")
  assert(close(no-band.width, with-band.width), message: "bend: 0 changes the width")
  assert(measure(string-diagram(copy, style: (wire: (arm-angle: 0)))).width > 0pt, message: "arm-angle: 0 does not render")
  let flat = measure(string-diagram(state([]), style: (triangle: (height: 0, inset: 0, margin: 0))))
  assert(flat.width > 0pt, message: "a zero-height unlabelled state does not render")

  // A custom primitive's declared size sets the canvas size, even if it draws
  // less than that.
  let dot = primitive(width: 3, height: 2, draw: (st, g) => draw.circle((1.5, 1), radius: 0.05))
  let s = measure(string-diagram(dot, style: (unit: 1cm, padding: 0)))
  assert(close(s.width, 3cm) and close(s.height, 2cm), message: "primitive: declared size does not bound the canvas")

  // A custom primitive that sizes itself to its label.
  let labelled(label) = primitive(
    width: (st, measure) => calc.max(1.0, measure(label).width + 0.4),
    draw: (st, g) => (),
  )
  let short = measure(string-diagram(labelled("f")))
  let long = measure(string-diagram(labelled("a much longer label")))
  assert(long.width > short.width * 2, message: "primitive: a measured width does not take effect")
}

The tests passed.
