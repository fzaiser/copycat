#import "setup.typ": *
#show: setup

#fig("wire", sd(wire($X$)))
#fig("process", sd(process($f$)))
#fig("state", sd(state($p$)))
#fig("effect", sd(effect($e$)))
#fig("copy", sd(copy))
#fig("discard", sd(discard))
#fig("swap", sd(swap))
#fig("unbundle", sd(unbundle))
#fig("bundle", sd(bundle))

#fig("wire-long", sd(wire($X$, length: 2, side: "left")))
#fig("process-2-3", sd(process($f$, inputs: 2, outputs: 3)))
#fig("state-2", sd(state($p$, outputs: 2)))
#fig("effect-2", sd(effect($e$, inputs: 2)))
#fig("process-wide", sd(process("Describe")))
