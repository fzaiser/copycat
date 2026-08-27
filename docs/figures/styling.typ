#import "setup.typ": *
#show: setup

#fig("style-whole", sd(program, style: (stroke: (paint: blue), box: (fill: blue.transparentize(85%)))))
#fig("style-sub", sd(serial(
  state("Camera"),
  styled(serial(copy, parallel(wire(), discard)), stroke: (paint: red)),
  wire("photo"),
)))
#fig("style-element", sd(serial(
  wire($X$),
  process($f$, stroke: (paint: blue), fill: blue.transparentize(85%)),
  wire($Y$, stroke: (dash: "dashed")),
)))
