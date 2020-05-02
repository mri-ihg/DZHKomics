#!/usr/bin/perl

########################################################################
# Tim M Strom   July 2019
########################################################################


use lib '.';
use strict;
use Dzhk;

my $cgi         = new CGI;
my $ref         = $cgi->Vars;
my $dzhk	= new Dzhk;

########################################################################
# main
########################################################################

$dzhk->printHeader();

$ref = $dzhk->htmlencodehash($ref);

$dzhk->details($ref);

$dzhk->printFooter();
