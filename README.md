# Swift DeepSky
This pipeline combines multiple Swift-XRT observations of a given position of the sky.
The pipeline components were written using Python, Bash, Perl and even Fortran.
Oh, and HEASoft; you have to have it: https://heasarc.nasa.gov/lheasoft/


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


## Install
Once the dependencies were satisfied, (See "Setup dependencies" below)
to install the package is a two-steps process.

First we have to compile a small fortran code inside `~/bin/countrates`.
Just `cd` into this directory and execute the script `compile.sh`.

The second step is actually optional: to include `~/bin` in your `PATH`
variable f you want to simplify your calls to `~/bin/pipeline.sh`.


## Setup dependencies

### Bash
You probably have the dependencies available, double check them though.

### Python
If you have Anaconda python distribution you could do:
```
# conda install pandas astropy
```

Otherwise, you may use `pip`:
```
# pip install pandas
# pip install astropy
```

### Perl
You probably have `cpan` in your machine, should be as easy as:
```
# cpan WWW::Mechanize
# cpan Carp::Assert
# cpan Archive::Tar
```
If something blocked you, see if CPAN-Minus can help you.
Try `cpan App::cpanminus`. That should work smooth, then retry the above commands.

### HEASoft
Following the instructions from https://heasarc.nasa.gov/lheasoft/install.html


## Run
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
