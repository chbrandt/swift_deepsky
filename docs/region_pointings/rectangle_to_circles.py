#!/usr/bin/env python

def heppes_melissen(length,radius):
    '''
    From "Covering a rectangle with equal circles",
    A. Heppes and H. Melissen, 1997,
    Periodica Mathematica Hungarica

    The article considers that the rectangle, of length='length'
    has width=2*'radius'/sqrt(2) .
    It also considers that 'length > n/sqrt(3)'.
    '''
    from math import sqrt,ceil
    den = 4*(radius**2)-1
    if den <= 0:
        return None
    n = sqrt( (length**2) / den )
    return ceil(n)

def rectangle_to_circles(xy_bottom_left,xy_top_right,circle_radius):
    '''
    '''
    xbl,ybl = xy_bottom_left
    xtr,ytr = xy_top_right

    height_half = abs(ytr-ybl)/2.0
    width_half = abs(xtr-xbl)/2.0
    x_center_rect = xbl + width_half
    y_center_rect = ybl + height_half

    from math import sqrt
    semi_diag = sqrt(height_half**2 + width_half**2)
    if circle_radius >= semi_diag:
        return [(x_center_rect,y_center_rect)]

    r_square = circle_radius/sqrt(2)

    x_center_circ = r_square
    y_center_circ = r_square
    n_horizontal = heppes_melissen(width_half*2, circle_radius)
    n_vertical = heppes_melissen(height_half*2, circle_radius)
    if n_horizontal is None or n_vertical is None:
        print('Choose a bigger value for radius')
        return None

    from numpy import linspace
    xcs = linspace(0,width_half*2,n_horizontal)[:-1] + x_center_circ
    ycs = linspace(0,height_half*2,n_vertical)[:-1] + y_center_circ

    # from numpy import meshgrid
    # grid = meshgrid(xcs,ycs,indexing='ij')

    from itertools import product
    xyr = [xcs,ycs,[circle_radius]]
    coords = [ c for c in product(*xyr) ]
    
    return coords
