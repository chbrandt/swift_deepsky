#!/usr/bin/env python

def weight_position(exposures, ras, decs):
    assert len(exposures) == len(ras), "Exposures vector expected to be same-size as RA's"
    assert len(exposures) == len(decs), "Exposures vector expected to be same-size as DEC's"
    ra = 0
    dec = 0
    for i in range(len(exposures)):
        ra += ras[i] * exposures[i]
        dec += decs[i] * exposures[i]
    sum_exposures = sum(exposures)
    ra = ra/sum_exposures
    dec = dec/sum_exposures
    return (ra,dec)

if __name__ == '__main__':
    import sys
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--expos', nargs='*', type=float)
    parser.add_argument('--ras', nargs='*', type=float)
    parser.add_argument('--decs', nargs='*', type=float)
    args = parser.parse_args()
    ra,dec = weight_position(args.expos, args.ras, args.decs)
    print("{:f},{:f}".format(ra,dec))
