#!/usr/bin/env python

import astropy
import pandas
import datetime

import logging
import sys

# VO Swift Master table
#
URL = 'https://heasarc.gsfc.nasa.gov/cgi-bin/vo/cone/coneGet.pl?table=swiftmastr&VERB=3'

def select_observations(swift_mstr_table,ra,dec,fileout,obsaddrfile,radius=12,
                        start_time=None, end_time=None):

    def swift_archive_obs_path(date,obsid):
        '''
        Format 'date' and 'obsid' information for swift archive

        Input:
         - date : MJD
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
            "56469.9994" --> "2013-06-26 23:59:08" --> "2013_06"
            '''
            from astropy.time import Time
            from datetime import datetime
            try:
                # dt = datetime.strptime(archive_date,'%y/%m/%d %H:%M:%S')
                td = Time(archive_date,format='mjd')
                dt = td.datetime
            except ValueError as e:
                print("ERROR: while processing {}".format(archive_date),file=sys.stderr)
                print("ERROR: {}".format(e),file=sys.stderr)
                return None
            year_month = '{:4d}_{:02d}'.format(dt.year,dt.month)
            return year_month

        dtf = extract_date(date)

        if dtf is None:
            return None
        obs = '{:011d}'.format(int(obsid))
        return '{}/{}'.format(dtf,obs)

    # def conesearch(ra_centroid, dec_centroid, radius,
    #                 ra_list, dec_list):
    #     '''
    #     Return a bool array signaling the entries around centroid
    #
    #     Input:
    #      - ra_centroid : float
    #         Reference position' right ascension, in 'degree'
    #      - dec_centroid: float
    #         Reference position' declination, in 'degree'
    #      - radius : float
    #         Radius, in 'arcmin', to consider around central position
    #      - ra_list : list of floats
    #         List of RA positions (in 'degree') to consider
    #      - dec_list : list of floats
    #         List of Dec positions (in 'degree') to consider
    #
    #     Output:
    #      - Mask arrays : boolean one-dimensional array
    #         True for (ra/dec_list) positions within 'radius' arcmin
    #         from (ra/dec_centroid) reference, Flase otherwise
    #     '''
    #     from astropy.coordinates import Angle,SkyCoord
    #     radius = Angle(radius,unit='arcmin')
    #     coords = SkyCoord(ra_centroid, dec_centroid, unit='degree')
    #     # ramin = coords.ra - radius
    #     # ramax = coords.ra + radius
    #     # raind = (ra_list > ramin.value) * (ra_list < ramax.value)
    #     # decmin = coords.dec - radius
    #     # decmax = coords.dec + radius
    #     # decind = (dec_list > decmin.value) * (dec_list < decmax.value)
    #     # ind = raind * decind
    #     # ra_list = ra_list[ind]
    #     # dec_list = dec_list[ind]
    #     coords_search = SkyCoord(ra_list, dec_list, unit='degree')
    #
    #     match_mask = coords.separation(coords_search) < radius
    #     return match_mask

    def timefilter(table_master, start_time, end_time):
        """
        Input:
         - 'start_time' and 'end_time' are strings in format ISO
        """
        from datetime import datetime
        from astropy.time import Time
        import pandas as pd
        import numpy as np
        inds = np.ones(len(table_master)).astype(bool)
        if start_time is not None:
            try:
                start_time = start_time.strip().replace(' ','T')
                if 'T' in start_time:
                    dt_sel = Time(datetime.strptime(start_time, '%Y-%m-%dT%H:%M:%S')).mjd
                else:
                    dt_sel = Time(datetime.strptime(start_time, '%Y-%m-%d')).mjd
                dt_vec = table_master['start_time']
                inds &= dt_vec >= dt_sel
            except Exception as e:
                print('Given start-time format not understood:', start_time)
                return table_master
        if end_time is not None:
            try:
                end_time = end_time.strip().replace(' ','T')
                if 'T' in end_time:
                    dt_sel = Time(datetime.strptime(end_time, '%Y-%m-%dT%H:%M:%S')).mjd
                else:
                    dt_sel = Time(datetime.strptime(end_time, '%Y-%m-%d')).mjd
                dt_vec = table_master['start_time']
                inds &= dt_vec <= dt_sel
            except:
                print('Given end-time format not understood:', end_time)
                return table_master
        return table_master[inds]

    def select_pc_mode_200(table_master, threshold_seconds=200):
        inds = table_master['xrt_expo_pc'] > threshold_seconds
        return table_master[inds]

    print("Searching Swift Master table: {}".format(swift_mstr_table))
    print("Searching observations around position: {},{}".format(ra,dec))
    print("Search readius: {}".format(radius))

    # radius from arcmin to degree:
    radius = radius / 60.0

    from eada.vo import conesearch as cs
    table_master = cs.main(ra,dec,radius,swift_mstr_table)
    table_object = table_master.to_pandas()

    table_object = select_pc_mode_200(table_object)

    # If any time limit was given, filter the observations
    #
    if start_time or end_time:
        print('START/END-TIME', start_time, end_time)
        table_object = timefilter(table_object, start_time, end_time)

    print("Number of observations found: {:d}".format(len(table_object)))

    # print(table_object.info)

    if len(table_object) > 0:
        archive_addr = table_object.apply(lambda x:swift_archive_obs_path(x['start_time'],x['obsid']), axis=1)
        print("Observation addresses: {}".format(archive_addr.values))
    else:
        archive_addr = pandas.DataFrame()

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

    parser.add_argument('--start', type=str, default='',
                        help='Start time to select observations (datetime ISO format)')
    parser.add_argument('--end', type=str, default='',
                        help='End time to select observations (datetime ISO format)')

    # parser.add_argument('table_in', type=str,
    #                     help='Table (Swift) to conesearch')
    parser.add_argument('table_out', type=str,
                        help='Filtered table by conesearch')
    parser.add_argument('--archive_addr_list', type=str, default='archive_addr_list.txt',
                        help='List of (addresses) Swift Observations DATE/IDs')


    args = parser.parse_args()

    if args.name:
        obj = args.name
        pos = resolve_name(obj)
        if pos is None:
            print("\nERROR: Object '{}' not resolved.\n".format(obj),file=sys.stderr)
            sys.exit(1)
        ra,dec = pos
    if args.radec:
        radec = args.radec.split(',')
        ra,dec = [ float(c) for c in radec ]
    radius = float(args.radius)

    from os import path
    # tablefilein = args.table_in
    tablefileout = args.table_out
    obsaddrfile = args.archive_addr_list
    start_time = args.start if args.start else None
    end_time = args.end if args.end else None
    select_observations(URL, fileout=tablefileout,
                        obsaddrfile=obsaddrfile,
                        ra=ra, dec=dec, radius=radius,
                        start_time=start_time, end_time=end_time)
