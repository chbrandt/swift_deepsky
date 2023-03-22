#!/usr/bin/env python

import astropy
import pandas
import datetime

import logging
import sys

def select_observations(swift_mstr_table,ra,dec,fileout,obsaddrfile,radius=12,
                        start_time=None, end_time=None, master_time_format='%y/%m/%d %H:%M:%S'):

    # ------------------------------------------------------------------------
    # Start aux functions
    # ------------------------------------------------------------------------

    def swift_archive_obs_path(date, obsid, date_format):
        '''
        Format 'date' and 'obsid' information for swift archive

        Input:
         - date : datetime string
         - obsid : str or int
            Swift OBSID code, e.g, "49650001"
         - date_format : datetime string format
            Default is '%y/%m/%d %H:%M:%S' (13/06/26 23:59:12)

        Output:
         - Swift archive DATE/OBSID address : string
            For example: "2013_06/00049650001"
        '''
        def extract_date(archive_date, date_format):
            '''
            Extract year/month from swift date format

            Example:
            "13/06/26 23:59:12" --> "2013_06"
            '''
            from datetime import datetime
            try:
                # dt = datetime.strptime(archive_date,'%y/%m/%d %H:%M:%S')
                # dt = datetime.strptime(archive_date,'%d/%m/%Y')
                dt = datetime.strptime(archive_date, date_format)
            except ValueError as e:
                print("ERROR: while processing {}".format(archive_date),file=sys.stderr)
                print("ERROR: {}".format(e),file=sys.stderr)
                return None
            year_month = '{:4d}_{:02d}'.format(dt.year,dt.month)
            return year_month

        dtf = extract_date(date, date_format)

        if dtf is None:
            return None
        obs = '{:011d}'.format(int(obsid))
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
        # ramin = coords.ra - radius
        # ramax = coords.ra + radius
        # raind = (ra_list > ramin.value) * (ra_list < ramax.value)
        # decmin = coords.dec - radius
        # decmax = coords.dec + radius
        # decind = (dec_list > decmin.value) * (dec_list < decmax.value)
        # ind = raind * decind
        # ra_list = ra_list[ind]
        # dec_list = dec_list[ind]
        coords_search = SkyCoord(ra_list, dec_list, unit='degree')
        match_mask = coords.separation(coords_search) < radius
        return match_mask

    def timefilter(table_master, start_time, end_time, master_time_format='%Y-%m-%d %H:%M:%S'):
        """
        Input:
         - 'start_time' and 'end_time' are strings in ISO format ('%Y-%m-%dT%H:%M:%S' or '%Y-%m-%d')
        """
        from datetime import datetime
        import pandas as pd
        import numpy as np
        
        user_time_format='%Y-%m-%dT%H:%M:%S'

        inds = np.ones(len(table_master)).astype(bool)
        if start_time is not None:
            try:
                start_time = start_time.strip().replace(' ','T')
                if 'T' in start_time:
                    dt_sel = datetime.strptime(start_time, user_time_format)
                else:
                    dt_sel = datetime.strptime(start_time+'T00:00:01', user_time_format)
                dt_vec = pd.to_datetime(table_master['START_TIME'], format=master_time_format)
                inds &= dt_vec >= dt_sel
            except Exception as e:
                print('Given start-time format not understood:', start_time)
                return table_master
        if end_time is not None:
            try:
                end_time = end_time.strip().replace(' ','T')
                if 'T' in end_time:
                    dt_sel = datetime.strptime(end_time, user_time_format)
                else:
                    dt_sel = datetime.strptime(end_time+'T23:59:59', user_time_format)
                dt_vec = pd.to_datetime(table_master['START_TIME'], format=master_time_format)
                inds &= dt_vec <= dt_sel
            except Exception as e:
                print('Given end-time format not understood:', end_time)
                return table_master
        return table_master[inds]

    def select_pc_mode_200(table_master, threshold_seconds=200):
        inds = table_master['XRT_EXPO_PC'] > threshold_seconds
        return table_master[inds]

    # ------------------------------------------------------------------------
    # End aux functions
    # ------------------------------------------------------------------------

    import pandas

    print("Searching Swift Master table: {}".format(swift_mstr_table))
    print("Searching observations around position: {},{}".format(ra,dec))
    print("Search readius: {}".format(radius))

    table_master = pandas.read_csv(swift_mstr_table, sep=';', header=0, low_memory=False)

    table_radec = table_master[['RA','DEC']]
    match_obs_mask = conesearch(ra, dec, radius=radius,
                                ra_list=table_radec['RA'].values,
                                dec_list=table_radec['DEC'].values)
    table_object = table_master.loc[match_obs_mask]

    table_object = select_pc_mode_200(table_object)

    # If any time limit was given, filter the observations
    #
    if start_time or end_time:
        print('START/END-TIME', start_time, end_time)
        table_object = timefilter(table_object, start_time, end_time, master_time_format)

    print("Number of observations found: {:d}".format(len(table_object)))

    if len(table_object) > 0:
        archive_addr = table_object.apply(
            lambda x:swift_archive_obs_path(x['START_TIME'],x['OBSID'], master_time_format), 
            axis=1)
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

    parser.add_argument('--table_time_format', type=str, default='%Y-%m-%d %H:%M:%S',
                        help='Datetime format used in (START_TIME) "table_in" (swift-master-table)')
    parser.add_argument('--archive_addr_list', type=str, default='archive_addr_list.txt',
                        help='List of (addresses) Swift Observations DATE/IDs')

    parser.add_argument('table_in', type=str,
                        help='Table (Swift) to conesearch')
    parser.add_argument('table_out', type=str,
                        help='Filtered table by conesearch')


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
    tablefilein = args.table_in
    tablefileout = args.table_out
    obsaddrfile = args.archive_addr_list
    start_time = args.start if args.start else None
    end_time = args.end if args.end else None
    master_time_format = args.table_time_format
    select_observations(tablefilein, fileout=tablefileout,
                        obsaddrfile=obsaddrfile,
                        ra=ra, dec=dec, radius=radius,
                        start_time=start_time, end_time=end_time,
                        master_time_format=master_time_format)
