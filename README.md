# Swift DeepSky
This pipeline combines multiple Swift-XRT observations of a given position of the sky.
The pipeline components were written using Python, Bash, Perl and Fortran.
HEASoft also, providing tools for x-ray image processing.

To ease the use and portability of this package, a Docker container was created.
The use of containers allows us to bypass the setup process and go straight to the data analysis.

See [#Docker] for instructions on using the *ready-to-use* container version.
See [#Install] section if you want to setup this package yourself.


## Run it

The pipeline needs a point on the sky (Right Ascension, Declination) and a radius value;
although the default is $12 arcmin$.
This is the size of the cone around (RA,Dec) where Swift pointings (observations) will
be searched for.

The *main* script is
```bash
$ path/to/bin/pipeline.sh

 Usage: pipeline.sh -d <data> { --ra <degrees> --dec <degrees> | --object <name> }

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

 Options:
  -f|--master_table : Swift master-table. This table relates RA,DEC,START_TIME,OBSID.
                      The 'master_table' should be a CSV file with these columns
  -o|--outdir       : output directory; default is the current one.
                      In 'outdir', a directory for every file from this run is created.

  -h|--help         : this help message
  -q|--quiet        : verbose
```

Apart from the coordinate/object to use as the field's center, the/a path to the
swift archive must be given. This data-archive directory will be verified for the
presence of necessary Observations, which will be downloaded from the Italian
Space Agency (swift.asdc.asi.it) only if not there yet.

The default Swift master table --relating (RA,DEC) coordinates to epoch of observation
(START_TIME) to observation-id (OBSID)-- is shipped together and it contains all Swift
observations as of September/2017.


## Docker

To use this package we just need Docker installed.
Look [#Install-Docker] for instructions about your platform.

So, once Docker is installed, download the heasoft image by typing:
```
# docker pull chbrandt/swift_deepsky
```

To run the pipeline we may now just type:
```
# docker run chbrandt/swift_deepsky
```

To recover the outputs from the processing we must export our current directory to 
the container's working directory:
```
# docker run -v $PWD:/work chbrandt/swift_deepsky
```

### Test

Run the following to get some processing done and see outputs comming out:
```
# docker run -v $PWD:/work chbrandt/swift_deepsky -d data --ra 22 --dec 33 --radius 15
```

We are here asking the pipeline to sum all Swift-XRT images in the `15'` wide field around Right Ascension `22` and Declination `33`. The output should be in a directory called `22_33_15` in your current directory.


## Setup
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

