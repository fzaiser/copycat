#import "setup.typ": *
#show: setup
#set page(width: 13cm)

#let small = sd.with(style: (unit: 1.2em))

#fig("inline")[
  The copy map #small(copy) and the discard map #small(discard) satisfy
  #small(serial(copy, parallel(wire(), discard))) $=$ #small(wire()), so every object is a comonoid.
  At the default size the same diagram, #sd(serial(copy, parallel(wire(), discard))), is too tall for a line of text.
  A labelled diagram also wants smaller labels: #sd(serial(wire($X$), process($f$), wire($Y$)), style: (unit: 1.3em, label: (size: 0.8em))).
]
