### Swift Master table

The Swift Master Table is a table containing all the observations done the Swift
satellite over the time.
Among other information, it relates each observation to the corresponding
position in the sky and timestamp it was taken.

Per default, the Swift-DeepSky queries a VO service providing the Master Table
as a service.
The query requests all the observations in a given region of the sky (RA, Dec),
and the VO service returns the corresponding entries.

There may be situations, though, where you may prefer to use a local Master table, 
in CSV format. 
For example, when you are running an all-sky processing and you want to avoid a 
lot of network traffic, or in case the VO service is down.

This can be done by using SDS's `--master-table` option, indicating the location
of the (CSV) file.

When you do that, you must guarantee that you provide all the columns SDS needs,
with the proper name. The order of the columns is not important.

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


Here is an example of a Swift Master table 
(see [docs/notebook/SwiftXrt_master.csv](docs/notebook/SwiftXrt_master.csv):

```
NAME;ORIG_TARGET_ID;TARGET_ID;RA;DEC;START_TIME;STOP_TIME;ORIG_OBS_SEGM;OBS_SEGMENT;ORIG_OBSID;OBSID;XRT_EXPOSURE;XRT_EXPO_PC;ARCHIVE_DATE;PROCESSING_DA;PROCESSING_DATE;PROCESSING_VE
SAFE3-CURR;60002;60002;0.640524;0.2784;20/11/2004;21/11/2004;0;0;60002000;60002000;0;0;27/11/2004;HEA_20JULY2006_V6.1_SWIFT_REL2.5A(BLD19)_22SEP2006;14/11/2006;3.7.6
SAFE5-CURR;60004;60004;0.640524;0.2784;21/11/2004;21/11/2004;0;0;60004000;60004000;0;0;28/11/2004;HEA_20JULY2006_V6.1_SWIFT_REL2.5A(BLD19)_22SEP2006;12/11/2006;3.7.6
(...)
```
