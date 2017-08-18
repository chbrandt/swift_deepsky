# Swift Sum-Events

This pipeline --`bin/pipeline.sh`-- combine multiple Swift-XRT observations
from a specific region of the sky. The pipeline --`bin/*`-- is a mixture of
Python(v3) and Bash(v4) scripts; under the hood, astronomical tools are called.

The following software are required (tested versions):

* Bash (v4)
  * wget
  * curl
* Python3 (v3.6.2)
  * Pandas (v0.20.2)
  * Astropy (v2.0)
* HEASoft (v6.21)
  * XSelect
  * XImage
