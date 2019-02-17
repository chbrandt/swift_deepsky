
The _Swift DeepSky_ (SDS) project has three goals:
* Generate deep views of the Sky
* Keep an up-to-date version of Swift photometric catalog
* Provide sn easy tool for non-specialists to process X-ray data

To accomplish those goals a mixture of technologies and client/server agents
were assembled to deliver a completely automated mechanism to handle all the
complexities of astronomical x-ray data processing and the production of
high-level products.

## A deep view of the X-ray Sky
The SDS pipeline is capable of combining Swift observations ever since the
satellite started operating -- in 2004.
The goal is to provide the most sensitive view of the X-ray sky _to the date
of the processing_.
The pipeline will automatically download and combine as much as
possible Swift/XRT observations covering the region of the sky requested by the
user, will automatically detect the objects in the combined, deep image and
then measure average energy emitted by the objects in it throughout the history.

##### more...
If you like photography, you probably know about the concept of _exposure time_
and its relevance to take pictures of dark scenes -- if the scene we are trying
to take the picture is low in light, our camera will have to set a _long_
exposure time to be able to capture the objects in the photo.

When we observe the sky with telescopes the same concept applies: to capture the
light from faint objects (galaxies, stars) the telescope has to _integrate_ the
light from such object for a long period of time.
An example of such process is the famous and gorgeous [Hubble Deep Field] observation.

Sometimes, though, it is not possible to continuosly observe a given region of
the sky for long periods of time.
For many reasons.
One reason, for example, in the case of satellites like Swift, is our own planet,
the Earth, that will block the satellite's field of view at every orbit (~90 minutes).

But if a particular region of the sky has been observed many times we can
combine those images to "simulate" a long exposure photography.
Sure many technical details have to be considered -- perfect alignment of the
pixels accross the images is the first of them -- but once we handle them we effectively
have a deep<sup>*</sup>, sensitive view (_i.e._, "observation") of that region of the sky.

<sup>*</sup>: the term _deep_ is used in observational astronomy as a synonym to
_distant_, which has a direct relation to the light intensity of an object.
The more distant an object (_e.g._, a galaxy) is from us, the fainter it is from
our point of view.

[hubble deep field]: https://en.wikipedia.org/wiki/Hubble_Deep_Field


## The live catalog
A particularly interesting feature of _the Swift-DeepSky pipeline_ is to push
the final results of each processing to a central server for global publication
through the network of Virtual Observatories.


## Docker packaging
_Software should be simple to use_ -- specialy if we want to deliver it to non-specialists.

The _Swift-DeepSky_ pipeline uses a lot of scientific software to do its job.
One of the software packages used is NASA's [HEASoft], some are written by us,
some use compiled languages (_e.g._, Fortran) while others use interpreted ones
(Python, Perl).
Bottomline is: the install procedure of scientific software may get nasty sometimes.

After considering the profile of our potencial users and the resources we should
provide [Docker containers] provided the right solution either to the first step
-- install -- and also to another aspect: _portability_.
Our users are most likely to work on either MacOS-X or GNU/Linux operating systems,
and Docker containers will run transparently in either one.

[dockerhub]: https://hub.docker.com/r/chbrandt/swift_deepsky/
[Swift]: https://en.wikipedia.org/wiki/Neil_Gehrels_Swift_Observatory
[XRT]: https://swift.gsfc.nasa.gov/about_swift/xrt_desc.html
[heasoft]: https://heasarc.gsfc.nasa.gov/docs/software/heasoft/
[Docker containers]: https://www.docker.com/

# Citation
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1217670.svg)](https://doi.org/10.5281/zenodo.1217670)
