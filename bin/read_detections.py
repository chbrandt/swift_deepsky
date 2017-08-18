#!/usr/bin/env python

import sys

SOSTAFILE=sys.argv[1]

fp = open(SOSTAFILE)
flux_neg=None
flux_pos=None
back=None
pix=None
expo=None
ul=None
error=None
cnt=None

print('cts/s','cts/s_error','cts/s_UL','Expect_background','Detected_counts')
for i,line in enumerate(fp.readlines()):
    if 'Background/elemental sq pixel :' in line:
        fields = line.split()
        back = fields[4]
    if 'Total' in line:
        fields = line.split()
        pix = fields[6]
        cnt = fields[4]
    if '+ vignetting ->' in line:
        fields = line.split()
        flux_neg =  fields[2]
        flux_pos =  fields[3]
        error = fields[5]
    if 'Exposure time' in line:
        fields = line.split()
        expo =  fields[3]
    if 'upper' in line:
        fields = line.split()
        ul =  fields[5]
    if '[XIMAGE> sosta' in line:
        if back is None:
            continue
        if ul != None:
            flux=float(flux_neg[2:])
            error=None
        else:
            flux=float(flux_pos)
        expect=float(back) * int(pix) * float(expo)
        print(flux,error,ul,expect,cnt)
        flux_neg=None
        flux_pos=None
        back=None
        pix=None
        expo=None
        ul=None
        error=None
        cnt=None

if ul != None:
    flux=float(flux_neg[2:])
    error=None
else:
    flux=float(flux_pos)
expect=float(back) * int(pix) * float(expo)
print(flux,error,ul,expect,cnt)
