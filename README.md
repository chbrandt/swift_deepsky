[dockerhub]: https://hub.docker.com/r/chbrandt/swift_deepsky/
[Swift]: https://en.wikipedia.org/wiki/Neil_Gehrels_Swift_Observatory
[XRT]: https://swift.gsfc.nasa.gov/about_swift/xrt_desc.html

# Swift DeepSky

The DeepSky pipeline provides *deep* observations of the *X-ray* sky seen by the Swift satellite -- currently named [Neil Gehrels Swift Observatory][Swift] in memory to Neil Gehrels, the former head of the mission.

The pipeline starts with a position of the Sky, given by the user -- Right Ascension, Declination -- and from there  automatically combines *all* observations made by [Swift/XRT][XRT] up to date, automatically identifies the objects in the field and measures their fluxes, countrates, spectral energy slope, hydrogen column density and other parameters involved in the process, like the *effective* exposure time (*per object*).

Data for the processing is downloaded on the fly, not being necessary for the user to have them before hand -- by all means, if the user has already the necessary data in his/her local storage the pipeline may use it.

To ease the use and portability of this package, a [Docker container is also available][dockerhub]. The use of containers allows us to bypass the setup process and go straight to the data analysis.

See section [Docker](#Docker) for instructions on using the *ready-to-use* container version; look for the section [Install](#Install) if you want to install the source code.

## Running it

The pipeline, when ran without arguments, will output a `help` message like the one below:
```

$ swift_deepsky

 Usage: pipeline.sh { --ra <degrees> --dec <degrees> | --object <name> }

 Arguments:
  --ra     VALUE    : Right Ascension (in DEGREES)
  --dec    VALUE    : Declination (in DEGREES)
  --object NAME     : name of object to use as center of the field.
                      If given, CDS/Simbad is queried for the position
                      associated with 'NAME'
  --radius VALUE    : Radius (in ARC-MINUTES) around RA,DEC to search for observations. Default is '12' (arcmin)
  -d|--data_archive : data archive directory; Where Swift directories-tree is.
                      This directory is supposed to contain the last 2 levels
                      os Swift archive usual structure: 'data_archive'/START_TIME/OBSID
  -l|--label LABEL  : Label output files. Otherwise object NAME or ra,dec VALUEs will be used.

 Options:
  -f|--master_table : Swift master-table. This table relates RA,DEC,START_TIME,OBSID.
                      The 'master_table' should be a CSV file with these columns
  -o|--outdir       : output directory; default is the current one.
                      In 'outdir', a directory for every file from this run is created.
  -u|--upload       : upload final results to central archive (no personal data is taken). Default.
  --noupload        : not to upload final results to central archive (no personal data is taken)
  --start           : initial date to consider for observations selection. Format is 'dd/mm/yyyy'
  --end             : final date to consider for observations selection. Format is 'dd/mm/yyyy'

  -h|--help         : this help message
  -q|--quiet        : verbose

```

Apart from the coordinate/object to use as the pointing centroid, and optionally the size of the circle to search for observation around, the path to an existent swift archive may be given to avoid downloading new data (notice that only a small amount, the necessary data only, is downloaded anyway).
For the records, Swift data is downloaded from the Italian Space Agency (swift.asdc.asi.it) archive.

The default Swift master table --relating (RA,DEC) coordinates to epoch of observation (START_TIME) to observation-id (OBSID)-- is shipped together and it contains all Swift observations as of February 28, 2018.

If that is running fine, we may make a test:
```bash
$ swift_deepsky --ra 34.2608 --dec 1.2455
```
, which will process every observation it finds in the archive And that process the 12 arcmin (default radius) field around RA=34.2608 and Dec=1.2455.

Or you can ask for a specific object, for example, the classic `3C279`. You can also ask for a specific time period, which we will do now by selecting only the observations in the first months of 2018:
```bash
$ swift_deepsky --object 3c279 --start 1/1/2018 --end 28/2/2018
```


## Docker

To use this package from a container Docker must be installed, see [#Install-Docker] for instructions about your platform.

**Note**
> The syntax on calling containers may be a bit ugly, don't worry; we will hide the ugliness under an alias.
> But I would like to explain the container' parameters so that we understand what is going on.

The name of the Swift-DeepSky container is `chbrandt/swift_deepsky`, it is publicly available through the [Docker-Hub][dockerhub]

The `latest` version of the pipeline can be downloaded by typing
```
# docker pull chbrandt/swift_deepsky
```

Considering we want to run the pipeline and have our results all organized under a directory called `work` we'd use the following call:
```
# docker run -v $PWD/work:/work chbrandt/swift_deepsky
```

`$PWD/work` means we are asking the outputs to be written to directory `work` inside current working directory (`$PWD`).
You may use any directory you want here; if such directory does not exist it will be created for you.

We can generalize the work directory and subsequent call to:
```
# WDIR="$PWD/work"
# docker run -v $WDIR:/work chbrandt/swift_deepsky
```

### Make it beautiful again

We can `alias` such command-line to a simple, clean call.
Let's say we decide to put our results in a directory called `sds_results` under our `Home` directory.

We can then define the alias as:
```
# alias swift_deepsky="docker run --rm -v \$HOME/sds_results/work:/work chbrandt/swift_deepsky"
```

*Notice we are defining the alias as `swift_deepsky`, but that is not mandatory; the alias can be called whatever you like better.*

We may now call the pipeline as presented in [#Running-it], as if we were running it from the source code binary:
```
# swift_deepsky
```

### Test

Run the following to get some processing done and see outputs comming out:
```
# swift_deepsky --ra 22 --dec 33 --radius 15
```

We are here asking the pipeline to sum all Swift-XRT images in the `15'` wide field around Right Ascension `22` and Declination `33`. The output should be in a directory called `22_33_15` in your current directory.


## Setup, the source code way

The following software(version) is necessary to run the pipeline:

* HEASoft (v6.21)
  * XSelect
  * XImage

* Python3 (v3.6.2)
  * Pandas (v0.20)
  * Astropy (v2.0)

* Perl (v5.10)
  * WWW::Mechanize
  * Carp::Assert
  * Archive::Tar

* Bash (v3)
  * `awk`
  * `tar`
  * `gfortran`


### Install
Once the dependencies were satisfied, (See "Setup dependencies" below)
to install the package is a two-steps process.

First we have to compile a small fortran code inside `~/bin/countrates`.
Just `cd` into this directory and execute the script `compile.sh`.

The second step is actually optional: to include `~/bin` in your `PATH`
variable f you want to simplify your calls to `~/bin/pipeline.sh`.


### Setup dependencies

#### Bash
You probably have the dependencies available, double check them though.

#### Python
If you have Anaconda python distribution you could do:
```
# conda install pandas astropy
```

Otherwise, you may use `pip`:
```
# pip install pandas
# pip install astropy
```

#### Perl
You probably have `cpan` in your machine, should be as easy as:
```
# cpan WWW::Mechanize
# cpan Carp::Assert
# cpan Archive::Tar
```
If something blocked you, see if CPAN-Minus can help you.
Try `cpan App::cpanminus`. That should work smooth, then retry the above commands.

#### HEASoft
Following the instructions from https://heasarc.nasa.gov/lheasoft/install.html


## Install Docker
Follow the links below to setup your docker environment; we see each other soon back here...

* [Windows](https://www.docker.com/docker-windows)
* [MacOS](https://www.docker.com/docker-mac)
* Linux:
  * [Ubuntu](https://www.docker.com/docker-ubuntu)
  * [CentOS](https://www.docker.com/docker-centos-distribution)

all options available: https://store.docker.com/.
