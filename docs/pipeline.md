# Swift DeepSky

DeepSky will stack all Swift/XRT observations in a given region of the sky.
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
