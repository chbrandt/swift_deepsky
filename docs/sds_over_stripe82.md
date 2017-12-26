
# Surveying Swift' Stripe82

The goal is to run Swift DeepSky over the Stripe82.
For such, we have to define the coordinates to visit and coverage radius.
Define a parallel way for running it, since each run is independent from the other
and a good amount of processing-time will be demanded.
And finally, the results should be merged to compile a unique catalog.

1) Define the positions to visit
  * use of healpix to define positions
2) Run the pipeline for each pointing
  * docker packaging and parallel run
3) Aggregate the results
  * use of xmatch to filter sources


## Sky pointings with HEALpix
[healpix]: https://healpix.jpl.nasa.gov/
[moc]: https://github.com/chbrandt/moc

To run the DeekSky in the entire Stripe82 we have to define the positions to
visit.
The region is to be covered by circles as that is how the pipeline operates.
To do that we will use [Healpix][healpix] as it provides the mechanism to define
regularly spaced coordinates given a constant radius for sky surveys.

The software implemented for this task is published as a small package [moc].

To build our list of pointings we queried the Swift Master table for all observations
inside the box `RA(deg):[-60:60]` and `Dec(deg):[-1.5,1.5]`, the Stripe82 region.
Each position observed by Swift is associated to a Healpix pixel at a pre-specified
*level*.
When all observations have been associated to its respective Healpix element,
the inverse transform -- *i.e*, from Healpix elements to coordinates -- is
applied to build up a discrete and reduced list of coordinates to eventually
be given to the pipeline.

The Healpix *level* is defined after after Swift XRT field-of-view.
Since we want to completely cover the region, the steps between our pointings
cannot be bigger than our observations field-of-view.
Swift XRT has a FoV of $12 arcmin$, Healpix levels $9$ and $8$ provide pixels
with sizes $5.6 arcmin$ and $13.1 arcmin$, respectively.
For our purpose, *level 9* is the appropriate level to used when defining the
*coordinates to healpix* transform.

When calling the pipeline then with pointings from this process and the original
radius from Swift-XRT FoV -- 12 arcmin -- adjacent pointings will overlap.
Although this is not optimal from the processing point-of-view, it is necessary
to guarantee our results the best signal-to-noise by combining all possible
events in that area.


As of December 2017 the list of Swift observations over the Stripe82 contains
[???] entries.
Healpix will be used here for binning a series of coordinates; the coordinates may be a real list of sources or an artifical one. In any case, the binning will downsample the list of coordinates.

An application for the downsampling is the definition of observational pointings on a survey, where we have to define the minimum amount of to cover a specific region.

The pointings are defined by a central coordinate -- RA,Dec -- and a radius value defining the size of the circle (i.e, field of view) each pointing covers.
