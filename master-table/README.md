# Swift Master Table

The Swift Master Table is a table containing all the observations done the Swift
satellite over the time.
Among other information, it relates each observation to the corresponding
position in the sky and timestamp it was taken.

Per default, the Swift-DeepSky queries a VO service providing the Master Table
as a service.
The query requests all the observations in a given region of the sky (RA, Dec),
and the VO service returns the corresponding entries.

There may be situations, though, that you may prefer to use a local Master table, 
in CSV format. 
For example, when you are running an all-sky processing and you want to avoid a 
lot of network traffic, or in case the VO service is down.

This can be done by using SDS's `--master-table` option, indicating the location
of the (CSV) file.

An up-to-date master table can be downloaded at:

- https://heasarc.gsfc.nasa.gov/FTP/heasarc/dbase/tdat_files/heasarc_swiftmastr.tdat.gz

SDS is sensitive to the names of the columns. The order of the columns is not important.
Specifically, the columns (and values format) SDS expects are:

| Column | Format/Unit/Type |
| --- | --- |
|NAME| |
|ORIG_TARGET_ID| integer |
|TARGET_ID| integer |
|RA | degrees/float |
|DEC | degrees/float |
|START_TIME | DD/MM/YYYY |
|STOP_TIME | DD/MM/YYYY |
|ORIG_OBS_SEGM| |
|OBS_SEGMENT| |
|ORIG_OBSID| integer |
|OBSID| integer |
|XRT_EXPOSURE| |
|XRT_EXPO_PC| |
|ARCHIVE_DATE | DD/MM/YYYY |
|PROCESSING_DA| |
|PROCESSING_DATE| DD/MM/YYYY |
|PROCESSING_VE | | 


Here is an example of a Swift Master table (from some time ago) properly formatted
(see [docs/notebook/SwiftXrt_master.csv](docs/notebook/SwiftXrt_master.csv):

```
NAME;ORIG_TARGET_ID;TARGET_ID;RA;DEC;START_TIME;STOP_TIME;ORIG_OBS_SEGM;OBS_SEGMENT;ORIG_OBSID;OBSID;XRT_EXPOSURE;XRT_EXPO_PC;ARCHIVE_DATE;PROCESSING_DA;PROCESSING_DATE;PROCESSING_VE
SAFE3-CURR;60002;60002;0.640524;0.2784;20/11/2004;21/11/2004;0;0;60002000;60002000;0;0;27/11/2004;HEA_20JULY2006_V6.1_SWIFT_REL2.5A(BLD19)_22SEP2006;14/11/2006;3.7.6
SAFE5-CURR;60004;60004;0.640524;0.2784;21/11/2004;21/11/2004;0;0;60004000;60004000;0;0;28/11/2004;HEA_20JULY2006_V6.1_SWIFT_REL2.5A(BLD19)_22SEP2006;12/11/2006;3.7.6
(...)
```


## HEASARC Table

If you get the `swiftmastr` table from the NASA's High Energy Astrophysics
archive you'll notice the `.tdat` file contains metadata before the 
`<DATA>` element.

The script `tdat-2-csv.sh` transform the `tdat` file into a `csv` 
(with `|` as field separator).

In the command-line, do:

```bash
% wget https://heasarc.gsfc.nasa.gov/FTP/heasarc/dbase/tdat_files/heasarc_swiftmastr.tdat.gz
```

Run the script to generate the (csv) table:

```bash
% ./tdat-2-csv.sh -i heasarc_swiftmastr.tdat -o swiftmastr.csv
```

Inspect the content:

```bash
% head -n3 swiftmastr.csv
NAME|ORIG_TARGET_ID|TARGET_ID|RA|DEC|ROLL_ANGLE|START_TIME|STOP_TIME|ORIG_OBS_SEGMENT|OBS_SEGMENT|ORIG_OBSID|OBSID|XRT_EXPOSURE|UVOT_EXPOSURE|BAT_EXPOSURE|XRT_EXPO_LR|XRT_EXPO_PU|XRT_EXPO_WT|XRT_EXPO_PC|XRT_EXPO_IM|UVOT_EXPO_UU|UVOT_EXPO_BB|UVOT_EXPO_VV|UVOT_EXPO_W1|UVOT_EXPO_W2|UVOT_EXPO_M2|UVOT_EXPO_WH|UVOT_EXPO_GU|UVOT_EXPO_GV|UVOT_EXPO_MG|UVOT_EXPO_BL|BAT_EXPO_EV|BAT_EXPO_SV|BAT_EXPO_RT|BAT_EXPO_MT|BAT_EXPO_PL|BAT_NO_MASKTAG|ARCHIVE_DATE|SOFTWARE_VERSION|PROCESSING_DATE|PROCESSING_VERSION|NUM_PROCESSED|PRNB|PI|ATT_FLAG|TDRSS_FLAG|GRB_FLAG|LII|BII|SAA_FRACTION|AF_TOTAL|AF_ONSOURCE|AF_INSLEW|AF_INSAA|CYCLE
saa-cold-103-0|74481|74481|312.55080216|-89.99061318|154.33022255378|54289.1548726852|54289.2303240741|18|18|00074481018|00074481018|247.11|0|490|0|0|33.998|213.112|0|0|0|0|0|0|0|0|0|0|0|0|0|490|1801.6|5424|1792|5|54300|Hea_21Dec2012_V6.13_Swift_Rel4.0(Bld29)_14Dec2012_SDCpatch_15|57219|3.16.09|5|1|Swift|110|N|N|302.94108088|-27.13290051|0.962750970681874|1798.79940000176|1744.99953898787|53.7998610138893|1680|0
saa-cold-103-0|74481|74481|2.31345068|-89.98788851|328.884766769837|54149.2159837963|54149.2911111111|8|8|00074481008|00074481008|224.007|0|389|0|0|224.007|0|0|0|0|0|0|0|0|0|0|0|0|0|0|389|1800|5400|0|3|54160|Hea_21Dec2012_V6.13_Swift_Rel4.0(Bld29)_14Dec2012_SDCpatch_15|57191|3.16.09|5|1|Swift|110|N|N|302.93440912|-27.14015814|0.979549509453624|1797.59950000048|1714.99939900637|82.6001009941101|1679.92682000995|0
```

You can also check if all lines have the same number of fields
(there should be only one number output, `55` columns):

```bash
% awk -F '|' '{print NF}' swiftmastr.csv| uniq
55
```
