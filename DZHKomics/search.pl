#!/usr/bin/perl

########################################################################
# Tim M Strom   July 2019
########################################################################

use lib '.';
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Dzhk;


my $dzhk        = new Dzhk;
my $cgiquery    = new CGI;


$dzhk->printHeader();


$dzhk->initSearch();


$dzhk->printFooter();
