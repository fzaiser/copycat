# How copycat lays out a diagram

This is a description of the implementation in `src/`, for changing the library rather than using it.
The public interface is documented in the README.

## Diagram values

A primitive or combinator returns a dictionary.
The fields a document may rely on are `inputs` and `outputs`; everything else is internal.

- `kind-in`, `kind-out`: one entry per slot, saying how willing the slot is to move sideways: `0` rigid (a box, a triangle, a custom primitive), `1` wire (a plain `wire` or a `discard`, which may be drawn at any x but prefers its own), `2` arm (an arm of `copy`, `unbundle` or `bundle`, which goes wherever it is told).
- `flex-in`, `flex-out`: the same information as booleans, "may this slot move at all".
- `flex-link`: for each input slot, the output slot that is the other end of the same wire, or `none`.
  A plain `wire` links its two ends; `serial` chains links through its layers and `parallel` concatenates them.
  Moving one end of a linked column moves the other, unless that end is held.
- `layout`: a function from an environment to a concrete layout, see below.
- `width`, `height`, `input-positions`, `output-positions`, `spans`, `draw`: the *nominal* layout, i.e. the result of `layout` for the default style with every label measured as empty.
  They are stored eagerly so that a diagram can be inspected outside of `context`.

## Environments and measurement

`layout(env)` receives `(style, unit, measured)`.
Labels can only be measured inside `context`, which `string-diagram` provides; `measured` says whether measurement is available.
Outside of it, `_measure` reports every label as having no size, which is what the nominal fields hold.
`_measure` reports extents in the layout frame: in the horizontal reading directions it swaps width and height, so that every element sizes itself as usual and its upright label still fits on the page.
Triangles need one more adjustment, since a sideways label runs towards the apex; `_tri-geometry` then lets the triangle grow in length rather than across.
A concrete layout consists of `width` and `height` in units, the slot positions `input-positions` and `output-positions`, `spans` (the horizontal extents of solid shapes, offset from the layout's left edge), and `draw(origin, in-over: none, out-over: none)`, which returns cetz elements.

## Overrides

A flexible slot can be told to end somewhere other than its natural place.
An override is an array with one entry per slot: `none`, or a pair `(x, reach)` giving the target's x in the element's own coordinates and how far beyond the element's edge the target lies.
`wire`, `copy`, `discard`, `unbundle` and `bundle` accept overrides and bend their flexible ends accordingly; `serial` and `parallel` translate the overrides they receive into their children's coordinates and pass them on.

## Sequential composition

`serial` stacks its layers, centring each within the widest, which means connected slots rarely line up.
It then decides which slots move, in two sweeps.
The bottom-up sweep lets every flexible slot adopt the x of the slot below it, unless that slot has a weaker claim; a wire hands the x on to its far end through `flex-link`, so a whole column follows the box it stands on.
The top-down sweep does the same from above for slots that are not yet held.
Claims are ordered rigid > wire > arm, and a slot that has been pinned keeps the claim of its source, so a box's position propagates through any number of wires.
A wire may not be moved into a solid shape (a `spans` entry) it does not already sit in; `_free-x` checks this.

What still disagrees after both sweeps is rigid on both sides, or a wire that was not allowed to move.
Only then is a band of `style.bend` units inserted between the two layers, and every slot at that junction is carried across it: flexible slots reach through the band themselves, via their overrides, and rigid pairs are drawn as S-curves, or straight lines where the two agree.

## Parallel composition

`parallel` places its children left to right, `style.gap` apart, and centres shorter children vertically, extending their wires to the common edges.
A child with no outputs hugs the bottom edge and one with no inputs the top edge, so that a `discard` or a `state` does not float in the middle of a taller neighbour.
Overrides received by the parallel are sliced per child; a slot that has been aimed elsewhere draws its own connection and the straight extension is skipped.

## Style resolution

Styles use cetz's `styles.resolve`: `auto` in an element group inherits the root key of the same name, and partial strokes fold onto the strokes they inherit from.
Two details keep folding predictable.
Strokes are stored as dictionaries rather than stroke values, because cetz folds a partial override onto a stroke value by filling the omitted fields with Typst's defaults instead of the base.
A disabled stroke is carried as `(paint: none)` rather than `none`, so that a later paintless override cannot silently bring it back; `use-stroke` turns it into `none` at the point of drawing.
`check-style` rejects unknown keys before any of this happens.

## Reading directions

All layout code works in the bottom-to-top frame.
`string-diagram` applies one cetz transform to the finished drawing: a vertical flip for `"down"`, a clockwise quarter turn for `"right"`, and the quarter turn followed by a horizontal flip for `"left"`, which keeps the first factor of a parallel composition on top in both horizontal directions.
cetz keeps content upright under transforms and resolves anchors on the page, so a wire label only needs its anchor chosen after mapping its side through the same transform, which `_side-anchor` does.

`string-diagram` also registers the layout's rectangle as hidden bounds, so the canvas is never smaller than the layout, even where an element draws less than its declared size.

## Custom primitives

`primitive` builds an element with rigid slots on top of `_mk`, the same constructor the built-in primitives use.
The user's drawing function runs inside a cetz `group` that translates to the element's origin, so it can draw in local coordinates and still land correctly under any reading direction.
