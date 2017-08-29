#!/usr/bin/env python

import astropy
import pandas
import datetime

import logging

def select_observations(swift_mstr_table,ra,dec,fileout,obsaddrfile,radius=12):

    def swift_archive_obs_path(date,obsid):
        '''
        Format 'date' and 'obsid' information for swift archive

        Input:
         - date : datetime string
            For example: "13/06/26 23:59:12"
         - obsid : str or int
            Swift OBSID code, e.g, "49650001"

        Output:
         - Swift archive DATE/OBSID address : string
            For example: "2013_06/00049650001"
        '''
        def extract_date(archive_date):
            '''
            Extract year/month from swift date format

            Example:
            "13/06/26 23:59:12" --> "2013_06"
            '''
            from datetime import datetime
            try:
                # dt = datetime.strptime(archive_date,'%y/%m/%d %H:%M:%S')
                dt = datetime.strptime(archive_date,'%d/%m/%Y')
            except ValueError as e:
                print("ERROR: while processing {}".format(archive_date))
                print("ERROR: {}".format(e))
                return None
            year_month = '{:4d}_{:02d}'.format(dt.year,dt.month)
            return year_month

        dtf = extract_date(date)

        if dtf is None:
            return None
        obs = '{:011d}'.format(obsid)
        return '{}/{}'.format(dtf,obs)

    def conesearch(ra_centroid, dec_centroid, radius,
                    ra_list, dec_list):
        '''
        Return a bool array signaling the entries around centroid

        Input:
         - ra_centroid : float
            Reference position' right ascension, in 'degree'
         - dec_centroid: float
            Reference position' declination, in 'degree'
         - radius : float
            Radius, in 'arcmin', to consider around central position
         - ra_list : list of floats
            List of RA positions (in 'degree') to consider
         - dec_list : list of floats
            List of Dec positions (in 'degree') to consider

        Output:
         - Mask arrays : boolean one-dimensional array
            True for (ra/dec_list) positions within 'radius' arcmin
            from (ra/dec_centroid) reference, Flase otherwise
        '''
        from astropy.coordinates import Angle,SkyCoord
        radius = Angle(radius,unit='arcmin')
        coords = SkyCoord(ra_centroid, dec_centroid, unit='degree')
        coords_search = SkyCoord(ra_list, dec_list, unit='degree')

        match_mask = coords.separation(coords_search) < radius
        return match_mask

    print("Searching Swift Master table: {}".format(swift_mstr_table))
    print("Searching observations around position: {},{}".format(ra,dec))
    print("Search readius: {}".format(radius))

    import pandas
    table_master = pandas.read_csv(swift_mstr_table, sep=';', header=0)

    table_radec = table_master[['RA','DEC']]
    match_obs_mask = conesearch(ra, dec, radius=radius,
                                ra_list=table_radec['RA'], dec_list=table_radec['DEC'])
    table_object = table_master.loc[match_obs_mask]
    print("Number of observations found: {:d}".format(len(table_object)))

    archive_addr = table_object.apply(lambda x:swift_archive_obs_path(x['START_TIME'],x['OBSID']), axis=1)
    print("Observation addresses: {}".format(archive_addr))

    from os.path import isdir,dirname
    if not isdir(dirname(fileout)):
        print('Needs to create dir for {}'.format(fileout))
    table_object.to_csv(fileout, index=False)
    if not isdir(dirname(obsaddrfile)):
        print('Needs to create dir for {}'.format(obsaddrfile))
    archive_addr.to_csv(obsaddrfile, index=False)
    print("Filtered table written to: {}".format(fileout))


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
    import argparse

    parser = argparse.ArgumentParser(description='Conesearch observations from Swift Master Table')

    group = parser.add_mutually_exclusive_group()
    group.add_argument("--position", dest='radec', type=str,
                        help="(RA,Dec) coordinates. Ex: 194.04,-5.789")
    group.add_argument("--object", dest='name', type=str,
                        help="Object name. Ex: 3c279")

    parser.add_argument('--radius', type=float, default=12,
                        help='Search radius in ARCMIN (default: 12)')

    parser.add_argument('table_in', type=str,
                        help='Table (Swift) to conesearch')
    parser.add_argument('table_out', type=str,
                        help='Filtered table by conesearch')
    parser.add_argument('--archive_addr_list', type=str, default='archive_addr_list.txt',
                        help='List of (addresses) Swift Observations DATE/IDs')


    args = parser.parse_args()

    if args.name:
        obj = args.name
        pos = resolve_name(obj)
        if pos is None:
            print("\nERROR: Object '{}' not resolved.\n".format(obj))
            sys.exit(1)
        ra,dec = pos
    if args.radec:
        radec = args.radec.split(',')
        ra,dec = [ float(c) for c in radec ]
    radius = float(args.radius)

    from os import path
    tablefilein = args.table_in
    tablefileout = args.table_out
    obsaddrfile = args.archive_addr_list
    select_observations(tablefilein, fileout=tablefileout,
                        obsaddrfile=obsaddrfile,
                        ra=ra, dec=dec, radius=radius)
