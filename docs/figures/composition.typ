#import "setup.typ": *
#show: setup

#fig("serial-fg", sd(serial(process($f$), process($g$))))
#fig("parallel-fg", sd(parallel(process($f$), process($g$))))
#fig("chain", sd(serial(wire($X$), process($f$), wire($Y$), process($g$), wire($Z$))))
#fig("copy-fg", sd(serial(
  copy,
  parallel(process($f$), process($g$)),
)))
