// copycat — string diagrams for Markov categories, built on cetz.
// Diagrams are read bottom to top: inputs enter at the bottom, outputs leave at the top.

#import "@preview/cetz:0.4.2"

// Aliased rather than imported, so that `#import "lib.typ": *` does not shadow
// Typst's own `line`, `rect`, `circle` and `content`.
#let (_bezier, _circle, _content, _line, _rect) = (
  cetz.draw.bezier, cetz.draw.circle, cetz.draw.content, cetz.draw.line, cetz.draw.rect,
)

// ------------------------------------------------------------------- styling
//
// The style follows cetz's model: generic keys at the root of `sd-style`, one
// group per kind of element, and `auto` meaning "inherit the root key of the
// same name". Values combine with cetz's folding rules, so a partial stroke
// such as `(paint: red)` recolours a wire without changing its thickness.
// A style can be overridden at three levels:
//   - the whole diagram:  `diagram(d, style: (stroke: red))`
//   - a sub-diagram:      `styled(d, box: (fill: blue))`, or the `style:`
//                         argument of `seq` and `tensor`
//   - a single element:   `morph("f", stroke: red)`, where `auto` inherits
//                         and `none` disables.
// Plain numbers are abstract units and scale with `unit`; typst lengths are
// absolute.

/// Default style.
#let sd-style = (
  unit: 2em,             // length of one abstract unit
  padding: 0.1,          // canvas padding, so strokes are not clipped
  // Base stroke, inherited by every `auto` stroke below. Kept in dictionary
  // form: cetz folds a partial override into a dictionary field by field, but
  // over a stroke *value* it would fill the fields the override omits with
  // typst's defaults instead of these.
  stroke: (paint: black, thickness: 0.7pt),
  fill: white,           // base fill of solid shapes (boxes and triangles)
  inset: 0.1,            // padding around a label inside a box or triangle
  margin: 0.1,           // horizontal gap between a shape and its slot boundary
  stub: 0.2,             // wire stub above/below a box, so boxes never touch
  bend: 0.5,             // height of the S-bend band inserted by `seq`
  gap: 0.0,              // extra horizontal space between `tensor` factors
  wire: (
    stroke: auto,
    arm-angle: 0.1,      // sideways reach, in multiples of the rise, at which
                         // the arm of a fork starts leaving its dot at an angle
  ),
  box: (
    stroke: (thickness: 0.6pt),
    fill: auto,
    height: 0.75,        // minimum height of a morphism box
    inset: auto,
    margin: auto,
  ),
  triangle: (
    stroke: (thickness: 0.6pt),
    fill: auto,
    height: 0.75,        // minimum height of a state/effect triangle
    aspect: 2.5,         // width/height a triangle aims for before growing taller
    inset: auto,
    margin: auto,
  ),
  dot: (
    radius: 0.1,
    height: 0.2,         // height of the copy and discard dots above their
                         // junction, and of the branch point of split/merge
    fill: auto,          // `auto` follows the wire paint, not the root fill
  ),
  discard: (
    kind: "dot",         // "dot" or "ground"
  ),
  label: (
    size: 1em,
    sep: 0.1,            // distance of a wire label from its wire
  ),
)

// The paint of a stroke given in any of the forms typst accepts.
#let _paint(s) = {
  if s == none {
    none
  } else if type(s) == dictionary {
    s.at("paint", default: black)
  } else if type(s) == std.stroke {
    if s.paint == auto { black } else { s.paint }
  } else if type(s) in (color, gradient, tiling) {
    s
  } else {
    black
  }
}

#let _resolve-dot-fill(raw, st) = {
  if raw.at("dot", default: (:)).at("fill", default: auto) == auto {
    st.dot.fill = _paint(st.wire.stroke)
  }
  st
}

// A stroke of `none` cannot fold: cetz would let a later partial override
// restart from typst's stroke defaults, so a paintless partial over a
// disabled stroke would silently come back black. Disabled strokes are
// therefore carried as `(paint: none)`, which folds like any stroke — an
// override revives it only by naming a paint — and `_use-stroke` turns
// whatever still has no paint back into `none` at the point of drawing.
#let _no-stroke = (paint: none)

// Strokes that later overrides fold onto must be dictionaries: cetz merges a
// partial override into a dictionary field by field, but folds it over a
// stroke *value* by filling the omitted fields with typst's defaults, which
// would clobber the base. A full stroke value still replaces wholesale,
// because `resolve-stroke` expands every field explicitly.
#let _normalize-stroke(v) = {
  if v == none { _no-stroke } else if type(v) == std.stroke { cetz.util.resolve-stroke(v) } else { v }
}

#let _normalize-style(over) = {
  // A group key that is `auto` inherits the root key at resolve time, but a
  // root-level `auto` has no ancestor to inherit from and would end up as a
  // literal `auto` stroke, i.e. cetz's defaults. At the root, `auto` therefore
  // means "no override": the key is dropped and the surrounding style shows
  // through.
  let over = over.pairs().filter(((_, v)) => v != auto).to-dict()
  if "stroke" in over { over.stroke = _normalize-stroke(over.stroke) }
  for k in ("wire", "box", "triangle") {
    let g = over.at(k, default: auto)
    if type(g) == dictionary and "stroke" in g {
      g.stroke = _normalize-stroke(g.stroke)
      over.insert(k, g)
    }
  }
  over
}

#let _use-stroke(s) = if type(s) == dictionary and s.at("paint", default: auto) == none { none } else { s }

// Precomputed so that unstyled diagrams do not pay for style resolution at
// every element.
#let _sd-resolved = _resolve-dot-fill(sd-style, cetz.styles.resolve(sd-style))

// Resolve a raw style: `auto` entries inherit the root key of the same name,
// and partial strokes fold with the stroke they inherit from.
#let _resolve(style) = if style == sd-style { _sd-resolved } else {
  _resolve-dot-fill(style, cetz.styles.resolve(style))
}

// Fold inline element overrides into one group of a resolved style.
#let _group(st, root, over) = cetz.styles.resolve(st, root: root, merge: over)

// Reject unknown style keys early, so that a typo fails with a clear message.
// Stroke values are checked against the stroke fields rather than the default
// dictionary's keys, which spell out only a paint and a thickness.
#let _stroke-keys = ("paint", "thickness", "cap", "join", "miter-limit", "dash")

#let _check-stroke(v, path) = if type(v) == dictionary {
  for k in v.keys() {
    assert(
      k in _stroke-keys,
      message: "unknown stroke key `" + path + "." + k + "`; valid keys: " + _stroke-keys.join(", "),
    )
  }
}

#let _check-style(over) = {
  for (k, v) in over {
    assert(k in sd-style, message: "unknown style key `" + k + "`; valid keys: " + sd-style.keys().join(", "))
    let base = sd-style.at(k)
    if k == "stroke" {
      _check-stroke(v, k)
    } else if type(v) == dictionary and type(base) == dictionary {
      for (kk, vv) in v {
        assert(
          kk in base,
          message: "unknown style key `" + k + "." + kk + "`; valid keys: " + base.keys().join(", "),
        )
        if kk == "stroke" { _check-stroke(vv, k + "." + kk) }
      }
    }
  }
}

/// Wire slot k of an n-wire element, centred within `width`.
#let _slots(n, width) = range(n).map(k => width / 2 + k - (n - 1) / 2)

// Measurement is only possible inside `context`; outside we fall back to a
// nominal layout, which is what the eagerly computed dictionary fields hold.
#let _nominal-env = (style: sd-style, unit: 1cm, measured: false)

#let _measure(env, st, body) = if env.measured {
  let s = measure(text(size: st.label.size, body))
  (s.width / env.unit, s.height / env.unit)
} else {
  (0.0, 0.0)
}

#let _label(st, body) = text(size: st.label.size, body)

// ---------------------------------------------------------------- slot kinds
//
// 0  rigid  — the slot sits where the element puts it (a box, a triangle).
// 1  wire   — a plain wire, which may be drawn at any x but prefers its own.
// 2  arm    — the arm of a copy, split or merge, which goes wherever it is told.
//
// `link` maps an input slot to the output slot it is the same wire as, if any;
// moving one end of such a column moves the other, unless that end is held.

#let _zeros(n) = range(n).map(_ => 0)
#let _nones(n) = range(n).map(_ => none)

#let _mk(inputs, outputs, layout, kind-in: none, kind-out: none, link: none) = {
  let ki = if kind-in == none { _zeros(inputs) } else { kind-in }
  let ko = if kind-out == none { _zeros(outputs) } else { kind-out }
  (
    inputs: inputs,
    outputs: outputs,
    kind-in: ki,
    kind-out: ko,
    flex-in: ki.map(k => k > 0),
    flex-out: ko.map(k => k > 0),
    flex-link: if link == none { _nones(inputs) } else { link },
    layout: layout,
  ) + layout(_nominal-env)
}

// The output slot each input slot is linked to, read backwards.
#let _inv-link(d) = {
  let out = _nones(d.outputs)
  for (k, v) in d.flex-link.enumerate() {
    if v != none { out.at(v) = k }
  }
  out
}

// How strong a claim a slot has on its x: rigid slots win over wires, wires
// over arms, and a slot that has already been pinned keeps its source's claim.
#let _offer(kind, auth) = if kind == 0 { 0 } else if auth == 3 { kind } else { auth }

// A wire may not be moved into a solid shape it does not already sit in.
#let _free-x(l, dx, nominal, x) = l.spans.all(sp => {
  let (a, b) = (sp.at(0) + dx, sp.at(1) + dx)
  not (a < x and x < b) or (a < nominal and nominal < b)
})

// ------------------------------------------------------------------ overrides
//
// A flexible slot can be told to end somewhere other than its natural place.
// An override is an array with one entry per slot: either `none`, or a pair
// `(x, reach)` giving the target's x in the element's own coordinates and how
// far beyond the element's edge it lies.

#let _norm(over) = if over == none or over.all(v => v == none) { none } else { over }

#let _shift(over, dx, extra) = if over == none { none } else {
  over.map(v => if v == none { none } else { (v.at(0) - dx, v.at(1) + extra) })
}

#let _slice(over, start, count) = if over == none { none } else {
  _norm(over.slice(start, start + count))
}

#let _prefer(over, fallback) = if over == none { fallback } else if fallback == none { over } else {
  over.enumerate().map(((k, v)) => if v == none { fallback.at(k) } else { v })
}

#let _entry(nominal, x, reach) = if calc.abs(x - nominal) < 1e-6 and reach == 0.0 { none } else { (x, reach) }

// Elements without flexible slots keep the plain `draw(origin)` signature.
#let _draw(l, pos, in-over: none, out-over: none) = {
  let (i, o) = (_norm(in-over), _norm(out-over))
  if i == none and o == none { (l.draw)(pos) } else { (l.draw)(pos, in-over: i, out-over: o) }
}

// ---------------------------------------------------------------- generators

/// The monoidal unit: no wires, no extent.
#let _empty = _mk(0, 0, _env => (
  width: 0.0, height: 0.0, in-xs: (), out-xs: (), spans: (),
  draw: _o => (),
))

// An S-curve with vertical tangents at both ends.
#let _sbend(a, b, s) = {
  let (ax, ay) = a
  let (bx, by) = b
  if calc.abs(ax - bx) < 1e-6 {
    _line(a, b, stroke: s)
  } else {
    let d = (by - ay) * 0.55
    _bezier(a, b, (ax, ay + d), (bx, by - d), stroke: s)
  }
}

// Where a flexible slot ends up, given an override and its natural place.
#let _target(over, k, x, y, dir) = {
  let v = if over == none { none } else { over.at(k) }
  if v == none { (x, y) } else { (v.at(0), y + dir * v.at(1)) }
}

/// A plain vertical wire, optionally labelled beside it. Both of its ends are
/// flexible: the wire is drawn wherever the diagrams above and below need it,
/// and bends smoothly if the two ends disagree.
#let wire(..args, label: none, length: 1, side: "right", stroke: auto) = {
  assert(args.pos().len() <= 1, message: "wire: expected at most one positional argument (the label)")
  assert(args.named().len() == 0, message: "wire: unknown argument(s) " + args.named().keys().map(repr).join(", "))
  assert(side in ("left", "right"), message: "wire: `side` must be \"left\" or \"right\"")
  let label = if args.pos().len() == 1 { args.pos().first() } else { label }
  _mk(1, 1, env => {
    let st = _resolve(env.style)
    let stroke = if stroke == none { _no-stroke } else { stroke }
    let ws = _use-stroke(if stroke == auto { st.wire.stroke } else { _group(st, "wire", (stroke: stroke)).stroke })
    (
      width: 1.0,
      height: length * 1.0,
      in-xs: (0.5,),
      out-xs: (0.5,),
      spans: (),
      draw: (o, in-over: none, out-over: none) => {
        let (ox, oy) = o
        let (bx, by) = _target(in-over, 0, 0.5, 0.0, -1)
        let (tx, ty) = _target(out-over, 0, 0.5, length, 1)
        _sbend((ox + bx, oy + by), (ox + tx, oy + ty), ws)
        if label != none {
          let d = if side == "right" { st.label.sep } else { -st.label.sep }
          _content(
            (ox + (bx + tx) / 2 + d, oy + (by + ty) / 2),
            _label(st, label),
            anchor: if side == "right" { "west" } else { "east" },
          )
        }
      },
    )
  }, kind-in: (1,), kind-out: (1,), link: (0,))
}

/// A morphism box with `inputs` wires entering at the bottom and `outputs`
/// leaving at the top. The box widens to fit its label. An inline `stroke`
/// or `fill` restyles this one box (and its wire stubs).
#let morph(label, inputs: 1, outputs: 1, stroke: auto, fill: auto) = _mk(inputs, outputs, env => {
  let st = _resolve(env.style)
  let stroke = if stroke == none { _no-stroke } else { stroke }
  let bst = if stroke == auto and fill == auto { st.box } else {
    _group(st, "box", (stroke: stroke, fill: fill))
  }
  bst.stroke = _use-stroke(bst.stroke)
  let ws = _use-stroke(if stroke == auto { st.wire.stroke } else { _group(st, "wire", (stroke: stroke)).stroke })
  let (lw, lh) = _measure(env, st, label)
  let m = bst.margin
  let w = calc.max(calc.max(inputs, outputs, 1) * 1.0, lw + 2 * (bst.inset + m))
  let bh = calc.max(bst.height, lh + 2 * bst.inset)
  let ins = _slots(inputs, w)
  let outs = _slots(outputs, w)
  (
    width: w,
    height: bh + 2 * st.stub,
    in-xs: ins,
    out-xs: outs,
    spans: ((m, w - m),),
    draw: o => {
      let (ox, oy) = o
      let y0 = oy + st.stub
      let y1 = y0 + bh
      for x in ins { _line((ox + x, oy), (ox + x, y0), stroke: ws) }
      for x in outs { _line((ox + x, y1), (ox + x, y1 + st.stub), stroke: ws) }
      _rect((ox + m, y0), (ox + w - m, y1), fill: bst.fill, stroke: bst.stroke)
      _content((ox + w / 2, (y0 + y1) / 2), _label(st, label))
    },
  )
})

// Geometry shared by `state` and `effect`: a triangle of width `w` and height
// `t` that is wide enough for the label at the level of the label's far edge.
#let _tri-geometry(env, st, tst, label, wires) = {
  let (lw, lh) = _measure(env, st, label)
  let m = tst.margin
  let pad = tst.inset
  let padv = pad * 1.4
  // The label sits just below the flat edge, so the triangle has to be `a` wide
  // at the label's far side, which is `b` away from that edge.
  let a = lw + 2 * pad
  let b = lh + padv
  let t = calc.max(tst.height, b + a / tst.aspect)
  let iw = calc.max(calc.max(wires, 1) * 1.0 - 2 * m, a * t / (t - b))
  (w: iw + 2 * m, m: m, t: t, lh: lh, pad: padv)
}

#let _tri-style(st, stroke, fill) = {
  let stroke = if stroke == none { _no-stroke } else { stroke }
  let (tst, ws) = if stroke == auto and fill == auto {
    (st.triangle, st.wire.stroke)
  } else {
    (
      _group(st, "triangle", (stroke: stroke, fill: fill)),
      if stroke == auto { st.wire.stroke } else { _group(st, "wire", (stroke: stroke)).stroke },
    )
  }
  tst.stroke = _use-stroke(tst.stroke)
  (tst, _use-stroke(ws))
}

/// A state: a downward-pointing triangle (apex at the bottom) whose outputs
/// leave the flat top edge. This is a distribution, i.e. a kernel with trivial
/// input.
#let state(label, outputs: 1, stroke: auto, fill: auto) = _mk(0, outputs, env => {
  let st = _resolve(env.style)
  let (tst, ws) = _tri-style(st, stroke, fill)
  let g = _tri-geometry(env, st, tst, label, outputs)
  let outs = _slots(outputs, g.w)
  (
    width: g.w,
    height: g.t + st.stub,
    in-xs: (),
    out-xs: outs,
    spans: ((g.m, g.w - g.m),),
    draw: o => {
      let (ox, oy) = o
      let top = oy + g.t
      for x in outs { _line((ox + x, top), (ox + x, top + st.stub), stroke: ws) }
      _line(
        (ox + g.m, top), (ox + g.w - g.m, top), (ox + g.w / 2, oy),
        close: true, fill: tst.fill, stroke: tst.stroke,
      )
      _content((ox + g.w / 2, top - g.pad - g.lh / 2), _label(st, label))
    },
  )
})

/// An effect: the mirror image of `state`, apex at the top.
#let effect(label, inputs: 1, stroke: auto, fill: auto) = _mk(inputs, 0, env => {
  let st = _resolve(env.style)
  let (tst, ws) = _tri-style(st, stroke, fill)
  let g = _tri-geometry(env, st, tst, label, inputs)
  let ins = _slots(inputs, g.w)
  (
    width: g.w,
    height: g.t + st.stub,
    in-xs: ins,
    out-xs: (),
    spans: ((g.m, g.w - g.m),),
    draw: o => {
      let (ox, oy) = o
      let bot = oy + st.stub
      for x in ins { _line((ox + x, oy), (ox + x, bot), stroke: ws) }
      _line(
        (ox + g.m, bot), (ox + g.w - g.m, bot), (ox + g.w / 2, bot + g.t),
        close: true, fill: tst.fill, stroke: tst.stroke,
      )
      _content((ox + g.w / 2, bot + g.pad + g.lh / 2), _label(st, label))
    },
  )
})

// An arm of a fork: it arrives at `b` vertically, and leaves `a` vertically as
// long as the target is roughly overhead, turning towards the target as the
// sideways reach grows.
#let _arm(st, a, b, s) = {
  let (ax, ay) = a
  let (bx, by) = b
  let (dx, dy) = (bx - ax, by - ay)
  if calc.abs(dx) < 1e-6 {
    _line(a, b, stroke: s)
  } else {
    let reach = calc.abs(dx) / calc.max(calc.abs(dy), 1e-6)
    let slant = calc.min(1.0, calc.max(0.0, (reach - st.wire.arm-angle) / st.wire.arm-angle))
    _bezier(a, b, (ax + 0.55 * dx * slant, ay + 0.55 * dy), (bx, by - 0.55 * dy), stroke: s)
  }
}

/// Copying: one wire rises to a dot from which two arms curve to the outputs.
/// The outputs are flexible: they go wherever the diagram above needs them.
#let copy = _mk(1, 2, env => {
  let st = _resolve(env.style)
  let ws = _use-stroke(st.wire.stroke)
  (
    width: 2.0, height: 1.0, in-xs: (1.0,), out-xs: (0.5, 1.5), spans: (),
    draw: (o, in-over: none, out-over: none) => {
      let (ox, oy) = o
      let f = (ox + 1, oy + st.dot.height)
      _line((ox + 1, oy), f, stroke: ws)
      for (k, x) in (0.5, 1.5).enumerate() {
        let (tx, ty) = _target(out-over, k, x, 1.0, 1)
        _arm(st, f, (ox + tx, oy + ty), ws)
      }
      _circle(f, radius: st.dot.radius, fill: st.dot.fill, stroke: none)
    },
  )
}, kind-out: (2, 2))

/// Discarding: a wire ending in a dot (or in a ground symbol, with
/// `discard: (kind: "ground")`). Like a wire, it slides sideways to sit over
/// whatever it discards. Its dot sits at the same height as a copy's dot
/// (`dot.height`): arms only ever climb from that height, so no arm crossing
/// this layer can run through the discard's dot.
#let discard = _mk(1, 0, env => {
  let st = _resolve(env.style)
  assert(st.discard.kind in ("dot", "ground"), message: "discard: `kind` must be \"dot\" or \"ground\"")
  let ws = _use-stroke(st.wire.stroke)
  let ground = st.discard.kind == "ground"
  let h = if ground { st.dot.height + 0.25 } else { st.dot.height + st.dot.radius }
  (
    width: 1.0, height: h, in-xs: (0.5,), out-xs: (), spans: (),
    draw: (o, in-over: none, out-over: none) => {
      let (ox, oy) = o
      let (x, by) = _target(in-over, 0, 0.5, 0.0, -1)
      _line((ox + x, oy + by), (ox + x, oy + st.dot.height), stroke: ws)
      if ground {
        for (half, dy) in ((0.26, 0.0), (0.16, 0.13), (0.07, 0.24)) {
          _line((ox + x - half, oy + st.dot.height + dy), (ox + x + half, oy + st.dot.height + dy), stroke: ws)
        }
      } else {
        _circle((ox + x, oy + st.dot.height), radius: st.dot.radius, fill: st.dot.fill, stroke: none)
      }
    },
  )
}, kind-in: (1,))

/// The symmetry: two wires crossing.
#let swap = _mk(2, 2, env => {
  let ws = _use-stroke(_resolve(env.style).wire.stroke)
  (
    width: 2.0, height: 1.0, in-xs: (0.5, 1.5), out-xs: (0.5, 1.5), spans: (),
    draw: o => {
      let (ox, oy) = o
      _sbend((ox + 0.5, oy), (ox + 1.5, oy + 1), ws)
      _sbend((ox + 1.5, oy), (ox + 0.5, oy + 1), ws)
    },
  )
})

/// Drawing a product wire X (times) Y as two separate wires: a fork with no dot.
#let split = _mk(1, 2, env => {
  let st = _resolve(env.style)
  let ws = _use-stroke(st.wire.stroke)
  (
    width: 2.0, height: 1.0, in-xs: (1.0,), out-xs: (0.5, 1.5), spans: (),
    draw: (o, in-over: none, out-over: none) => {
      let (ox, oy) = o
      let f = (ox + 1, oy + st.dot.height)
      _line((ox + 1, oy), f, stroke: ws)
      for (k, x) in (0.5, 1.5).enumerate() {
        let (tx, ty) = _target(out-over, k, x, 1.0, 1)
        _arm(st, f, (ox + tx, oy + ty), ws)
      }
    },
  )
}, kind-out: (2, 2))

/// The mirror image of `split`: two wires drawn as one product wire.
#let merge = _mk(2, 1, env => {
  let st = _resolve(env.style)
  let ws = _use-stroke(st.wire.stroke)
  (
    width: 2.0, height: 1.0, in-xs: (0.5, 1.5), out-xs: (1.0,), spans: (),
    draw: (o, in-over: none, out-over: none) => {
      let (ox, oy) = o
      let f = (ox + 1, oy + 1 - st.dot.height)
      for (k, x) in (0.5, 1.5).enumerate() {
        let (tx, ty) = _target(in-over, k, x, 0.0, -1)
        _arm(st, f, (ox + tx, oy + ty), ws)
      }
      _line(f, (ox + 1, oy + 1), stroke: ws)
    },
  )
}, kind-in: (2, 2))

// --------------------------------------------------------------- combinators

/// A copy of a diagram with some style keys overridden, e.g.
/// `styled(copy, stroke: red)` or `styled(d, box: (fill: blue))`.
#let styled(d, ..style) = {
  assert(style.pos().len() == 0, message: "styled: style overrides must be named, e.g. `styled(d, stroke: red)`")
  let over = style.named()
  _check-style(over)
  for k in ("unit", "padding") {
    assert(k not in over, message: "styled: `" + k + "` applies to a whole diagram; pass it to `diagram` instead")
  }
  let over = _normalize-style(over)
  _mk(
    d.inputs, d.outputs,
    kind-in: d.kind-in, kind-out: d.kind-out, link: d.flex-link,
    env => (d.layout)(env + (style: cetz.styles.merge(env.style, over))),
  )
}

// The optional `style:` argument of `seq` and `tensor`, applied via `styled`.
#let _combinator-style(name, args) = {
  let bad = args.named().keys().filter(k => k != "style")
  assert(bad.len() == 0, message: name + ": unknown named argument(s) " + bad.map(repr).join(", "))
  args.named().at("style", default: (:))
}

#let _apply-style(d, style) = if style == (:) { d } else { styled(d, ..style) }

// An input slot of a `seq` is the same wire as an output slot if the link
// survives every layer in between.
#let _chain-links(ds) = range(ds.first().inputs).map(k => {
  let j = k
  for d in ds {
    if j == none { break }
    j = d.flex-link.at(j)
  }
  j
})

/// Sequential composition, first argument at the bottom. An optional `style:`
/// argument overrides style keys for this sub-diagram.
#let seq(..args) = {
  let style = _combinator-style("seq", args)
  let ds = args.pos()
  if ds.len() == 0 { return _apply-style(_empty, style) }
  if ds.len() == 1 { return _apply-style(ds.first(), style) }
  for i in range(ds.len() - 1) {
    let (a, b) = (ds.at(i), ds.at(i + 1))
    assert(
      a.outputs == b.inputs,
      message: "seq: argument " + str(i + 1) + " has " + str(a.outputs) + " output(s) but argument "
        + str(i + 2) + " has " + str(b.inputs) + " input(s)",
    )
  }
  _apply-style(_mk(
    ds.first().inputs, ds.last().outputs,
    kind-in: ds.first().kind-in,
    kind-out: ds.last().kind-out,
    link: _chain-links(ds),
    env => {
      let n = ds.len()
      let ls = ds.map(d => (d.layout)(env))
      let ws = _use-stroke(_resolve(env.style).wire.stroke)
      let w = calc.max(..ls.map(l => l.width))
      let dxs = ls.map(l => (w - l.width) / 2)
      let invs = ds.map(_inv-link)
      // Natural slot positions, and the resolved ones with the claim behind them.
      let nb = ls.enumerate().map(((i, l)) => l.in-xs.map(x => x + dxs.at(i)))
      let nt = ls.enumerate().map(((i, l)) => l.out-xs.map(x => x + dxs.at(i)))
      let (bx, tx) = (nb, nt)
      let ba = ds.map(d => d.kind-in.map(k => if k == 0 { 0 } else { 3 }))
      let ta = ds.map(d => d.kind-out.map(k => if k == 0 { 0 } else { 3 }))

      // Bottom-up: every flexible slot adopts the x of the slot below it,
      // unless that slot has a weaker claim; a wire hands the x on to its far
      // end, so a whole wire column follows the box it stands on.
      for i in range(n - 1) {
        for k in range(ds.at(i).outputs) {
          let kb = ds.at(i + 1).kind-in.at(k)
          if kb == 0 { continue }
          let claim = _offer(ds.at(i).kind-out.at(k), ta.at(i).at(k))
          if claim > _offer(kb, ba.at(i + 1).at(k)) { continue }
          let x = tx.at(i).at(k)
          if kb == 1 and not _free-x(ls.at(i + 1), dxs.at(i + 1), nb.at(i + 1).at(k), x) { continue }
          bx.at(i + 1).at(k) = x
          ba.at(i + 1).at(k) = claim
          let j = ds.at(i + 1).flex-link.at(k)
          if j != none {
            let kf = ds.at(i + 1).kind-out.at(j)
            let af = ta.at(i + 1).at(j)
            let held = af != 3 and claim >= _offer(kf, af)
            if kf != 0 and not held and (kf != 1 or _free-x(ls.at(i + 1), dxs.at(i + 1), nt.at(i + 1).at(j), x)) {
              tx.at(i + 1).at(j) = x
              ta.at(i + 1).at(j) = claim
            }
          }
        }
      }
      // Top-down: the same from above, for slots that are not yet held.
      for i in range(n - 1).rev() {
        for k in range(ds.at(i).outputs) {
          let ka = ds.at(i).kind-out.at(k)
          if ka == 0 { continue }
          let claim = _offer(ds.at(i + 1).kind-in.at(k), ba.at(i + 1).at(k))
          if claim > _offer(ka, ta.at(i).at(k)) { continue }
          let x = bx.at(i + 1).at(k)
          if ka == 1 and not _free-x(ls.at(i), dxs.at(i), nt.at(i).at(k), x) { continue }
          tx.at(i).at(k) = x
          ta.at(i).at(k) = claim
          let j = invs.at(i).at(k)
          if j != none {
            let kf = ds.at(i).kind-in.at(j)
            let af = ba.at(i).at(j)
            let held = af != 3 and claim >= _offer(kf, af)
            if kf != 0 and not held and (kf != 1 or _free-x(ls.at(i), dxs.at(i), nb.at(i).at(j), x)) {
              bx.at(i).at(j) = x
              ba.at(i).at(j) = claim
            }
          }
        }
      }

      // Whatever still disagrees is rigid on both sides (or a wire that was not
      // allowed to move) and needs a connector band. Once a band exists, every
      // pair must be carried across it: flexible slots reach through it
      // themselves, and the connector loop below owns all rigid-rigid pairs,
      // straight or not.
      let js = range(n - 1).map(i => {
        let mism = range(ds.at(i).outputs).filter(k =>
          calc.abs(tx.at(i).at(k) - bx.at(i + 1).at(k)) > 1e-6)
        let band = if mism.len() > 0 { env.style.bend } else { 0.0 }
        let conn = if band == 0.0 { () } else {
          range(ds.at(i).outputs).filter(k => k in mism or (
            ds.at(i).kind-out.at(k) == 0 and ds.at(i + 1).kind-in.at(k) == 0
          ))
        }
        (band: band, mism: mism, conn: conn)
      })
      let ys = ()
      let y = 0.0
      for (i, l) in ls.enumerate() {
        ys.push(y)
        y += l.height + js.at(i, default: (band: 0.0)).band
      }

      // How far each flexible slot has to reach beyond its element's edge to
      // bridge the band, and where it has to land.
      let iovs = range(n).map(i => range(ds.at(i).inputs).map(k => {
        if ds.at(i).kind-in.at(k) == 0 { return none }
        let reach = if i == 0 { 0.0 } else {
          let j = js.at(i - 1)
          if k in j.mism { 0.0 } else if ds.at(i - 1).kind-out.at(k) > 0 { j.band / 2 } else { j.band }
        }
        _entry(nb.at(i).at(k), bx.at(i).at(k), reach)
      }))
      let oovs = range(n).map(i => range(ds.at(i).outputs).map(k => {
        if ds.at(i).kind-out.at(k) == 0 { return none }
        let reach = if i == n - 1 { 0.0 } else {
          let j = js.at(i)
          if k in j.mism { 0.0 } else if ds.at(i + 1).kind-in.at(k) > 0 { j.band / 2 } else { j.band }
        }
        _entry(nt.at(i).at(k), tx.at(i).at(k), reach)
      }))

      (
        width: w,
        height: y,
        in-xs: bx.first(),
        out-xs: tx.last(),
        spans: {
          let out = ()
          for (i, l) in ls.enumerate() {
            for sp in l.spans { out.push((sp.at(0) + dxs.at(i), sp.at(1) + dxs.at(i))) }
          }
          out
        },
        draw: (o, in-over: none, out-over: none) => {
          let (ox, oy) = o
          for (i, l) in ls.enumerate() {
            let iov = if i == 0 { _prefer(in-over, iovs.at(0)) } else { iovs.at(i) }
            let oov = if i == n - 1 { _prefer(out-over, oovs.at(i)) } else { oovs.at(i) }
            _draw(
              l, (ox + dxs.at(i), oy + ys.at(i)),
              in-over: _shift(iov, dxs.at(i), 0.0),
              out-over: _shift(oov, dxs.at(i), 0.0),
            )
          }
          for (i, j) in js.enumerate() {
            let y0 = oy + ys.at(i) + ls.at(i).height
            let y1 = oy + ys.at(i + 1)
            for k in j.conn {
              _sbend((ox + tx.at(i).at(k), y0), (ox + bx.at(i + 1).at(k), y1), ws)
            }
          }
        },
      )
    },
  ), style)
}

/// Parallel composition, left to right. An optional `style:` argument
/// overrides style keys for this sub-diagram.
#let tensor(..args) = {
  let style = _combinator-style("tensor", args)
  let ds = args.pos()
  if ds.len() == 0 { return _apply-style(_empty, style) }
  if ds.len() == 1 { return _apply-style(ds.first(), style) }
  let links = {
    let (out, oi) = ((), 0)
    for d in ds {
      for v in d.flex-link { out.push(if v == none { none } else { v + oi }) }
      oi += d.outputs
    }
    out
  }
  _apply-style(_mk(
    ds.map(d => d.inputs).sum(default: 0),
    ds.map(d => d.outputs).sum(default: 0),
    kind-in: ds.map(d => d.kind-in).flatten(),
    kind-out: ds.map(d => d.kind-out).flatten(),
    link: links,
    env => {
      let ls = ds.map(d => (d.layout)(env))
      let ws = _use-stroke(_resolve(env.style).wire.stroke)
      let h = calc.max(..ls.map(l => l.height))
      let dxs = ()
      let x = 0.0
      for l in ls {
        dxs.push(x)
        x += l.width + env.style.gap
      }
      let w = x - env.style.gap
      // A child with no outputs connects only below, so it hugs the bottom
      // edge (and one with no inputs the top edge) instead of floating in the
      // middle, where its loose end would stray into a neighbour's wires.
      let dys = ls.enumerate().map(((i, l)) => {
        let d = ds.at(i)
        if d.outputs == 0 and d.inputs > 0 { 0.0 } else if d.inputs == 0 and d.outputs > 0 { h - l.height } else { (h - l.height) / 2 }
      })
      (
        width: w,
        height: h,
        in-xs: ls.enumerate().map(((i, l)) => l.in-xs.map(v => v + dxs.at(i))).flatten(),
        out-xs: ls.enumerate().map(((i, l)) => l.out-xs.map(v => v + dxs.at(i))).flatten(),
        spans: {
          let out = ()
          for (i, l) in ls.enumerate() {
            for sp in l.spans { out.push((sp.at(0) + dxs.at(i), sp.at(1) + dxs.at(i))) }
          }
          out
        },
        draw: (o, in-over: none, out-over: none) => {
          let (ox, oy) = o
          let (ii, oi) = (0, 0)
          for (i, l) in ls.enumerate() {
            let (bx, by) = (ox + dxs.at(i), oy + dys.at(i))
            let top = h - dys.at(i) - l.height
            // A child's own wires run to its edges; the gap to the tensor's
            // edges is bridged here, unless the slot is aimed somewhere else.
            let iov = _shift(_slice(in-over, ii, l.in-xs.len()), dxs.at(i), dys.at(i))
            let oov = _shift(_slice(out-over, oi, l.out-xs.len()), dxs.at(i), top)
            _draw(l, (bx, by), in-over: iov, out-over: oov)
            for (k, v) in l.in-xs.enumerate() {
              if dys.at(i) > 1e-6 and (iov == none or iov.at(k) == none) {
                _line((bx + v, oy), (bx + v, by), stroke: ws)
              }
            }
            for (k, v) in l.out-xs.enumerate() {
              if top > 1e-6 and (oov == none or oov.at(k) == none) {
                _line((bx + v, by + l.height), (bx + v, oy + h), stroke: ws)
              }
            }
            ii += l.in-xs.len()
            oi += l.out-xs.len()
          }
        },
      )
    },
  ), style)
}

// ----------------------------------------------------------------- rendering

/// Render a diagram as content, sized so its vertical centre sits on the math axis.
#let diagram(d, style: (:), baseline: auto) = context {
  _check-style(style)
  let st = cetz.styles.merge(sd-style, _normalize-style(style))
  let u = st.unit.to-absolute()
  let l = (d.layout)((style: st, unit: u, measured: true))
  box(
    baseline: if baseline == auto { 50% - 0.25em } else { baseline },
    cetz.canvas(length: u, padding: st.padding, (l.draw)((0.0, 0.0))),
  )
}
