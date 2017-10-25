#!/usr/bin/env python

# This simple-ugly-working script takes a file like the one below
# and transform in a table.
#
# Example input file
#------------------------------------------------------------------------------
#[XIMAGE> sosta/xpix=259.66666/ypix=364.33334/back=1.2362776E-07/eef_s=0.6
# Using MAP1
# Using constant background...
#                    X = 259.66666    Y = 364.33334
#  Using average energy for PSF:    1.0000000
# Source half-box for 0.55 EEF is    3.5 pixels
#        Half-box for 0.90 EEF is   12.6 pixels
# Total # of counts 1.0000000 (in 49 elemental sq pixels)
# Background/elemental sq pixel :                1.236E-07 +/- 5.0E-05
# Background/elemental sq pixel/sec :            2.741E-11 +/- 1.1E-08
#
# Source counts :                                1.000E+00 +/- 1.0E+00
# s.c. corrected for PSF :                       2.460E+00 +/- 2.5E+00
# s.c. corrected for PSF + sampling dead time
#                                + vignetting    3.187E+00 +/- 3.2E+00
# Source intensity :                             2.217E-04 +/- 2.2E-04 c/sec
# s.i. corrected for PSF                         5.453E-04 +/- 5.5E-04 c/sec
# s.i. corrected for PSF + sampling dead time
#                                + vignetting -> 7.065E-04 +/- 7.1E-04 c/sec <-
# Signal to Noise Ratio             :            1.000E+00
#                                                 Poisson    Gauss
# Pr. that source is a fluctuation of back. :    6.06E-06   0.00E+00
#
#
#    Exposure time                 :       4510.633 s
#    Vignetting correction         :      1.296
#    Sampling dead time correction :      1.000
#    PSF correction                :      2.460
#    Optimum half box size is      : 46.500000 orig pixels
#------------------------------------------------------------------------------

import sys

if len(sys.argv) < 3:
    from os.path import basename
    print('\nUsage: {} <sosta.log> <xray-band>'.format(basename(sys.argv[0])))
    sys.exit(1)

SOSTAFILE=sys.argv[1]
BAND=sys.argv[2]

fp = open(SOSTAFILE)
flux_neg=None
flux_pos=None
back=None
pix=None
expo=None
ul=None
error=None
cnt=None

SEP=' '
print(SEP.join(['(photon_flux_{0}(ph.s-1))',
                '(photon_flux_error_{0}(ph.s-1))',
                '(upper_limit_{0}(ph.s-1))',
                '(expected_background_{0}(ph))',
                '(detected_counts_{0}(ph))']).format(BAND))
def print_fluxes(flux,error,ul,expect,cnt):
    fmt="{1}{0}{2}{0}{3}{0}{4}{0}{5}"
    print(fmt.format(SEP,flux,error,ul,expect,cnt))

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
    if 'sosta' in line:
        if back is None:
            continue
        if ul != None:
            flux=float(flux_neg[2:])
            error=None
        else:
            flux=float(flux_pos)
        expect=float(back) * int(pix) * float(expo)
        print_fluxes(flux,error,ul,expect,cnt)
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
print_fluxes(flux,error,ul,expect,cnt)
