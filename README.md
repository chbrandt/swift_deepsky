[dockerhub]: https://hub.docker.com/r/chbrandt/swift_deepsky/
[Swift]: https://en.wikipedia.org/wiki/Neil_Gehrels_Swift_Observatory
[XRT]: https://swift.gsfc.nasa.gov/about_swift/xrt_desc.html

# Swift DeepSky
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1217670.svg)](https://doi.org/10.5281/zenodo.1217670)
-----

The _Swift DeepSky_ pipeline provides *deep* observations of the *X-ray* sky as seen by the Swift<sup>1</sup> satellite.

The pipeline starts from a position on the Sky given by the user (Right Ascension, Declination) -- and from there combines *all* observations made by [Swift/XRT][XRT] up to the date, identifies the objects in the field and measures their fluxes, countrates, spectral energy slope, hydrogen column density, like the *effective* exposure time (*per object*).
And this is all done _automatically_.

* Data for the processing is downloaded on the fly, not being necessary for the user to have them before hand -- by all means, if the user has already the necessary data in his/her local storage the pipeline may use it if requested.

* To ease the use and portability of this package, a [Docker container is also available][dockerhub]. The use of containers allows us to bypass the setup process and go straight to the data analysis.

See section [Docker](#Docker) for instructions on using the *ready-to-use* container version; look for the section [Install](#Install) if you want to install the source code.


## No secrets: `help` is here
When no arguments are given, or the `--help | -h` option is given, a _help_ message like the one below is displayed.
Besides all the options, it should be highlighted that only the `--object` _or_ the (`--ra`,`--dec`) position is mandatory; that is effectively all `swift_deepsky` needs to run.
```
$ swift_deepsky

 Usage: swift_deepsky { --ra <degrees> --dec <degrees> | --object <name> }

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

## Running it

The pipeline may either be manually installed in your own workstation -- to that, check section [#Manual-Install] below -- or (recommended) run through a Docker engine.

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
To run the `swift_deepsky` container we need to have Docker installed and tested.
Please, check [#Install-Docker] for instructions on installing Docker on your platform.

Since version 9, the _Swift-DeepSky_ container (`chbrandt/swift_deepsky`) runs with a _CalDB_ container attached to it (`chbrandt/heasoft_caldb`). 
The _CalDB_ container though is just a data volume: it's role is only to serve _DeepSky_ with Swift calibration data, which means that you can run the _CalDB_ container once and (mostly) forget about it for a while.

There is _one_ information that is important about the `heasoft_caldb` container that we will use everytime we call
`swift_deepsky`: the _name_ we give to the container. We will use simply `caldb`:
```bash
$ docker run --name caldb chbrandt/heasoft_caldb:swift
```

Now we can run the `swift_deepsky` container, supported by `caldb`:
```bash
$ docker run --rm -it --volumes-from caldb -v $HOME/sds_output:/work chbrandt/swift_deepsky:latest
```
Let me explain what we just saw:
* `--rm`: this guarantees that the container is garbage-collected when it is done processing;
* `-it`: these are important flags that guarantee the necessary kind of environment for HeaSOFT tools;
* `--volumes-from caldb`: here is where we bind `swift_deepsky` to `heasoft_caldb` container;
* `-v $HOME/sds_output:/work` is where the results are written: locally, inside `$HOME/sds_output`;
  * `$HOME/sds_output` **can** be changed to whatever you want, `/work` **cannot** be changed;
* `chbrandt/swift_deepsky:latest` is the same as `chbrandt/swift_deepsky`.

> In other words, you want to keep the parameters as given above, you _may_ (and probably _should_) change the value for
> the output files: the example uses `$HOME/sds_output`, pick one that suites your organization better.

Once you digested the command-line(s) above, you may very well create an alias to simplify your life. For example,
```bash
$ alias swift_deepsky='docker run --rm -it --volumes-from caldb -v $HOME/sds_output:/work chbrandt/swift_deepsky:latest'
```

And now you could simply type:
```bash
$ swift_deepsky [options]
```

### Test: dummy values
Run the following to get some processing done and see outputs comming out:
```
# swift_deepsky --ra 22 --dec 33 --radius 15
```

We are here asking the pipeline to sum all Swift-XRT images in the `15'` wide field around Right Ascension `22` and Declination `33`. The output should be in a directory called `22_33_15` in your current directory.


## Manual Install
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

- - -
<sup>1</sup>: currently named [Neil Gehrels Swift Observatory][Swift] in memory to Neil Gehrels, former head of the mission.
