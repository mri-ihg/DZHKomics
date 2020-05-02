#!/usr/bin/perl

########################################################################
# Tim M Strom   July 2019
########################################################################

use lib '.';
use strict;
use Dzhk;


my $dzhk        = new Dzhk;


$dzhk->printHeader();

$dzhk->initSearch();

$dzhk->printFooter();
