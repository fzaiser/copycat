# Architecture

How drawstring turns a term such as `serial(copy, parallel(discard, wire()))` into a drawing.
This is a guide to the implementation in `src/`, for changing the library; the [README](README.md) documents how to use it.

## The pipeline

A diagram passes through three stages.

| Stage | Where | What happens |
|---|---|---|
| Build | the primitives and combinators | Each call returns a *diagram value*, a dictionary. This is cheap and needs no `context`. |
| Layout | `layout(env)`, a closure stored in every diagram value | Inside `context`, labels are measured and every element gets a size, wire positions and a `draw` function, all in abstract units. |
| Draw | `string-diagram` | The layout's `draw` produces CeTZ elements. One transform turns them into the requested reading direction, and the canvas is boxed so that its centre sits on the math axis. |

All layout code works in a single frame: the diagram reads bottom to top, x grows to the right, lengths are in units, and the origin is the bottom-left corner.
The reading direction is applied afterwards, as one transform of the finished drawing; the layout consults it only where an upright label changes an element's size, see [Measuring labels](#measuring-labels).

The files:

- `src/lib.typ` re-exports exactly the public names.
- `src/style.typ` holds the default style and everything about resolving and validating styles.
- `src/core.typ` holds the rest: primitives, combinators, custom elements and the renderer.

## Diagram values

Every primitive and combinator returns a dictionary built by `_mk`.
Only `inputs` and `outputs` are public; the rest may change.

| Field | Meaning |
|---|---|
| `inputs`, `outputs` | wire counts |
| `kind-in`, `kind-out` | one entry per wire end, saying how willing it is to move sideways (see [Slot kinds](#slot-kinds)) |
| `flex-in`, `flex-out` | the same as booleans: may this end move at all |
| `flex-link` | for each input, the index of the output that is the other end of the same wire, or `none` |
| `layout` | `env => layout`, see below |
| `width`, `height`, `input-positions`, `output-positions`, `spans`, `in-labels`, `out-labels`, `draw` | the *nominal* layout: `layout` evaluated for the default style with every label measured as empty. It is stored eagerly so that a diagram can be inspected outside `context`. |

### Slot kinds

A *slot* is the point where a wire meets the edge of an element.
Its kind says who decides where it sits:

| Kind | Name | Elements | Behaviour |
|---|---|---|---|
| `0` | rigid | boxes, triangles, custom elements | stays where the element puts it |
| `1` | wire | `wire`, `discard` | may be drawn at any x, but prefers its own |
| `2` | arm | the arms of `copy`, `unbundle` and `bundle` | goes wherever it is told |

`flex-link` ties the two ends of a plain `wire` together, so that moving one end moves the other unless that end is held.
`serial` chains links through its layers and `parallel` concatenates them, so a column of wires stacked by `serial` behaves like one long wire.

## Layouts

`layout(env)` receives an environment `(style, unit, measured)` and returns

- `width` and `height` in units,
- `input-positions` and `output-positions`, the x of each slot,
- `spans`, the horizontal extents of solid shapes, which wires must not be moved into,
- `in-labels` and `out-labels`, for each slot the horizontal extent of the label that moves with it, or `none` (only labelled wires have one; a layout may leave the two fields out, and `_mk` fills them with `none`), and
- `draw(origin, in-over: none, out-over: none)`, which returns CeTZ elements; elements without flexible slots take only `origin`, and `_draw` calls either form.

### Measuring labels

Labels can only be measured inside `context`, which `string-diagram` provides; `env.measured` says whether that is the case.
Outside of it, `_measure` reports every label as empty, which is what the nominal layout holds.

`_measure` reports extents in the layout frame.
In the horizontal reading directions the drawing will be turned a quarter, so a label's width on the page runs along the element's height, and the two are swapped.
Every element can then size itself as usual and its upright label still fits.
Triangles need one more adjustment: read sideways, the label runs towards the apex, so `_tri-geometry` lets the triangle grow in length rather than across.
A labelled wire also measures its label: it widens on the label's side so that `parallel` neighbours are placed after the label, and it lengthens to the label's extent along the flow, which matters when the diagram is read sideways.

### Overrides

A flexible slot can be told to end somewhere other than its natural place.
An *override* is an array with one entry per slot: `none`, or a pair `(x, reach)` with the target's x in the element's own coordinates and how far beyond the element's edge the target lies.
`wire`, `copy`, `discard`, `unbundle` and `bundle` accept overrides in `draw` and bend their flexible ends accordingly; `serial` and `parallel` translate the overrides they receive into their children's coordinates and pass them down.

## Sequential composition

`serial` stacks its layers and centres each within the widest, so connected slots rarely line up.
It then decides which slots move, in this order:

1. **Bottom-up sweep.**
   Every flexible slot adopts the x of the slot below it, unless that slot has a weaker claim.
   A wire passes the x on to its far end through `flex-link`, so a whole column of wires follows the box it stands on.
2. **Top-down sweep.**
   The same from above, for slots that are not yet held.
3. **Connector bands.**
   Whatever still disagrees is rigid on both sides, or a wire that was not allowed to move.
   Only then is a band of `style.bend` units inserted between the two layers, and every slot at that junction is carried across it: flexible slots reach through the band themselves, via their overrides, and rigid pairs are drawn as S-curves, or as straight lines where they agree.

Claims are ordered rigid > wire > arm, and a slot that has been pinned keeps the claim of its source, so a box's position propagates through any number of wires.
`_free-x` refuses a move that would put a slot into a solid shape it does not already sit in or into another wire's label, or that would carry a wire's own label onto a shape or another slot of the same layer.
A refused slot stays where it is and is carried across the band instead.

## Parallel composition

`parallel` places its children left to right, `style.gap` apart, and centres shorter children vertically, extending their wires straight to the common edges.
A child with no outputs hugs the bottom edge and one with no inputs the top edge, so that a `discard` or a `state` does not float in the middle of a taller neighbour with its loose end among the neighbour's wires.
Overrides received by the parallel are sliced per child; a slot that has been aimed elsewhere draws its own connection and skips the straight extension.

## Styles

Styles use CeTZ's `styles.resolve`: `auto` in an element group inherits the root key of the same name, and partial strokes fold onto the strokes they inherit from.
Two details keep the folding predictable:

- Strokes are stored as dictionaries rather than stroke values.
  CeTZ folds a partial override onto a stroke *value* by filling the omitted fields with Typst's defaults instead of the base, which would clobber it.
- A disabled stroke is carried as `(paint: none)` rather than `none`, so that a later paintless override cannot silently revive it.
  `use-stroke` turns it back into `none` at the point of drawing.

`check-style` rejects unknown keys before any of this happens, and `whole-diagram-keys` lists the keys that only `string-diagram` accepts.

## Reading directions

`string-diagram` applies one CeTZ transform to the finished drawing:

| Direction | Transform |
|---|---|
| `"down"` | vertical flip |
| `"right"` | clockwise quarter turn |
| `"left"` | quarter turn, then a horizontal flip, which keeps the first factor of a `parallel` on top in both horizontal directions |

CeTZ keeps content upright under transforms and resolves anchors on the page.
A wire label therefore only needs its anchor chosen after mapping its side through the same transform, which `_side-anchor` does.

`string-diagram` also registers the layout's rectangle as hidden bounds, so the canvas is never smaller than the layout, even where an element draws less than its declared size.

## Custom primitives

`primitive` builds an element with rigid slots on top of `_mk`, the same constructor the built-in primitives use.
The user's drawing function runs inside a CeTZ `group` that translates to the element's origin, so it can draw in local coordinates and still land correctly under any reading direction.
The style it receives has already passed through `use-stroke`, so every stroke in it can be handed to CeTZ as it is.
