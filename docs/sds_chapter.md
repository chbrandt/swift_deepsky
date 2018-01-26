
# The Swift DeepSky catalog

1. motivation
  * why create the catalog
2. catalog creation
  * selection, data processing, catalog
3. pipeline description
  * workflow and results
4. catalog description
  * data characteristics


## Motivation

**
Talk about the stripe82 data collection, in particular the deep surveys, and
how a deep x-ray data collection would improve it and could help the search for
AGNs.
At this point I have already talked about the collection of data over the Stripe82
and the x-ray data provided by LaMassa.

We have now to talk about the benefits of (1) Swift XRT data and (2) deep x-ray
data.

For the Swift XRT data I can recall the articles:
* Puccetti et al. (2011): analyzed the deepest gamma-ray burst (GRB) fields,
combining all of the data into a single image per field;
* D’Elia et al. (2013): analyzed 7 yr of XRT data, considering each observation independently;
* Evans et al. (2014): produced a deeper catalog by coadding XRT images using xrtpipeline
**

The amount of time a telescope observe a particular region of the sky dictates
the amount of information that can be retrieved from that particular region.
An astonishing demonstration of the power of extended integration time was
given by the Hubble Space Telescope in 1995;
the telescope observed a small region of the sky for 10 consecutive days generating
more than 300 images, which were then combined into what was called the Hubble
Deep Field, the deepest observation done to that date.

Objects with apparent luminosity too low to be significantly detected in a single
exposure may show out when many observations are coadded.
Clearly, coaddition is possible only when the telescope has visited a given
region of the sky multiple times, which happens in three situations: (i) the
observed region is signed to a series of dedicated time project, like the
Hubble Deep Field, (ii) the region is part of a wide field survey's footprint
periodically visited, as in the Sloan Digital Sky Survey, or (iii) the telescope
has long been collecting data that overlaps become a feature, which is the
scenario we are exploring with the Swift Telescope.

Swift primary goal is to investigate Gamma-Ray Bursts (GRB), to accomplish that the
telescope carries three detectors: the Burst Alert Telescope ([BAT]), which
triggers the whole telescope's attention whenever a GRB is detected; the X-Ray
Telescope ([XRT]), that follows the subsequent emission of the GRB; finally the
UltraViolet-Optical Telescope ([UVOT]) responsible for registering the uv/optical
GRB afterglow.

[BAT]: https://swift.gsfc.nasa.gov/about_swift/bat_desc.html
[XRT]: https://swift.gsfc.nasa.gov/about_swift/xrt_desc.html
[UVOT]: https://swift.gsfc.nasa.gov/about_swift/uvot_desc.html

Although its priority is GRB events, Swift will follow a routine of
x-ray sources observations whenever GRBs are not in the sight.
We may notice then the nature of x-ray sources Swift/XRT are used to register:
GRB neighbourhoods and known x-ray sources.

With that in mind we developed a pipeline to combine all Swift/XRT observations
inside the Stripe82 region.
Our goal is to compile the deepest set of Swift/XRT observations to date and
enrich the Stripe82 data collection in the high energy band with a catalog of
all detected sources fluxes.
The pipeline implemented is called Swift DeepSky.

The next sections describe the creation of the sources catalog, the DeepSky pipeline,
and the catalog data analysis.


## Catalog creation

(file 'sds_over_stripe82.md')


## The Swift DeepSky pipeline

(file 'pipeline.md')


## The Catalog

The output of Swift DeepSky over the Stripe82 is a list of 6906 (non-unique) objects.
We then filter duplicated objects out by self-matching its objects within $5''$
and the `full band` flux signal-to-noise ratio to define the primary source.

The primary catalog is composed by 3254 unique sources.

(Highlight the cleaning with xmatch)
