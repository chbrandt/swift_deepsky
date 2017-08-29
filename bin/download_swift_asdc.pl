#!/usr/bin/env perl
#-*- coding:utf8 -*-

use strict;
use warnings;
use Carp::Assert;

use feature qw(say);

# Tools to query/retrieve Swift data from ASDC website.
#

# Function to retrieve all GRBs table detected by Swift only
use WWW::Mechanize;
sub open_url {
  my $seq = $_[0];
  my $date = $_[1];
  my $baseurl = 'http://swift.asdc.asi.it/cgi-bin/listobs';
  my $url = sprintf('%s?seq=%011d&date=%s',$baseurl,$seq,$date);
  use WWW::Mechanize;
  my $mech = WWW::Mechanize->new();
  $mech->get( $url );
  return $mech;
}

sub download_observation {
  # Arguments
  # - OBSID (11 digits)
  # - DATE (YYYY_MM)
  # - OUTDIR
  my $seq = $_[0];
  my $date = $_[1];
  my $outdir = $_[2];
  my $mech = open_url($seq,$date);
  my $form = $mech->form_number(1);

  $mech->set_visible( [ radio => "tar" ] );
  $mech->tick("/","on");
  $mech->submit();

  my $outfile = sprintf("%s/%011d.tar",$outdir,$seq);
  $mech->save_content($outfile);
}

my $nargs = $#ARGV + 1;
if ($nargs < 2) {
  say "\nUsage: $0 <OBSID> <START_TIME> [output-dir]";
  say "";
  say "Positional arguments:";
  say "  OBSID      : Swift 11-digits observation identifier";
  say "  START_TIME : observation's date in format 'YYYY_MM'";
  say "  output-dir : (optional) directory to write data";
  say "";
  exit 1;
}

my $obsid = $ARGV[0];
my $date = $ARGV[1];
my $outdir = "./";
if ($nargs == 3) {
  $outdir = $ARGV[2];
}
if (not(-e $outdir and -d $outdir and -w $outdir)) {
  say "\nERROR: Verify '$outdir', it be a directory and writable by you\n";
  exit 1;
}
download_observation($obsid,$date,$outdir);
