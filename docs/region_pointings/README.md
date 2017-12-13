# Region-Pointings

Here we define a code snippet to cover a region (rectangular, to start)
 entirely with circles.
The idea is to give as input a region (defined by its edges/nodes) and
 the size of the circles (i.e, radius) to be used;
 As output we should get a list of coordinates defining the center of
 the circles found by the algorithm to be the best solution.
Notice that the circles (with pre-defined radius 'R') defined by the
 algorithm will overlap and the ones at the border will surpass the
 original region limits.

For example, suppose we want to cover a square-shaped region of side '10'
 with circles of radius '5'. One --probably the simplest-- solution is to
 define 4 circles: at each middle-point on the edges, (5,0),(0,5),(10,5),(5,10)

[]
Carlos
