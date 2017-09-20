#!/usr/bin/env python
import astropy

def resolve_name(name):
    '''
    Return ICRS position for given object 'name'

    Input:
     - name : str
        Object designation/name
    Output:
     - position : (float,float)
        Tuple with (RA,Dec) coordinates in degree
    '''
    from astropy.coordinates import get_icrs_coordinates as get_coords
    try:
        icrs = get_coords(name)
        pos = (icrs.ra.value,icrs.dec.value)
    except:
        pos = None
    return pos



if __name__ == '__main__':
    import sys

    args = sys.argv[:]
    if len(args) == 1:
        print("\nUsage: {} <object-name>\n".format(args[0]))
        sys.exit(1)

    obj = args[1]

    pos = resolve_name(obj)
    if pos is None:
        print("\nERROR: Object '{}' not resolved.\n".format(obj),file=sys.stderr)
        sys.exit(1)

    ra,dec = pos
    print("Object {} position (RA,Dec): {:.4f},{:.4f}".format(obj,ra,dec))
    sys.exit(0)
