// error: `triangle.aspect` must be positive
#import "../../src/lib.typ": *
#string-diagram(state("p"), style: (triangle: (aspect: 0)))
