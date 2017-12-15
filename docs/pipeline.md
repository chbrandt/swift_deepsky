# Swift DeepSky

DeepSky combines all Swift/XRT observations in a given region of the sky.
Such (circular) region is defined by a coordinate (c=RA,Dec) and a radius.

The pipeline will dynamically load data from the (online) Swift archive,
sum all events and exposure-maps centered in the corresponding field and
detect the objects using all events, in the entire XRT energy range
-- 0.3-10 keV.

For each object detected, the pipeline then focus on flux measurements
in three energy sub-ranges:
* soft: 0.3-1 keV
* medium: 1-2 keV
* hard: 2-10 keV


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
