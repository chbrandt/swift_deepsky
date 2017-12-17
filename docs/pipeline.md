# Swift DeepSky

DeepSky combines all Swift/XRT observations for a given region of the sky.
The region is defined by a central coordinate and a radius.

The pipeline sum all events and exposure-maps centered in the corresponding
field and detect the objects using all events, in the XRT energy range
-- 0.3-10 keV.

For each object detected, the pipeline then do a series of flux measurements
in three energy sub-ranges and Swift's *full* energy band:
* soft: 0.3-1 keV
* medium: 1-2 keV
* hard: 2-10 keV
* full: 0.3-10 keV

## Pre-/Post-processing
** This goes in another part of the thesis, where I explain the technical/method
to run the pipeline for an entire (e.g, stripe82) region of the sky **

When covering an extended region of the sky, defining the positions to visit is
a fundamental step, at this point we want to (1) completely cover the region and
(2) minimize the amount of overlap between the pointings.

After running the pipeline for each position, we will concatenate all individual
results in a unique catalog, such catalog will contain duplicated objects due
to the overlaps which we have to remove to keep only the primary sources.

### Surveying a region
[healpix]: https://healpix.jpl.nasa.gov

We use the [Healpix][healpix] model to define the pointings (RA,Dec;radius) covering a
given region of the sky.
Healpix provides a discrete vision of the sky coordinates according to a spatial
resolution required.
In our case, considering that Swift/XRT has a `12 arcmin` field-of-view we will
build a list of pointings using Healpix closest resolution that fits this size;
for instance, Healpix' level-9 resolution: ~`6.5 arcmin`.

### Joining the results

The catalog resulting from all the individual processes contains two or more
duplicates for the objects in overlap regions.
If we want to have a final catalog with only unique sources -- which we do --,
a filtering process is necessary.
The filter has to define (1) which objects are duplicates and (2) which one
(and only one) to keep.

To detect duplicated objects we rely on their position.
Notice, though, that *not necessarily* duplicates will have *the same position*,
it may be that the same object to be seen at (slightly) different position when
detected from different pointings.
We search for all objects closer than a positional-error parameter, those are
said to be duplicates.
For Swift/XRT, for instance, such positional-error value is `6 arcsec`.

Among each set of duplicated objects, which one to keep is dictated by their
energy flux signal-to-noise ratio (SNR) in the full band: the source with better
SNR is defined as our primary source and goes to the final catalog.

## Pipeline stages

DeepSky is composed by five blocks of code:
1. Query/retrieve Swift observations is the search field
2. Sum all events and exposure-maps from each observation
3. Detect objects
4. Measure sources' photon flux in different energy ranges
5. Transform photon fluxes to energy fluxes (nuFnu)

### Swift observations

The pipeline starts by querying the Swift Master table which observations
were done by the Swift telescope in a given region of the sky.
The region of the sky is defined by the user and input to the pipeline
as a central positional -- Right Ascension and Declination -- and a
radius around it.

The Swift Master table is a table relating every Swift observation to
a position in the sky -- the central position of the telescope's field-of-view --
start and end time of the observation, instruments and observation mode
carried out.

The pipeline process data from observations done by the XRT instrument
running in Photon Count mode.

Once the list of observations (uniquely identified by their OBSID value)
are retrieved, the according data is downloaded from the italian swift
data archive host by the Italian Space Agency.
Only the necessary data is downloaded to minimize the amount of data
downloaded and speed-up the process.
The data downloaded are the (XRT) event-files and exposure-maps.

### Observations stacking

The event-files are combined using HEASoft `xselect` tool.

Exposure-maps are coadded with HEASoft `ximage` tool.

### Objects detection

Objects are detected using all events in the entire Swift energy range
-- 0.3-10 keV -- from the combined events-file as well as the coadded
exposure-map.
XImage's `detect` algorithm is used for sources detection.
Its output is a list of positions, effective exposure time, background
level and count-rates estimate for each detected source.

### Photon flux measurement

For each source detected previously the photon flux is measured using
XImage's `sosta` algorithm.
Sosta measures the count-rates is a given region of the image, weighing
the exposure time and background level previously estimated by `detect`.
The pipeline defines the size of the region around each source based on
the amount of photons detected.

Photon flux measurements are carried out in the full band and three
sub-bands: soft, medium and hard.

### Energy flux measurements

At the last stage the pipeline transforms photon flux to energy flux,
in particular, `nufnu` flux estimated at the middle point of each energy
band.

The energy flux is corrected by our galaxy's dust attenuation.
The pipeline computes the energy-slope between the soft+medium (combined)
and hard bands.
With the energy-slope, each source has its `countrates` transformed to
`nufnu` in `erg.s-1.cm-2`.


## I/O

### Input

* Right Ascension
* Declination
* Search radius


### Output

* Main final products
  * tables:
    * energy flux (nuFnu)
    * photon flux (countrates)
  * images/events:
    * events-file (stacked)
    * exposures-map (stacked)
