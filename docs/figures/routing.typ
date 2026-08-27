#import "setup.typ": *
#show: setup

#fig("routing-straight", sd(serial(process("Describe"), wire("text"))))
#fig("routing-arm", sd(serial(
  copy,
  parallel(process("Describe"), wire()),
)))
#fig("routing-sbend", sd(serial(
  parallel(process("Crop"), process("Describe")),
  parallel(wire(), wire()),
  parallel(process("Describe"), process("Crop")),
)))
#fig("routing-band", sd(serial(
  parallel(process("Crop"), process("Describe")),
  parallel(process("Describe"), process("Crop")),
)))
