#!/usr/bin/env python

# This simple-ugly-working script takes a file like the one below
# and transform in a table.
#
# Example input file
#------------------------------------------------------------------------------
# read/size=1024/ecol=PI/emin=201/emax=1000 947_5_1_sum.evt
#  Telescope SWIFT XRT
#  Image size = 1024 x 1024 pixels
#  Image rebin = 1.000
#  Image center = 500.5, 500.5
#  Energy column = PI Min = 201 Max = 1000
#  Using gti for exposure 13484.2594005 s
#  Reading an events file
#  File contains       2895 events
#  Accepted: 1130 Rejected: 1765
#   Image level, min = 0.0000000 max = 2.0000000
#  Copied MAP1 to MAP9
#  read/size=1024/expo .//947_5_1_sum.exp
#  Telescope SWIFT XRT
#  Image size = 1024 x 1024 pixels
#  Image rebin = 1.000
#  Image center = 500.5, 500.5
#  Reading an image
#   Image level, min = 0.0000000 max = 13484.614
#  sosta/xpix=457.45834/ypix=513.29169/back=3.0157142E-07/eef_s=0.6
#  Using MAP1
#  Using constant background...
#                     X = 457.45834    Y = 513.29169
#   Using average energy for PSF:    1.0000000
#  Source half-box for 0.57 EEF is    4.4 pixels
#         Half-box for 0.90 EEF is   18.5 pixels
#  Total # of counts 0.0000000 (in 72 elemental sq pixels)
#  Background/elemental sq pixel :                3.016E-07 +/- 6.5E-05
#  Background/elemental sq pixel/sec :            2.242E-11 +/- 4.8E-09
#
#  Source counts :                               -2.171E-05 +/- 4.7E-03
#  s.c. corrected for PSF :                      -4.562E-05 +/- 9.8E-03
#  s.c. corrected for PSF + sampling dead time
#                                 + vignetting   -4.590E-05 +/- 9.8E-03
#  Source intensity :                            -1.614E-09 +/- 3.5E-07 c/sec
#  s.i. corrected for PSF                        -3.392E-09 +/- 7.3E-07 c/sec
#  s.i. corrected for PSF + sampling dead time
#                                 + vignetting ->-3.412E-09 +/- 7.3E-07 c/sec <-
#  Signal to Noise Ratio             :           -4.660E-03
#                                                  Poisson    Gauss
#  Pr. that source is a fluctuation of back. :    1.00E+00   5.02E-01
#
#     Exposure time                 :      13451.856 s
#     Vignetting correction         :      1.006
#     Sampling dead time correction :      1.000
#     PSF correction                :      2.101
#
#       Three sigma upper limit : 1.04E-03 cts/s
#     Optimum half box size is      : 2.5000000 orig pixels
#  sosta/xpix=477.25000/ypix=445.00000/back=3.0157142E-07/eef_s=0.6
#  Using MAP1
#  Using constant background...
#                     X = 477.25000    Y = 445.00000
#   Using average energy for PSF:    1.0000000
#  Source half-box for 0.58 EEF is    4.3 pixels
#         Half-box for 0.90 EEF is   18.0 pixels
#  Total # of counts 4.0000000 (in 81 elemental sq pixels)
#  Background/elemental sq pixel :                3.016E-07 +/- 6.1E-05
#  Background/elemental sq pixel/sec :            2.236E-11 +/- 4.5E-09
#
#  Source counts :                                4.000E+00 +/- 2.0E+00
#  s.c. corrected for PSF :                       8.318E+00 +/- 4.2E+00
#  s.c. corrected for PSF + sampling dead time
#                                 + vignetting    8.408E+00 +/- 4.2E+00
#  Source intensity :                             2.966E-04 +/- 1.5E-04 c/sec
#  s.i. corrected for PSF                         6.169E-04 +/- 3.1E-04 c/sec
#  s.i. corrected for PSF + sampling dead time
#                                 + vignetting -> 6.235E-04 +/- 3.1E-04 c/sec <-
#  Signal to Noise Ratio             :            2.000E+00
#                                                  Poisson    Gauss
#  Pr. that source is a fluctuation of back. :    0.00E+00   0.00E+00
#
#
#     Exposure time                 :      13484.259 s
#     Vignetting correction         :      1.011
#     Sampling dead time correction :      1.000
#     PSF correction                :      2.080
#     Optimum half box size is      : 80.500000 orig pixels
#  sosta/xpix=612.00000/ypix=487.11765/back=3.0157142E-07/eef_s=0.6
#  Using MAP1
#  Using constant background...
#                     X = 612.00000    Y = 487.11765
#   Using average energy for PSF:    1.0000000
#   (...)
#------------------------------------------------------------------------------

import sys

if len(sys.argv) < 3:
    from os.path import basename
    print('\nUsage: {} <sosta.log> <xray-band>'.format(basename(sys.argv[0])))
    sys.exit(1)

SOSTAFILE = sys.argv[1]
BAND = sys.argv[2]

fp = open(SOSTAFILE)
flux_neg = None
flux_pos = None
back = None
size = None
expo = None
ul = None
error = None
counts = None

SEP = ' '
print(SEP.join(['photon_flux_{0}(ph.s-1)',
                'photon_flux_error_{0}(ph.s-1)',
                'upper_limit_{0}(ph.s-1)',
                'expected_background_{0}(ph)',
                'detected_counts_{0}(ph)']).format(BAND))


def print_fluxes(flux, error, ul, expect, counts):
    fmt = "{1}{0}{2}{0}{3}{0}{4}{0}{5}"
    print(fmt.format(SEP, flux, error, ul, expect, counts))


for i, line in enumerate(fp.readlines()):

    if 'Background/elemental sq pixel :' in line:
        fields = line.split()
        back = fields[4]

    if 'Total # of counts' in line:
        fields = line.split()
        counts = fields[4]
        size = fields[6]

    if '+ vignetting ->' in line:
        fields = line.split()
        flux_neg = fields[2]
        flux_pos = fields[3]
        error = fields[5]

    if 'Exposure time' in line:
        fields = line.split()
        expo = fields[3]

    if 'upper' in line:
        fields = line.split()
        ul = fields[5]

    if 'sosta' in line:
        if back is None:
            continue

        if ul is None:
            flux = float(flux_pos)
        else:
            flux = float(flux_neg[2:])
            error = None

        expect = float(back) * int(size) * float(expo)

        print_fluxes(flux, error, ul, expect, counts)

        # Clear variables
        flux_neg = None
        flux_pos = None
        back = None
        size = None
        expo = None
        ul = None
        error = None
        counts = None

if ul is None:
    flux = float(flux_pos)
else:
    flux = float(flux_neg[2:])
    error = None

expect = float(back) * int(size) * float(expo)

print_fluxes(flux, error, ul, expect, counts)
