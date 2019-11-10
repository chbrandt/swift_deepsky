#!/bin/bash

# This script checks the order in which event-files and exposure-maps were
# processed on XSelect and XImage, resp. In particular, it checks for the
# first observation used in each case; The first observation dictates the
# the (internal) mapping between space coordinates (RA,Dec) and image
# coordinates (X,Y), when XSelect and XImage map those coordinates differently,
# subsequent processing (e.g., objects detection) may suffer inconsistency.
#
# The script is meant to be run from the top directory where (all) SDS
# output directories are stored. What the script does is to go inside (each)
# output directory, unpack the 'tmp.tgz' tarball, extract the list of
# event-files used in 'tmp/events_sun.xcm' (XSelect) script and also
# the list of exposure-maps used in 'tmp/expos_sum.xco' (XImage) script.
# Then, those lists are compared to check (1) whether they are different,
# and (2) whether the first observation is different. In the (unlikely)
# case(s) they are different a message is printed to stdout.

for output_dir in *; do
    # Skip in case a directory does not contain a 'tmp/tgz' file
    [[ -f "${output_dir}/tmp.tgz" ]] || continue

    (
    cd "$output_dir"

    # Unpack 'tmp.tgz'
    tar -xzf tmp.tgz

    # Create list of expo-maps' and first observation used
    EXPOS='expos.list'
    EXPOS_1='expos_first.list'
    grep "ex.img" "tmp/expos_sum.xco" | awk 'BEGIN{FS="/"}{split($NF,a,"_"); print a[1]}' > $EXPOS
    head -n1 $EXPOS > $EXPOS_1

    # Create list of event-files' observations
    EVENTS='events.list'
    EVENTS_1='events_first.list'
    grep "cl.evt.gz" "tmp/events_sum.xcm" | awk '{split($NF,a,"_"); print a[1]}' > $EVENTS
    head -n1 $EVENTS > $EVENTS_1

    # If 1st observations are different, enough to print/alert the user and skip to next 'output_dir'
    diff -q -w $EXPOS_1 $EVENTS_1 &> /dev/null || { echo "${output_dir}: DIFFERENT 1st OBSERVATIONS USED"; exit 1; }

    # First observations are the same, since we are here, check if the overall order is different then
    diff -q -w $EXPOS $EVENTS &> /dev/null || echo "${output_dir}: different observations order"
    )
done
