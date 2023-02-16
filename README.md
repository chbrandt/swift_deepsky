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

* An example of `--master_table` can be found at [docs/notebook/SwiftXrt_master.csv](docs/notebook/SwiftXrt_master.csv):
  ```
  NAME;ORIG_TARGET_ID;TARGET_ID;RA;DEC;START_TIME;STOP_TIME;ORIG_OBS_SEGM;OBS_SEGMENT;ORIG_OBSID;OBSID;XRT_EXPOSURE;XRT_EXPO_PC;ARCHIVE_DATE;PROCESSING_DA;PROCESSING_DATE;PROCESSING_VE
  SAFE3-CURR;60002;60002;0.640524;0.2784;20/11/2004;21/11/2004;0;0;60002000;60002000;0;0;27/11/2004;HEA_20JULY2006_V6.1_SWIFT_REL2.5A(BLD19)_22SEP2006;14/11/2006;3.7.6
  SAFE5-CURR;60004;60004;0.640524;0.2784;21/11/2004;21/11/2004;0;0;60004000;60004000;0;0;28/11/2004;HEA_20JULY2006_V6.1_SWIFT_REL2.5A(BLD19)_22SEP2006;12/11/2006;3.7.6
  (...)
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

### The `work` directory

When we run SDS using Docker container, inside the container the (SDS) pipeline runs from the directoty `/work`. It is a directory _inside_ the container, you don't need to worry about having a directory `/work` in your host system. What you _do_ need to be attentive to is to use `/work` as the container's directory when mounting local directories from the host to the container. For instance, in the instructions below we mount (or _bind_ if you will) the _local_ directory `$HOME/sds_output` to container's `/work` so the results show up in your system's `$HOME/sds_output` (generated by the container, inside the container's `/work` folder).

### CALDB

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
$ swift_deepsky --ra 22 --dec 33 --radius 15
```

We are here asking the pipeline to sum all Swift-XRT images in the `15'` wide field around Right Ascension `22` and Declination `33`. The output should be in a directory called `22_33_15` in your current directory.

### Local Swift Master table

When a Master table is not given to Swift-DeepSky (default), it uses VO services to query for Swift observations (in the specified RA,DEC,RADIUS region).
There may be situations you prefer to use a local Master table, though. For example, when you are running an all-sky processing and you want to avoid a big network traffic (requests to the VO server).

When you do that, specify the master table to be used (option `--master_table`) while using Docker containers, you must remember that containers run in there own, isolated environment; Containers cannot see outside, containers don't have access to files in the hosting operating system _unless_ you explicit share directories and files with it.

Thankfully, it is simple to get around that. As a matter of fact, we did something like that before when we _mounted the "sds_output" volume_ to have the outputs (generated inside the container) in our host system's `$HOME/sds_output`.

> We are going to use `sds_runs` instead of `sds_output` just because it makes more sense, since we will have our master-table in that directory. But it is just a name, the meaning is the same.

For example, suppose the Swift Master Table you want SDS to use is inside a local directory `$PWD/sds_runs` (`sds_runs` inside the current working directory, $PWD). The Master Table filename is `my_swift_master_table.csv` (see above for the format expected, or [bin/SwiftXrt_master.csv](bin/SwiftXrt_master.csv)). In this case, you will run SDS as follows:

```bash
$ ls sds_runs
my_swift_master_table.csv
$
$ docker run --rm -it --volumes-from caldb \
    -v $PWD/sds_runs:/work chbrandt/swift_deepsky \
    --master_table my_swift_master_table.csv \
    --ra 22 --dec 33 --radius 15
```

Again, if you always use the same directory to Input/Output data to/from the (SDS) container (eg, `$HOME/sds_runs`), you may very well create an alias:

```bash
$ alias swift_deepsky='docker run --rm -it --volumes-from caldb -v $HOME/sds_runs:/work chbrandt/swift_deepsky'
$
$ swift_deepsky --ra 22 --dec 33 --radius 15 --master_table my_swift_master_table.csv
```

> **Notice** that you do NOT specify the absolute path of `my_swift_master_table.csv` _in the host system terms_ (remember, the container doesn't know the host system's filesystem organization). You can, though, specify the absolute path _in the container terms_, `/work/my_swift_master_table.csv` in this case.


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
