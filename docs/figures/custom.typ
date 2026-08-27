#import "setup.typ": *
#import "@preview/cetz:0.5.2": draw
#show: setup

#let cup = primitive(inputs: 0, outputs: 2, width: 2, height: 1, draw: (style, geometry) => {
  draw.bezier((0.5, 1), (1.5, 1), (0.5, 0.2), (1.5, 0.2), stroke: style.wire.stroke)
})
#let cap = primitive(inputs: 2, outputs: 0, width: 2, height: 1, draw: (style, geometry) => {
  draw.bezier((0.5, 0), (1.5, 0), (0.5, 0.8), (1.5, 0.8), stroke: style.wire.stroke)
})
#let spider(n, m) = primitive(inputs: n, outputs: m, draw: (style, geometry) => {
  let c = (geometry.width / 2, geometry.height / 2)
  for x in geometry.input-positions { draw.line((x, 0), c, stroke: style.wire.stroke) }
  for x in geometry.output-positions { draw.line(c, (x, geometry.height), stroke: style.wire.stroke) }
  draw.circle(c, radius: style.dot.radius, fill: style.dot.fill, stroke: none)
})
#let trapezoid(label) = primitive(
  width: (style, measure) => calc.max(1.0, measure(label).width + 2 * (style.box.inset + style.box.margin) + 0.2),
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

#fig("cup", sd(cup))
#fig("cap", sd(cap))
#fig("spider", sd(spider(3, 2)))
#fig("trapezoid", sd(trapezoid("Describe")))
#fig("snake")[
  $ #sd(serial(
      parallel(wire($X$), cup),
      parallel(cap, wire($X$)),
    )) = #sd(wire($X$, length: 2)) $
]
