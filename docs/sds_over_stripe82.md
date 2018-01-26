
# Surveying Swift' Stripe82

Here we describe the processing of all Swift/XRT observations lying within the
Stripe82 region.
For such, we have to define the coordinates to visit and coverage radius.
Define a parallel way for running it, since each run is independent from the other
and a good amount of processing-time will be demanded.
And finally, the results should be merged to compile a unique catalog.


## Sky pointings with HEALpix
[healpix]: https://healpix.jpl.nasa.gov/
[moc]: https://github.com/chbrandt/moc

To run the DeekSky in the entire Stripe82 we have to define the positions to
visit.
The region is to be covered by circles as that is how the pipeline operates.
To do that we will use [Healpix][healpix] as it provides the mechanism to define
regularly spaced coordinates given a constant radius for sky surveys.

The software implemented for this task is published as a small package called [moc].

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

When calling the pipeline with the positions from this process and the original
radius from Swift-XRT FoV -- 12 arcmin --, adjacent pointings will overlap.
Although this is not optimal from the processing point-of-view, it is necessary
to guarantee our results the best signal-to-noise by combining all possible
events in that area.

Figure [healpix_coverage_example] below illustrates the coverage of a small
region following the algorithm described above.
And figure [healpix_coverage_s82] presents all pointings defined to run
DeepSky over.

![healpix_coverage_example]: healpix_coverage_example.jpg
![healpix_coverage_s82]: healpix_coverage_s82.jpg

The resulting list of pointings contains 699 entries, compiled from [???]
observations.
Now that we have the list positions we want to visit, we have to define
how we will do it, considering that the processing of [???] observations
is a quite time consuming task.


## Running the pipeline

For the Stripe82 ~700 pointings were defined, representing [???] observations.
To process this dataset we will apply a parallel strategy.
In this section I will present some general number about the whole
processing, done in parallel.
I will also take the chance to present the software packaging adopted,
which makes the setup and use of the pipeline a straightforward process.

The pipeline process data from a given pointing -- (ra,dec;radius) --
independent from others.
Such independence between the processings allows us to trivially
parallelize the processing of all pointings using a *bag-of-tasks*
approach.

In practice, a *bag-of-tasks* is a list of tasks (or parameters defining tasks)
that are processed according to the available resources.
Resources are controlled by a queue of running jobs.
In our case, the most demanding resource is CPU.
If we have 10 CPUs available the size of our queue will be 10, which
means 10 jobs will run simultaneously; whenever a job is finished, the
next one from *the bag* will be allocated.

Although very simple, such parallelization strategy naturally provides
load balancing, longer jobs can run as much as necessary without blocking
the queue.

**TODO**: draw an illustration of the queue system.

**TODO**: plot distribution of *number-of-observations per pointing*;
plot scatter *processing-time vs job-size*.

[seq]: https://github.com/chbrandt/shools

The queue system used was implemented using `Bash` scripting and may
be downloaded from [Github, Simplest-Ever-Queue system][seq].
Many queue systems are publicly available, but none of them is simple
enough to *just use*; they all need more or less complex setups and
they are usually focused on larger, distributed high performance systems.
My goal was to provide a simple queue system that anyone with access to
a multiprocessing machine could use it effortlessly.


### Pipeline distribution

The packaging of the pipeline is the result of the implementation of the
*software portability* concept.
Many concepts may characterize a software, *portability* is the one that
qualifies whether a software can run in different platforms.
A non-portable software is one that runs in one, specific operating
system or architecture (*i.e*, platform); on the other hand, a (highly)
portable software may run in a wide range of platforms.

Regarding *portability*, in very recent years the landscape of computing
has been significantly changed with the development of *containers*.
Containers are the top level of virtualization technologies, which allows
us to mimic an entire environment around a software so that the real
platform underneath it can be abstracted.
This paradigm removes the weight of portability from the (core) software,
which not only simplifies the development but also promotes the focus
on developing core functionalities for the software.

A detailed explanation of the technology and its technical aspects is
described in [Appendix ???: docker for astro].
**TODO**: write the appendix/article about `docker-heasoft`, `swift_ds`.

The Swift-DeepSky pipeline is distributed in a Docker container image,
which provides the user a *ready-to-use* software package.
In other words, every software dependence is packaged together with
the pipeline code.
By implementing such technology to our software we completely solve any
portability issue that could block any potencial user, leaving the user
only with the task of generating and analysing data.

By all means, the source code of DeepSky is publicly available for the
sake of scientific transparency and to individuals more control over the
pipeline internals if/whenever necessary.


## Aggregate results

The goal of this big processing is to extract flux measurements from
every object (detectable) within the Stripe82 area.
To eventually build a catalog from all those sources for Spectral
Energy Distribution studies.

Each region visited generates a set of output files: catalogs, images, log-files.
The main products are the flux tables -- photon and energy fluxes --,
containing flux measurements for each detected object.

After processing all ~700 regions we concatenate every (output) catalog
in one big table.
Notice, though, that this table may contain duplicated entries -- the
same object appearing more than once.
Duplicated objects will happen whenever an object is detected by two
different runs because of overlapping regions.

The removal of duplicated objects is done through a cross-matching, where
we basically search for objects that are too close to be two real, different
sources.
The definition of this *tolerance distance* is guided by instrument's
point spread function, typically, which is the limiting deblending power.
Whenever two (or more) objects follow within this tolerance distance
one of them is kept and other(s) are discarded.

The criterion to decide which of the duplicated measurements to keep is
the signal-to-noise ratio (*snr*).
Among the duplicates, the one with higher full-band flux *snr* is the
so called *primary source* and makes to the final, unique-sources catalog.
