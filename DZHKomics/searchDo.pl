#!/usr/bin/perl

########################################################################
# Tim M Strom   July 2019
########################################################################


use lib '.';
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Dzhk;

my $cgiquery    = new CGI;
my $ref         = $cgiquery->Vars;
my $dzhk	= new Dzhk;

########################################################################
# main
########################################################################

$dzhk->printHeader();


$dzhk->searchResults($ref);


$dzhk->printFooter();
