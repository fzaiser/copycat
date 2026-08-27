// Shared setup for the README figures in this directory.
//
// Each figure is one page, marked with `fig`, and scripts/render-docs.sh
// writes it to docs/images/<name>.svg; it finds the names by grepping for the
// `fig("name"` calls, so keep those literal. The script also adds a style block
// that turns black ink white when the reader's colour scheme is dark, which is
// why boxes and triangles are left unfilled here.

#import "@preview/copycat:0.1.0": *

/// Page and text setup: `#show: setup`.
#let setup(body) = {
  set page(width: auto, height: auto, margin: 8pt, fill: none)
  set text(size: 11pt)
  set par(justify: false)
  body
}

/// A figure named `name`, on a page of its own.
#let fig(name, body) = {
  body
  pagebreak(weak: true)
}

/// `string-diagram` with unfilled shapes, and further style keys merged in.
#let sd(diagram, style: (:), ..args) = string-diagram(diagram, style: (fill: none) + style, ..args)

/// The running example of the README: take a photo, keep it, and describe it in text.
#let program = serial(
  state("Camera"),
  copy,
  parallel(wire("photo", side: "left"), process("Describe")),
  parallel(wire(), wire("text")),
)
