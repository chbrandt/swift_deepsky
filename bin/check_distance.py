from astropy import units as u
from astropy.coordinates import SkyCoord

def arcmin_separation(ra_o, dec_o, ra_file, dec_file):
    c1 = SkyCoord(ra_o, dec_o, frame='icrs', unit='deg')
    c2 = SkyCoord(ra_file, dec_file, frame='icrs', unit='deg')
    sep = c1.separation(c2)
    return sep.arcminute

if __name__ == "__main__":
    import sys
    try:
        ra_o, dec_o, ra_file, dec_file, radius = list(map(float, sys.argv[1:]))
        sep = arcmin_separation(ra_o, dec_o, ra_file, dec_file)
    except Exception as err:
        print(err)
        sep = 0
    # print('SEPARATION',sep)
    if sep < radius:
        sys.exit(0)
    else:
        sys.exit(1)
