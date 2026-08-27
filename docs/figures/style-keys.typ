#import "setup.typ": *
#show: setup

#let d = serial(copy, parallel(discard, process($f$)))

#fig("keys-default", sd(d))
#fig("keys-ground", sd(d, style: (discard: (kind: "ground"))))
#fig("keys-gap", sd(d, style: (gap: 0.5)))
#fig("keys-thickness", sd(d, style: (stroke: (thickness: 1.4pt))))
#fig("keys-dot", sd(d, style: (dot: (radius: 0.15, height: 0.4))))
#fig("keys-unit", sd(d, style: (unit: 1.4em)))
