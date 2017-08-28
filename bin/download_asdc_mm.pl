#!/usr/bin/env perl
#-*- coding:utf8 -*-

use strict;
use warnings;
use Carp::Assert;

# Tools to query/retrieve Swift data from ASDC website.
#

# Function to retrieve all GRBs table detected by Swift only
use WWW::Mechanize;
sub _open_url(){
  my $url = 'https://swift.gsfc.nasa.gov/archive/grb_table/';

  use WWW::Mechanize;
  my $mech = WWW::Mechanize->new();
  $mech->get( $url );
  return $mech;
}

use LWP::UserAgent;
sub get_all_grbs(){
  my $mech = _open_url();
  my $form = $mech->form_number(2);

  $mech->tick("bat_ra",1);
  $mech->tick("bat_dec",1);
  $mech->tick("bat_err_radius",1);
  $mech->tick("xrt_ra",1);
  $mech->tick("xrt_dec",1);
  $mech->tick("xrt_err_radius",1);
  $mech->tick("uvot_ra",1);
  $mech->tick("uvot_dec",1);
  $mech->tick("uvot_err_radius",1);

  use LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  my $response = $ua->request($form->click);
  my $html = $response->decoded_content();
  parse_table($html)
}

use Array::Compare;
use Scalar::Util;# qw(looks_like_number);
use HTML::TableExtract;
sub parse_table(){
  my $html = $_[0];

  my $te = HTML::TableExtract->new( attribs=>{ class=>'grbtable' } );
  $te->parse($html);
  assert scalar $te->tables == 1;

  foreach my $ts ($te->tables)
  {
    my @header = ();
    my @table = ();
    foreach my $row ($ts->rows)
    {
      my @linha = ();
      foreach my $field (@$row)
      {
        my $first = (split("\n",$field))[0];
        if (Scalar::Util::looks_like_number($first)) {
          $field = $first;
        } else {
          $field =~ s/\r|\n/|/g;
        }
        # $field =~ s/([^\000-\200])/sprintf '&#x%X;', ord $1/ge;
        # $field =~ s/([^\000-\200])/'&#'.ord($1).';'/ge;
        $field =~ s/[^\000-\200]//g;
        $field =~ s/\;/|/g;
        push(@linha,$field);
      }
      if (!@header) {
        @header = @linha;
      } elsif ($linha[1] eq $header[1]) {
        my $comp = Array::Compare->new(WhiteSpace => 0);
        if ( $comp->compare(\@linha,\@header) )
        { next; }
      }
      # print "@linha\n";
      push( @table, join (";",@linha) );
    }
    foreach (@table)
    { print "$_\n"; }
  }
}

get_all_grbs();
