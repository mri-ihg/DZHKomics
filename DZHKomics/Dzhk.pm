########################################################################
# Tim M Strom   July 2019
########################################################################

use strict;
package Dzhk;
use warnings;
use CGI;
use DBI;
use HTML::Entities;

my $ihg4 = 1;
my $text = "";

my $refgenome = "hg19";
my $altgenome = "hg38";

my $searchLimit = 10000;

#LiftOver:
my $liftOver = "/usr/local/packages/seq/liftOver";
my %liftOverFile;
$liftOverFile{"hg19"}{"hg38"}="/usr/local/packages/seq/liftOverFiles/hg19ToHg38.over.chain.gz";
$liftOverFile{"hg38"}{"hg19"}="/usr/local/packages/seq/liftOverFiles/hg38ToHg19.over.chain.gz";

if ($ihg4) {
	$text = "/srv/tools/text.txt"; #login
}
else {
	$text = "/srv/tools/textreadonly.txt"; #login
}

sub new {
	my $class = shift;
	my $self = {};
	bless $self,$class;
	return $self;
}

my $cgi = new CGI;
########################################################################
# dbh
########################################################################
sub dbh {
my $item   = "";
my $value  = "";
my %logins = ();
open(IN, "$text");
while (<IN>) {
	chomp;
	($item,$value)=split(/\:/);
	$logins{$item}=$value;
}
close IN;
my $dbh = DBI->connect("DBI:mysql:dzhkomics", "$logins{dblogin}", "$logins{dbpasswd}") || die print "$DBI::errstr";
return($dbh);
}

########################################################################
# init
########################################################################
# gets reference genome from querystring OR 
# sets reference genome to hg19 by default
sub init {
	my $self = shift;
	my $ref = shift;
	
	
	if (defined($ref->{'refgenome'}))
	{
		my $tmpRefGenome = $ref->{'refgenome'};
		
		if ( $tmpRefGenome eq "hg38" )
		{
			$refgenome = "hg38";
			$altgenome = "hg19";
			$searchLimit = 1000;
			
		}
		else
		{
			$refgenome = "hg19";
			$altgenome = "hg38";
			$searchLimit=10000;
		}
	}
	

}


########################################################################
# init for search
########################################################################
sub initSearch {
my $self         = shift;

print qq(
<style>
div.search {
  max-width:650px;
  margin: auto;
  padding: 20px;
  text-align:center;
  input:size:650px;
  // border: 3px solid #73AD21;
}
</style>
);

print qq(<div class="search">);
print qq(<br><br><br><br><br><div style='font-size:48px;color:#AF0233'><strong>DZHK</strong><font color="#000000">omics<sup><span style='font-size:15px'>v2</span></sup></font></div>);
print "DZHK - German Centre for Cardiovascular Research<br><br><br><br>";

#form

#Searchterm liftOver: 
my $searchTerm = "12:4477393-4488894";
if ( $refgenome eq "hg38")
{
	$searchTerm = liftOver($searchTerm, "hg19", "hg38");
	$searchTerm =~ s/chr//g ;
}


print qq(<form action="searchDo.pl" method="post">);
print qq(<input name="searchterm" placeholder="Search by gene or region" required="required" value="" maxlength="100" style="width:70%;">&nbsp;&nbsp;<input type="submit" value="Search" class="form-submit-button" ><br><br>);
print qq(Examples - Gene: <a href='searchDo.pl?searchterm=FGF23&refgenome=$refgenome'>FGF23</a>, 
Position: <a href='searchDo.pl?searchterm=$searchTerm&refgenome=$refgenome'>$searchTerm</a>
 - max $searchLimit variants<br><br>);
 
print qq(<input type="checkbox"  checked value="lof" name="lof">LoF &nbsp;&nbsp;&nbsp;);
print qq(<input type="checkbox"  checked value="missense" name="missense">Missense &nbsp;&nbsp;&nbsp;);
print qq(<input type="checkbox"  checked value="synonymous" name="synonymous">Synonymous &nbsp;&nbsp;&nbsp;);
print qq(<input type="checkbox"  value="other" name="other">Other &nbsp;&nbsp;&nbsp;);
print qq(<input type="checkbox"  value="filtered" name="filtered">Filtered variants<br><br>);
 
print qq(</form>);
&main_text();

print qq(</div>);

#rs7955866
}
########################################################################
# main_text
########################################################################
sub main_text {
print qq(<div style="text-align:justify;">);
print qq(
<br><br><br><br>
The <a href="https://dzhk.de/en/ressourcen/omics">DZHKomics </a> 
data set is provided by the German Centre for Cardiovascular Research
(DZHK). It comprises SNVs and indels of approximately 1150 genomes from
unrelated individuals of 6 German population cohorts: 
<a href="https://www.unimedizin-mainz.de/pkmp/studien-mit-biodatenbank/gutenberg-gesundheitsstudie.html">GHS</a> 
(Gutenberg-Gesundheitsstudie), 
<a href="https://hchs.hamburg">HCHS</a> 
(Hamburg City Health Study), 
NOKO (Heidelberg Normal Kontrollen), 
<a href="https://www.ikmb.uni-kiel.de">IKMB</a>
(Institut f&uuml;r Klinische Molekularbiologie Kiel), 
<a href="https://www.helmholtz-munich.de/en/kora">KORA</a> 
(Kooperative Gesundheitsforschung in der Region Augsburg), 
<a href="https://www2.medizin.uni-greifswald.de/cm/fv/ship.html">SHIP</a>
(Study of Health in Pomerania).
The data set contains approximately 48 million variants.
<br><br>
All data are released for the benefit of the wider biomedical community 
without restriction on use.<br><br><br><br>
);
print qq(</div>);
}

########################################################################
# resultssearch
########################################################################
sub table_labels {
my $chrom  = shift;
my @labels = ();
if ($chrom eq "X") {
@labels	= (
	'n',
	'Position (VCF)',
	'rsID',
	'Symbol',
	'Canonical',
	'Consequence',
	'HGVSc',
	'HGVSp',
	'Flags',
	'Allele<br>Count',
	'Allele<br>Number',
	'Allele<br>Frequency',
	'Number of<br>Homozygotes',
	'Number of<br>Hemizygotes',
	);
}
else {
@labels	= (
	'n',
	'Position (VCF)',
	'rsID',
	'Symbol',
	'Canonical',
	'Consequence',
	'HGVSc',
	'HGVSp',
	'Flags',
	'Allele<br>Count',
	'Allele<br>Number',
	'Allele<br>Frequency',
	'Number of<br>Homozygotes',
	);
}
&tableheaderDefault("1200px");

print "<thead><tr>";
foreach (@labels) {
	print "<th align=\"center\">$_</th>";
}
print "</tr></thead><tbody>";
}

########################################################################
# resultssearch
########################################################################

sub searchResults {
my $self       = shift;
my $ref        = shift;
my $searchterm = $ref->{'searchterm'};
my $lof        = $ref->{'lof'};
my $missense   = $ref->{'missense'};
my $synonymous = $ref->{'synonymous'};
my $other      = $ref->{'other'};
my $filtered   = $ref->{'filtered'};
my $where      = "";

if ($lof eq "lof") {
	$where .= " AND (c.type='3' ";
}
if ($missense eq "missense") {
	if ($where eq "") {
		$where = " AND (c.type='2' "
	} else {
		$where .= " OR c.type='2' ";
	}
}
if ($synonymous eq "synonymous") {
	if ($where eq "") {
		$where = " AND (c.type='1' "
	} else {
		$where .= " OR c.type='1' ";
	}
}
if ($other eq "other") {
	if ($where eq "") {
		$where = " AND (c.type='0' "
	} else {
		$where .= " OR c.type='0' ";
	}
}
if ($where ne "") {
	$where .= ") "
}

if ($filtered eq "") {
	$where .= " AND v.filter='PASS' ";
}
#print "where $where<br>";

my @labels    = ();
my @values    = ();
my $out       = "";
my @row       = ();
my $query     = "";
my $dbh       = &dbh;
my $item      = "";
my $i         = 0;
my $n         = 1;
my $maxlength = 30;
my $chrom     = "";
my $start     = "";
my $end       = "";
my $idvariant = "";



print qq(<form action="searchDo.pl" method="post">&nbsp;&nbsp;);
print qq(<input name="searchterm" placeholder="Search by gene or region" required="required" value="$searchterm" maxlength="100" style="width:200px;">&nbsp;);
print qq(<input type="checkbox"  checked value="lof" name="lof">LoF &nbsp;);
print qq(<input type="checkbox"  checked value="missense" name="missense">Missense &nbsp;);
print qq(<input type="checkbox"  checked value="synonymous" name="synonymous">Synonymous &nbsp;);
print qq(<input type="checkbox"  value="other" name="other">Other &nbsp;);
print qq(<input type="checkbox"  value="filtered" name="filtered">Filtered variants &nbsp; <input type="submit" value="Search" class="form-submit-button" ></form>);



if ($searchterm eq "") {
	print "Search term empty.";
	exit;
}

my $searchtermtype = "";

print qq(<div style="padding:10px;padding-bottom:50px">);
print "<br><span class=\"big\">Search term: $searchterm</span><br>" ;

if ($searchterm =~ /^.+:.+$/) { #Position
	$searchterm =~ s/\,//g;
	$searchtermtype="Position"; 
	($chrom,$start) = split(/\:/,$searchterm);
	$chrom =~ s/chr//;
	if ($start =~ /^.+-.+$/) { #End position
		($start,$end) = split(/-/,$start);
	}
	else {
		$end=$start;
	}

	# LiftOver hg38 to hg19 for searching if search is Position
	# separately query START and END to avoid failures. 
	
	if ( $refgenome eq "hg38" )
	{
		my $dummy; my $newstart; my $newend;
		($dummy, $newstart, $dummy) = split("\t", liftOver($chrom.":".$start."-".$start, "hg38", "hg19", "bed"));
		($dummy, $newend, $dummy)   = split("\t", liftOver($chrom.":".$end."-".$end,     "hg38", "hg19", "bed"));
	
		$start=$newstart;
		$end=$newend;
	}	
	
	
$query = qq#
SELECT 
CONCAT_WS( '-',v.chrom,v.pos,v.ref,v.alt),
t.rsid,
t.symbol,
t.canonical,
REGEXP_REPLACE(t.consequence,'_variant|_gene|_prime',''),
REGEXP_SUBSTR(t.hgvsc, 'c[.].+'),
REGEXP_REPLACE(REGEXP_SUBSTR(t.hgvsp, 'p[.].+'),'%3D','='),
CONCAT_WS(' ',REGEXP_REPLACE(v.filter,'PASS',''),v.lcr,v.segdup),
v.AC,v.AN,v.AF,v.nhomalt,v.nhemialt,v.chrom,v.idvariant,
v.chrom, v.pos, v.ref, v.alt
FROM variants v
INNER JOIN transcripts t ON v.idvariant=t.idvariant
LEFT JOIN consequences c ON t.consequence=c.consequence
WHERE v.chrom = ?
AND v.pos >= ?
AND v.pos <= ?
AND viewit = 1
$where
ORDER BY v.pos
LIMIT $searchLimit
#;
push(@values,$chrom);
push(@values,$start);
push(@values,$end);
}
elsif ($searchterm =~ /^rs.+$/) { # rsSNP
$searchtermtype="rsID";
$query = qq#
SELECT 
CONCAT_WS( '-',v.chrom,v.pos,v.ref,v.alt),
t.rsid,
t.symbol,
t.canonical,
REGEXP_REPLACE(t.consequence,'_variant|_gene|_prime',''),
REGEXP_SUBSTR(t.hgvsc, 'c[.].+'),
REGEXP_REPLACE(REGEXP_SUBSTR(t.hgvsp, 'p[.].+'),'%3D','='),
CONCAT_WS(' ',REGEXP_REPLACE(v.filter,'PASS',''),v.lcr,v.segdup),
v.AC,v.AN,v.AF,v.nhomalt,v.nhemialt,v.chrom,v.idvariant,
v.chrom, v.pos, v.ref, v.alt
FROM variants v
INNER JOIN transcripts t ON v.idvariant=t.idvariant
LEFT JOIN consequences c ON t.consequence=c.consequence
WHERE t.rsid = ?
AND viewit = 1
$where
ORDER BY v.pos
LIMIT $searchLimit
#;
#$searchterm= "%" . $searchterm . "&";
push(@values,$searchterm);
}
else { # Symbol
$searchtermtype="Symbol";
$query = qq#
SELECT 
CONCAT_WS( '-',v.chrom,v.pos,v.ref,v.alt),
t.rsid,
t.symbol,
t.canonical,
REGEXP_REPLACE(t.consequence,'_variant|_gene|_prime',''),
REGEXP_SUBSTR(t.hgvsc, 'c[.].+'),
REGEXP_REPLACE(REGEXP_SUBSTR(t.hgvsp, 'p[.].+'),'%3D','='),
CONCAT_WS(' ',REGEXP_REPLACE(v.filter,'PASS',''),v.lcr,v.segdup),
v.AC,v.AN,v.AF,v.nhomalt,v.nhemialt,v.chrom,v.idvariant,
v.chrom, v.pos, v.ref, v.alt
FROM variants v
INNER JOIN transcripts t ON v.idvariant=t.idvariant
LEFT JOIN consequences c ON t.consequence=c.consequence
WHERE symbol = ?
AND viewit = 1
$where
ORDER BY v.pos
LIMIT $searchLimit
#;
push(@values,$searchterm);
}

$out = $dbh->prepare($query) || die print "$DBI::errstr";
$out->execute(@values) || die print "$DBI::errstr";

print "<br><br><span>$searchtermtype not found.</span>" if($out->rows == 0);

while (@row = $out->fetchrow_array) {
	print "<tr>";
	
	#liftOver:
	my $LOChrom; my $LOStart; my $LORef; my $LOAlt; 
		$LOAlt=pop(@row);
		$LORef=pop(@row);
		$LOStart=pop(@row);
		$LOChrom=pop(@row);
		
	if ( $refgenome eq "hg38" )
	{
		my $dummy; my $newstart; 
		($dummy, $newstart, $dummy) = split("\t", liftOver($LOChrom.":".$LOStart."-".$LOStart, "hg19", "hg38", "bed"));
		#print $LOChrom.":".$LOStart."-".$LOStart."-".$LORef."-".$LOAlt;
		$row[0] = $LOChrom."-".$newstart."-".$LORef."-".$LOAlt;
	}
	
	$i=0;
	$idvariant = pop(@row);
	$chrom  = pop(@row);
	if ($chrom ne "X") {
		pop(@row); # remove hemizygotes
	}
	if ($n == 1) {
		&table_labels($chrom);
	}
	foreach $item (@row) {
		if ($i == 0) { #Postion
			print "<td align=\"center\">$n</td>";
			if (length($item) > $maxlength) {
				$item = substr($item,0,$maxlength) . "....";
			}
			$item = "<a href='details.pl?idvariant=$idvariant&refgenome=$refgenome'>$item</a>";
		}
		if ($i == 5) { #hgvsc
			if (length($item) > $maxlength) {
				$item = substr($item,0,$maxlength) . "....";
			}
		}
		print "<td>$item</td>";
		$i++;	
	}
	print "</tr>\n";
	$n++;
}
print "</tbody></table>";
print "</div>";
print "</div>";
}
########################################################################
# details
########################################################################
sub details {
my $self       = shift;
my $ref       = shift;
my $idvariant = $ref->{'idvariant'};


print qq(<form action="searchDo.pl" method="post">&nbsp;&nbsp;);
print qq(<input name="searchterm" placeholder="Search by gene or region" required="required" value="" maxlength="100" style="width:200px;">&nbsp;);
print qq(<input type="checkbox"  checked value="lof" name="lof">LoF &nbsp;);
print qq(<input type="checkbox"  checked value="missense" name="missense">Missense &nbsp;);
print qq(<input type="checkbox"  checked value="synonymous" name="synonymous">Synonymous &nbsp;);
print qq(<input type="checkbox"  value="other" name="other">Other &nbsp;);
print qq(<input type="checkbox"  value="filtered" name="filtered">Filtered variants &nbsp; <input type="submit" value="Search" class="form-submit-button" ></form>);

print qq(<div style="padding:10px;padding-bottom:50px">);


my @labels    = ();
my $out       = "";
my @row       = ();
my $query     = "";
my $dbh       = &dbh;
my $item      = "";
my $i         = 0;
my $n         = 1;
my $bamhet    = "";
my $bamhom    = "";
my $clinvarlink   = qq{"<a href='https://www.ncbi.nlm.nih.gov/clinvar/?term=",cv.rcv,"[alleleid]'>",cv.path,"</a>"};


$query = qq#
SELECT
allele_type,
CONCAT_WS( '-',v.chrom,v.pos,v.ref,v.alt),
filter,
REGEXP_REPLACE(deepvariant,'DeepVariant','PASS'),
CONCAT_WS(' ',v.lcr,v.segdup),
v.AC,v.AN,v.AF,v.nhomalt,v.nhemialt,
v.chrom,v.pos,v.ref,v.bamhet,v.bamhom,
group_concat(DISTINCT $clinvarlink separator '<br>'),
t.rsid,
v.alt
FROM variants v
INNER JOIN transcripts t ON v.idvariant=t.idvariant
LEFT JOIN consequences c ON t.consequence=c.consequence
LEFT JOIN clinvar     cv ON (v.chrom=cv.chrom and v.pos=cv.start and v.ref=cv.ref and v.alt=cv.alt)
WHERE t.idvariant = ?
ORDER BY c.score DESC
LIMIT 1
#;

$out = $dbh->prepare($query) || die print "$DBI::errstr";
$out->execute($idvariant) || die print "$DBI::errstr";

@row = $out->fetchrow_array;

my $chrom  = $row[10];
my $start  = $row[11];

# LiftOver:
if ($refgenome eq "hg38")
{
	my $dummy;
	($dummy, $start, $dummy) = split("\t", liftOver($chrom.":".$start."-".$start , "hg19", "hg38", "bed"));
		

	#Reassign row0
	$row[1]= $row[10]."-".$start."-".$row[12]."-".$row[17];
	#print "AA ".$row[0]."AAA";
	
}

my $end    = length($row[12]);
$end = $start+$end;
my $hstart = $start-100;
my $hend   = $end+100;
my $gstart = $start-20;
my $gend   = $end+20;
$bamhet    = $row[13];
$bamhom    = $row[14];
my $clinvar= $row[15];
my $rsid=$row[16];

$row[0] = "SNV" if $row[0] eq "snv";

print "<br><span class=\"big\">$row[0]: $row[1]</span><br><br>";
print qq(
<table class="vep_table">
);
if ( defined($rsid) && ($rsid ne "") )
{
print qq(
<tr><td style="text-align:left">rsID</td><td style="text-align:left">$row[16]</td></tr>
);
}
print qq(
<tr><td style="text-align:left">Random Forest</td><td style="text-align:left">$row[2]</td></tr>
<tr><td style="text-align:left">DeepVariant</td><td style="text-align:left">$row[3]</td></tr>
<tr><td style="text-align:left">Flags</td><td style="text-align:left">$row[4]</td></tr>
<tr><td style="text-align:left">Allele Count</td><td style="text-align:left">$row[5]</td></tr>
<tr><td style="text-align:left">Allele Number</td><td style="text-align:left">$row[6]</td></tr>
<tr><td style="text-align:left">Allele Frequency</td><td style="text-align:left">$row[7]</td></tr>
<tr><td style="text-align:left">Number of Homozygotes</td><td style="text-align:left">$row[8]</td></tr>
);

if ($chrom eq "X") {
print qq(
<tr><td style="text-align:left">Number of Hemizygotes</td><td style="text-align:left">$row[9]</td></tr>
);
}

print qq(
</table>
<br>
);

if ($bamhet eq "") {
	$bamhet = "00";
}
if ($bamhom eq "") {
	$bamhom = "00";
}
#print "start $start<br>";
#print "end   $end<br>";
#print "bamhet   $bamhet<br>";
#print "bamhom   $bamhom<br>";
############### Links ###############################

### $refGenome!

if ( $refgenome eq "hg19" )
{
	print qq(  
	<br><span class="big">Links: 
	<a href="https://genome.ucsc.edu/cgi-bin/hgTracks?db=hg19&position=chr$chrom:$hstart-$hend&highlight=hg19.chr$chrom:$start-$end">UCSC</a> |
	<a href="https://grch37.ensembl.org/Homo_sapiens/Location/View?db=core&r=$chrom:$hstart-$hend">Ensembl</a> |
	<a href="https://gnomad.broadinstitute.org/region/$chrom:$gstart-$gend">gnomAD</a>
	);
}else{
	print qq(  
	<br><span class="big">Links: 
	<a href="https://genome.ucsc.edu/cgi-bin/hgTracks?db=hg38&position=chr$chrom:$hstart-$hend&highlight=hg38.chr$chrom:$start-$end">UCSC</a> |
	<a href="https://www.ensembl.org/Homo_sapiens/Location/View?db=core&r=$chrom:$hstart-$hend">Ensembl</a> |
	<a href="https://gnomad.broadinstitute.org/region/$chrom:$gstart-$gend?dataset=gnomad_r3">gnomAD</a>
	);
}



if ($clinvar ne "") {
print qq(
| Clinvar: $clinvar
<br>
);
}

print qq( </span> );


############### transcripts ###############################
$query = qq#
SELECT
symbol,
t.feature,
t.canonical,
REGEXP_REPLACE(t.consequence,'_variant|_gene|_prime',''),
REGEXP_SUBSTR(t.hgvsc, 'c[.].+'),
REGEXP_REPLACE(REGEXP_SUBSTR(t.hgvsp, 'p[.].+'),'%3D','=')
FROM variants v
INNER JOIN transcripts t ON v.idvariant=t.idvariant
LEFT JOIN consequences c ON t.consequence=c.consequence
WHERE t.idvariant = ?
ORDER BY c.score DESC
LIMIT $searchLimit
#;

$out = $dbh->prepare($query) || die print "$DBI::errstr";
$out->execute($idvariant) || die print "$DBI::errstr";

@labels	= (
	'n',
	'Symbol',
	'Ensembl Transcript',
	'Canonical',
	'Consequence',
	'HGVSc',
	'HGVSp',
);

print "<br><br><span class=\"big\">Annotations</span>" ;

&tableheaderDefaultnew("table02","800px");


print "<thead><tr>";
foreach (@labels) {
	print "<th align=\"center\">$_</th>";
}

print "</tr></thead><tbody>";
while (@row = $out->fetchrow_array) {
	print "<tr>";
	$i=0;
	foreach $item (@row) {
		if ($i == 0) { #Postion
			print "<td align=\"center\"></td>";
	
		}
		print "<td>$item</td>";
		$i++;	
	}
	print "</tr>\n";
	$n++;
}
print "</tbody></table></div>";
&tablescriptnew("table02");

############### IGV ###############################

return if ( $refgenome eq "hg38" );

print "<br><br><span class=\"big\">Read Data</span><br><br>";

print qq(
<div id="igv-div" style="padding-top: 10px;padding-bottom: 10px; border:1px solid lightgray"></div>
);

print qq(
<script src="/igv/igv.min.js"></script>
<script type="text/javascript">

      var igvDiv = document.getElementById("igv-div");
      var options =
        {
            reference: {
            	id: "hg19",
	    	fastaURL: "/hg19p/noPAR.hg19_decoy.fa",
	    	indexURL: "/hg19p/noPAR.hg19_decoy.fa.fai",
            },
	    // genome: "hg19",
            locus: "$chrom:$hstart-$hend",
            tracks: [
                {
                    "displayMode":"SQUISHED",
                    "indexURL":"/hg19p/gencode.v19.sorted.bed.idx",
                    "name":"gencode v19",
                    "removable":!1,
                    "url":"/hg19p/gencode.v19.sorted.bed"
                },
                {
		    "colorBy": "strand",
		    "showSoftClips": true,
                    "name": "Heterozygous",
                    "url": "/bam/BAMS/het_$bamhet.sorted.bam",
                    "indexURL": "/bam/BAMS/het_$bamhet.sorted.bam.bai",
                    "format": "bam"
                },
                {
		    "colorBy": "strand",
		    "showSoftClips": true,
                    "name": "Homozygous",
                    "url": "/bam/BAMS/hom_$bamhom.sorted.bam",
                    "indexURL": "/bam/BAMS/hom_$bamhom.sorted.bam.bai",
                    "format": "bam"
                }
            ]
        };

        igv.createBrowser(igvDiv, options)
                .then(function (browser) {
                    console.log("Created IGV browser");
                })


</script>
);

print "</div>";

}
########################################################################
# downloads
########################################################################
sub downloads {
print qq(<div style="padding:10px;padding-bottom:50px">);

print qq#
<div class="faq">

<br><span class="big">Downloads</span><br><br>

Data are available for download in VCF and Hail Table (.ht) formats.<br>
Files can also be downloaded on the command line with 'wget'.<br><br>

<ul>
<li><a href="/DZHKomics/DZHKomics_2019_04_08_frequency_only.vds.tar.gz">Hail Table hg19</a></li>
<li><a href="/DZHKomics/DZHKomics_2019_04_08_frequency_only.vcf.bgz">VCF Table hg19</a></li>
</ul>

</div>
#;

print "</div>";
}
########################################################################
# about
########################################################################
sub about {
print qq(<div style="padding:10px;padding-bottom:50px">);

print qq(
<div class="faq">

<br><span class="big">About DZHKomics</span><br><br>
DZHKomics is a common project of 6 epidemiological cohort studies, a sequencing center and analysis teams.
It generated a healthy control resource of approximately 1,200 individuals.
Samples were provided by the following cohort studies:
<ul>
<li><a href="https://www.unimedizin-mainz.de/pkmp/studien-mit-biodatenbank/gutenberg-gesundheitsstudie.html">GHS</a> (Gutenberg-Gesundheitsstudie)</li>
<li><a href="https://hchs.hamburg">HCHS</a> (Hamburg City Health Study)</li>
<li>NOKO (Heidelberg Normal Kontrollen)</li>
<li><a href="https://www.ikmb.uni-kiel.de">IKMB</a> (Institut f&uuml;r Klinische Molekularbiologie Kiel)</li>
<li><a href="https://www.helmholtz-munich.de/en/kora">KORA</a> (Kooperative Gesundheitsforschung in der Region Augsburg)</li>
<li><a href="https://www2.medizin.uni-greifswald.de/cm/fv/ship.html">SHIP</a> (Study of Health in Pomerania)</li>
</ul>
<br>

Approximately 200 samples were selected from each of the six cohorts according with the following criteria:
<ul>
<li>Equal distribution of females and males</li>
<li>Age between 45 and 64 years (in 10-years increments)</li>
<li>Exclusion criteria was heart attack and stroke</li>
<li>Enrichment for Western European ancestry if possible</li>
</ul>
<br>

DNA samples were pre-processed at the 
Department of Cardiology, Angiology, Pneumology (University Hospital Heidelberg)
and sequenced on HiSeq X machines at the German Cancer Research Center
<a href="https://www.dkfz.de/en/forschung/zentrale_einrichtungen/CF_genom_proteom.html">(DKFZ)</a>. 
Data were analyzed at the 
<a href="https://ihg.helmholtz-munich.de/ihg/index_engl.html">Institute of Human Genetics</a> (Helmholtz Zentrum M&uuml;nchen), the
<a href="https://cardiogenetics-luebeck.de">Institute for Cardiogenetics</a> (Universit&auml;t zu L&uuml;beck), and the
<a href="https://www.imbs.uni-luebeck.de/en/institute.html">Institute of Medical Biometry and Statistics</a> (Universit&auml;t zu L&uuml;beck).

<br><br><br>

<div class="flex-about">
<div>
<span class="bold">Project coordination</span><br>
Heribert Schunkert<br>
Jeanette Erdmann<br>
Tanja Zeller<br><br>

<span class="bold">Science Administration</span><br>
Alexandra Klatt<br><br>

<span class="bold">Production Team</span><br>
Benjamin Meder<br>
Jan Haas<br>
Stefan Wiemann<br>
Stephan Wolf<br>
Angela Schulz<br>
Melanie Waldenberger<br>
Eva Reischl<br>
Katrin Saar<br>
Norbert H&uuml;bner<br><br>
</div>

<div>
<span class="bold">Epidemiological Studies</span><br>
Andre Franke<br>
Annette Peters<br>
Christian Gieger<br>
Georg Homuth<br>
Harald Grallert<br>
Philipp Wild<br>
Stefan Blankenberg<br>
Renate Schnabel<br>
Tanja Zeller<br>
Uwe V&ouml;lker<br>
Norbert Frey<br>
Benjamin Meder<br>
Jan Haas<br>
Stephan B. Felix<br>
Marcus D&ouml;rr<br><br>
</div>

<div>
<span class="bold">Analysis Team</span><br>
Tim M Strom<br>
Riccardo Berutti<br>
Thomas Schwarzmayr<br>
Jeanette Erdmann<br>
Inka R K&ouml;nig<br>
Damian Gola<br>
Mark P H&ouml;ppner<br>
Matthias Munz<br>
Thomas Meitinger<br>
Christian M&uuml;ller<br><br>

<span class="bold">Funding</span><br>
German Federal Ministry of Education and Research (BMBF) and the German states in which member institutions are located.<br>
</div>
</div>


</div>
);

print "</div>";
}
########################################################################
# faq
########################################################################
sub faq {
print qq(<div style="padding:10px;padding-bottom:50px">);

print qq(
<div class="faq">
<span class="big">General</span><br><br>
<span class="bold">How should the data be cited?</span><br>
The data is not yet published. Please use the URL of this site to cite the data.<br><br>

<span class="bold">Is data usage restricted?</span><br>
There are no restrictions on the publication of results derived from these data. 
The data are available under the <a href="https://opendatacommons.org/licenses/odbl/1.0/">ODC Open Database License (ODbL)</a>: 
you are free to share and modify the data as long as you attribute any public use, 
or works produced from the database; keep the resulting data-sets open; and offer your 
shared or adapted version of the dataset under the same ODbL license.<br><br>

<span class="bold">Can I get access to individual-level genotype data?</span><br>
Access to the individual-level data of the DZHKomics ressource can be applied for at 
<a href="https://dzhk.de/en/ressourcen/omics">omics.resource(at)dzhk.de</a>.<br><br><br>

<span class="big">Acknowledgments</span><br><br>
Data analysis relied heavily on 
<a href="https://software.broadinstitute.org/gatk">GATK</a>, 
<a href="https://hail.is/">Hail toolkit</a>, 
<a href="https://software.broadinstitute.org/software/igv/download">IGV</a>, 
<a href="https://github.com/google/deepvariant">DeepVariant</a>, 
<a href="https://github.com/dnanexus-rnd/GLnexus">GLnexus</a> 
and the scripts provided by 
<a href="https://github.com/macarthur-lab">gnomAD</a>. 
This analysis would not have been possible without these tools. 
We would like to thank all the teams for making their software publically available.  
<br><br><br>

<span class="big">Technical details</span><br><br>

<span class="bold">Which genome build is the data based on?</span><br>
All data are based on GRCh37/hg19.<br>
The hg38 version is a liftover of the hg19 dataset. Original data aligned on hg38 are also available on request by applying for at 
<a href="https://dzhk.de/en/ressourcen/omics">omics.resource(at)dzhk.de</a>.<br>
<br><br>

<span class="bold">What version of Gencode was used to annotate variants?</span><br>
Version 19 (annotated with 
<a href="http://dec2017.archive.ensembl.org/info/docs/tools/vep/script/vep_cache.html#cache_content">VEP</a>
 version 91).<br><br>

<span class="bold">How is variant calling done?</span><br>
Variant calling was performed with GATK haplotype caller (version 4.1.0.0).
For variant classification we used random forest as provided by the gnomAD and Hail teams 
(https://github.com/macarthur-lab/gnomad_qc). We used 
hail version 'hail-20190730-1209-devel-b0342b11e1af' and gnomad_qc from 2018-11-21. 
We modified the gnomad_qc scripts to run locally.<br>
In addition variants were called with DeepVariant (version 0.7.2).<br><br>

<span class="bold">Which transcript is used for the functional annotation on the region page?</span><br>
The region page summarizes the most severe functional consequence of a canonical transcript if present.
The annotation for all transcripts are listed on the variant detail page.<br><br>

<span class="bold">What is the meaning of the flags?</span><br>
<ul>
<li>AC0: The allele count is zero after filtering out low-confidence genotypes (GQ < 20; DP < 10; and allele bias < 0.2 for het calls; for males on the
non-pseudoautosomal regions of tne X chromosome: DP < 5).</li>
<li>InbreedingCoeff: The InbreedingCoeff is < -0.3.</li>
<li>RF: Failed random forest filtering thresholds.</li>
<li>lcr: Found in a low complexity region: these regions were identified with the symmetric DUST algorithm at a score threshold of 30 and provided by
<a href="https://github.com/lh3/varcmp/blob/master/scripts/LCR-hs37d5.bed.gz"> Heng Li</a>.</li>
<li>segdup: Found in segmental duplication region.</li>
</ul><br>

<span class="bold">How was coverage calculated?</span><br>
Coverage was calculated with samtools mpileup command, using all mapped reads on chromosomes 1-22. 
Sites with no coverage were included in the 
calculations. Samples with less than 30x average coverage were excluded from the final panel.<br><br>

<span class="bold">Which populations are represented in the data?</span><br>
Data are generated from individuals of 6 German population cohorts.
<a href="https://www.unimedizin-mainz.de/pkmp/studien-mit-biodatenbank/gutenberg-gesundheitsstudie.html">GHS</a> 
(Gutenberg-Gesundheitsstudie), 
<a href="https://hchs.hamburg">HCHS</a> 
(Hamburg City Health Study), 
NOKO (Heidelberg Normal Kontrollen), 
<a href="https://www.ikmb.uni-kiel.de">IKMB</a>
(Institut f&uuml;r Klinische Molekularbiologie Kiel), 
<a href="https://www.helmholtz-munich.de/kora">KORA</a> 
(Kooperative Gesundheitsforschung in der Region Augsburg), 
<a href="https://www2.medizin.uni-greifswald.de/cm/fv/ship.html">SHIP</a>
(Study of Health in Pomerania).<br><br>

<table class="vep_table">
<thead>
<tr>
<th></th>
<th>GHS</th>
<th>HCHS</th>
<th>NOKO</th>
<th>IKMB</th>
<th>KORA</th>
<th>SHIP</th>
<th>Total</th>
</tr>
</thead>
<tbody>
<tr>
<td>Female</td>
<td>87</td>
<td>100</td>
<td>82</td>
<td>90</td>
<td>97</td>
<td>102</td>
<td>558</td>
</tr>
<tr>
<td>Male</td>
<td>92</td>
<td>91</td>
<td>101</td>
<td>118</td>
<td>98</td>
<td>91</td>
<td>591</td>
</tr>
<tr>
<td>Total</td>
<td>179</td>
<td>191</td>
<td>183</td>
<td>208</td>
<td>195</td>
<td>193</td>
<td>1149</td>
</tr>
</tbody>
</table>

);

print "</div>";
print "</div>";
}
########################################################################
# privacy
########################################################################
sub privacy {
print qq(<div style="padding:10px;padding-bottom:50px">);

print qq#
<div class="faq">

<br><span class="big bold">Privacy and Data Protection</span><br><br>
<span class="big">I. Name and address of the controller</span><br><br>
In the sense of the General Data Protection Regulation (GDPR) and other national 
data protection laws in the member states as well as other provisions 
of data protection law, the controller is: <br><br>
Deutsches Zentrum f&uuml;r Herz-Kreislauf-Forschung e. V.<br>
Potsdamer Str. 58<br>
10785 Berlin<br>
Germany<br>
E-Mail: info(at)dzhk.de<br>
Tel.: 030 3465 52901<br><br>

<span class="big">II. Name and address of the data protection officer</span><br><br>
Rechtsanwalt Marcel Wetzel<br>
Theodor-Heuss-Platz 4<br>
14052 Berlin<br>
E-Mail: mail(at)wetzel.berlin<br>
Tel.: 030 895 66 160<br>
Fax.: 030 895 66 161 <br><br>

<span class="big">III. Log files</span><br><br>

<span class="bold">1. Description and scope of the data processing</span><br>
Each time our website is accessed, our system automatically records data and information regarding the 
computer system of the accessing computer.<br>
The following data are collected in this case:<br>
<ul>
<li>The user's IP address</li>
<li>Date and time of day of the access</li>
<li>Websites from which the user's system reaches our website</li>
<li>Information on the browser type and the version in use</li>
<li>The user's operating system (if transmitted)</li>
</ul>
The data are likewise stored in our system's log files. 
These data are not stored together with other personal data of the user.<br><br>

<span class="bold">2. Legal basis for the data processing</span><br>
The legal basis for the temporary storage of the data and the log files is Article 6(1)(f) GDPR.<br><br>


<span class="bold">3. Purpose of the data processing</span><br>
The system will temporarily store the IP address and is necessary, in order to allow the website to be 
delivered to the computer of the user. This requires the user\u2019s IP address to be stored for the 
duration of the session.
The storage of log files takes place, in order to ensure the functional capability of the website. 
We additionally use the data to optimize the website and to ensure the safety and security of our 
information technology systems. Data is not evaluated for marketing purposes in this connection.
For these purposes, our legitimate interest in data processing is also in accordance with Article 6(1)(f) GDPR.<br><br>

<span class="bold">4. Storage period</span><br>
Log files are deleted automatically are stored at longest for 30 days.<br><br>

<span class="bold">5. Possibility of objection and disposal</span><br>
The recording of data for the provision of the website and storage of the data in log files is vital 
to the operation of the internet website. The user consequently has no possibility to object.<br><br>

<span class="big">IV. Use of Cookies</span><br><br>
We don't use neither session cookies nor cookies to track users. Reference genome preference is stored in the querystring and choice will be lost for every reload of the website.<br><br>

<span class="big">V. Newsletter</span><br><br>
We don't offer newsletters.<br><br>

<span class="big">VI. Web forms</span><br><br>
We don't offer Web forms to enter peronal data.<br><br>

<span class="big">VII. Right to lodge a complaint with a supervisory authority</span><br><br>
Without prejudice to any other administrative or judicial remedy, you have the right to lodge a 
complaint with a supervisory authority, in particular in the Member State of your residence, 
place of work or place of the alleged infringement if you consider that the processing of 
personal data relating to you violates the GDPR.<br>

The supervisory authority with which the complaint has been lodged will inform the 
complainant on the progress and the outcome of the complaint including the possibility 
of a judicial remedy pursuant to Article 78 GDPR.<br>

The competent supervisory authority for the Deutsches Zentrum f&uuml;r Herz-Kreislauf-Forschung e. V. 
is the Landesdatenschutzbeauftragte for the Land Berlin. You can find her/his address at the following URL:
<a href="https://www.bfdi.bund.de/DE/Infothek/Anschriften_Links/anschriften_links-node.html">https://www.bfdi.bund.de</a> 

</div>
#;

print "</div>";
}
########################################################################
# imprint
########################################################################
sub imprint {
print qq(<div style="padding:10px;padding-bottom:50px">);

print qq(
<div class="faq">

<br><span class="big">Imprint</span><br><br>

<span class="bold">Publisher</span><br>
German Centre for Cardiovascular Research<br>
Deutsches Zentrum f&uuml;r Herz-Kreislauf-Forschung e. V.<br>
Potsdamer Str. 58<br>
10785 Berlin<br>
Germany<br>
<br>
phone: +49 30 3465 529-01<br>
fax: +49 30 3465 529-99<br>

District court  Charlottenburg-Berlin<br>
Association register number  31188 B<br><br>

<span class="bold">Executive Board</span><br>
Prof. Dr. T. Eschenhagen (Vors.)<br>
Prof. Dr. G. Hasenfu&szlig;<br>
Prof. Dr. W. Rosenthal<br>
<br>
<span class="bold">Managing Director</span><br>
Joachim Krebser<br>
<br><br>

<span class="big">Disclaimer</span><br><br>
<span class="bold">1. Content</span><br>
The German Centre for Cardiovascular Research reserves the right not to be responsible for the topicality, correctness, 
completeness or quality of the information provided. Liability claims regarding damage caused by the use 
of any information provided, including any kind of information which is incomplete or incorrect will 
therefore be rejected. Parts of the pages or the complete publication including all offers and 
information might be extended, changed or partly or completely deleted by the 
German Centre for Cardiovascular Research without separate announcement.<br><br>

<span class="bold">2. Referrals and Links</span><br>
The German Centre for Cardiovascular Research is not responsible for any contents linked or referred to from 
the German Centre for Cardiovascular Research's pages - unless we have full knowledge 
of illegal contents and we are able to prevent the visitors of the German Centre for Cardiovascular Research site 
from viewing those pages. If any damage occurs by the use of information presented there, 
only the author of the respective page might be liable, not the one who has linked to these pages.<br><br>

</div>
);

print "</div>";
}
########################################################################
# tableheaderDefault
########################################################################
sub tableheaderDefault {
my $width   = shift;
my $numeric = shift;
my $string  = shift;
my $html    = shift;
my $mode    = shift;  # for burden test
my $buf     = "";

if (!defined($width)) {$width = "";}
$buf = "<br><br>";
if ($width eq "650px") {
	$width = "class='width650'";
}
elsif ($width eq "1000px") {
	$width = "class='width1000'";
}
elsif ($width eq "1200px") {
	$width = "class='width1200'";
}
elsif ($width eq "1500px") {
	$width = "class='width1500'";
}
elsif ($width eq "1750px") {
	$width = "class='width1750'";
}
elsif ($width eq "2000px") {
	$width = "class='width2000'";
}

$buf .= qq(
<div id="container" $width>
<table id="default" numeric="$numeric" string="$string" html="$html" cellspacing="0" class="display compact" width="100%"> 
);

if ($mode eq "") {
	print $buf;
}
else {
	return $buf;
}

}
########################################################################
# tableheaderDefaultnew
########################################################################
sub tableheaderDefaultnew {
my $tableid = shift;
my $width   = shift;
my $numeric = shift;
my $string  = shift;
my $html    = shift;
my $mode    = shift;  # for burden test
my $buf     = "";
if ($tableid eq "") {
	$tableid = "table01";
}

if (!defined($width)) {$width = "";}
$buf = "<br><br>";
if ($width eq "800px") {
	$width = "class='width800'";
}
elsif ($width eq "1000px") {
	$width = "class='width1000'";
}
elsif ($width eq "1500px") {
	$width = "class='width1500'";
}

$buf .= qq(
<div id="container" $width>
<table id="$tableid" numeric="$numeric" string="$string" html="$html" cellspacing="0" class="compact display" width="100%">
);

if ($mode eq "") {
	print $buf;
}
else {
	return $buf;
}

}

########################################################################
# tablescriptnew
########################################################################
sub tablescriptnew {
my $tableid = shift;

print qq(
<script type="text/javascript" charset="utf-8">
\$(document).ready( function () {
 var t = \$('#$tableid').DataTable({
	"dom":           'Bfrtip',
 	"paginate":      false,
  	"lengthChange":  true,
	"filter":        false,
 	"sort":          true,
	"info":          false,
	"autoWidth":     true,
	"orderClasses":  false,
	"displayLength": -1,
	"lengthMenu":   [[-1, 100, 50, 25], ["All", 100, 50, 25]],
	"select":        'multi',
 	"buttons":       [],
	"fixedHeader":   false,
	"columnDefs": [ {
		"targets": 0,
		"searchable": false,
		"orderable": false
	}],
        "order": [[ 1, 'asc' ]]
});

    t.on( 'order.dt search.dt', function () {
        t.column(0, {search:'applied', order:'applied'}).nodes().each( function (cell, i) {
            cell.innerHTML = i+1;
        } );
    } ).draw();

});
</script>
);

}
########################################################################
# htmlencode
########################################################################

sub htmlencode {
	my $self    = shift;
	my $string  = shift;
	HTML::Entities::encode($string);
	return($string);
}
########################################################################
# htmlencodehash
########################################################################

sub htmlencodehash {
	my $self     = shift;
	my $ref      = shift;
	my $key      = "";
	my $tt       = chr(0);
	my $tmp      = "";
	my @tmp      = ();
	my $checkbox = "";
	my $i        = 0;
	for $key (keys %$ref) {
		if ($ref->{$key} =~ /$tt/) {   # for checkbox_group
			$i        = 0;
			$checkbox = "";
			$tmp = $ref->{$key};
			@tmp = split(/$tt/,$tmp);
			foreach $tmp (@tmp) {
				HTML::Entities::encode($tmp);
				if ($i >= 1) {
					$checkbox = $checkbox . $tt;
				}
				$checkbox = $checkbox . $tmp;
				$i++;
			}
			$ref->{$key} = $checkbox;
		}
		else {
			HTML::Entities::encode($ref->{$key});
		}
	}
	return($ref);
}
########################################################################
# printHeader
########################################################################

sub printHeader {
my $self        = shift;
my $background  = shift;
if (!defined($background)) {$background = "";}

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print qq(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>DZHKomics</title>
) ;
# Tell Perl not to buffer our output
$| = 1;


#Genome change:
my $currpage = $ENV{SCRIPT_NAME};
my $ref         = $cgi->Vars;

$ref->{'refgenome'} = $altgenome;

my $iLoop=0;
my $queryString="";
for my $refkey ( keys %$ref )
{
	# Modify searchterm if POSITIONAL
	if ( $refkey eq "searchterm" )
	{
		if ( $ref->{$refkey} =~ /^(chr)?(20|21|22|[1-9]|1[0-9]|[XYM]):[0-9]+-[0-9]+$/ )
		{
			if ( ( $refgenome eq "hg19" || $refgenome eq "hg38" ) &&  ( $altgenome eq "hg19" || $altgenome eq "hg38" ) )
			{
				my $newpos = liftOver($ref->{$refkey}, $refgenome, $altgenome);
				$newpos =~ s/chr//g;
				$ref->{$refkey} = $newpos; 
			}
			else
			{
				exit -1;
			}
		}
	}

	$queryString .= "&" if ($iLoop > 0 );
	$queryString .= $self->htmlencode($refkey) . "=" . $self->htmlencode($ref->{$refkey});
	
	$iLoop++;
}

$queryString=$currpage."?".$queryString;


# Visualisation Switcher:
my $refGenomeSwitcher = "";

my $refGenomeSwitcherInUse=qq( <strong><span style="background-color:#606060;">$refgenome</span></strong> );
my $refGenomeSwitcherNotInUse=$altgenome;

if ($refgenome eq "hg19")
{
	$refGenomeSwitcher = $refGenomeSwitcherInUse."&nbsp;&rarr;&nbsp;".$refGenomeSwitcherNotInUse;
}
else
{	
	$refGenomeSwitcher = $refGenomeSwitcherNotInUse."&nbsp;&larr;&nbsp;".$refGenomeSwitcherInUse;
}



print qq(

<script type="text/javascript" src="https://ihg4.helmholtz-munich.de/DataTables/datatables.min.js"></script>
<link rel="stylesheet" type="text/css" href="https://ihg4.helmholtz-munich.de/DataTables/datatables.min.css">
<link rel="shortcut icon" href="/dzhk.ico">

<script type="text/javascript" src="https://ihg4.helmholtz-munich.de/medialize-jQuery-contextMenu-09dffab/src/jquery.contextMenu.js"></script>
<script type="text/javascript" src="https://ihg4.helmholtz-munich.de/medialize-jQuery-contextMenu-09dffab/src/jquery.ui.position.js"></script>
<link rel="stylesheet" type="text/css" href="http://ihg4.helmholtz-munich.de/medialize-jQuery-contextMenu-09dffab/src/jquery.contextMenu.css">

<meta name="viewport" content="width=device-width, height=device-height,  initial-scale=1, minimum-scale=1">

<script type="text/javascript" src="https://ihg4.helmholtz-munich.de/gif/EVAdb.js"></script>
<link rel="stylesheet" type="text/css" href="https://ihg4.helmholtz-munich.de/gif/DZHKomics.css">
 <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
 </head>
) ;



if ($background ne "white") {
	print qq(<body bgcolor=\"#ffffff\">\n);
	print qq(<div id="wrapper">);
	print qq(<div id="content">);
}
else {
	print qq(<body bgcolor=\"#CCCCCC\">\n);
	print qq(<div id="wrapper">);
	print qq(<div id="content">);
}

print qq(
<div class='topnav'>
<div class="flex">
	<img src="/gif/dzhk1.png" class="dzhkicon">
</div>
<a href="search.pl?refgenome=$refgenome">DZHKomics</a>


	<div class='topnav-right'>
	<div id="myLinks">
		<a href="downloads.pl?refgenome=$refgenome">Downloads</a>
		<a href="about.pl?refgenome=$refgenome">About</a>
		<a href="faq.pl?refgenome=$refgenome">FAQ</a>
		<a href="$queryString">$refGenomeSwitcher</a>
	</div>
	</div>
	<div class='mobileShow'>
		<a href="javascript:void(0);" class="icon" onclick="myFunction()">
		<i class="fa fa-bars"></i>
	</a>
	</div>
</div>
);

print qq#
<script>
function myFunction() {
  var x = document.getElementById("myLinks");
  if (x.style.display === "block") {
    x.style.display = "none";
  } else {
    x.style.display = "block";
  }
} 
</script>
#;


}


########################################################################
# printFooter
########################################################################

sub printFooter {
my $self        = shift;

print qq(
<br><br>
</div>
<div id="footer">
<br>
<div class="footertext">
<a href="https://dzhk.de/en/">DZHK</a> German Centre for Cardiovascular Research
<br>
<a href="imprint.pl?refgenome=$refgenome">Imprint</a> 
<a href="privacy.pl?refgenome=$refgenome">Privacy</a>
<br><br>
</div>
</div>
</div>
</body>
</html>
);

}

########################################################################


########################################################################
# liftOver
########################################################################
sub liftOver {

my $input  = shift;
my $LOFrom = shift;
my $LOTo   = shift;
my $outBed = shift;

my $LOFile=$liftOverFile{$LOFrom}{$LOTo};

if ( ! ( $input =~ /^(chr)?(20|21|22|[1-9]|1[0-9]|[XYM]):[0-9]+-[0-9]+$/ ) )
{
	return "chr1:1-1";
}

if ( ! ( $input =~ /^chr/ ) )
{
	$input = "chr".$input;
}

my $toBedFormat = $input;
	$toBedFormat =~ s/\:/\\t/g;
	$toBedFormat =~ s/\-/\\t/g;
	
	my ($LOchrom, $LOstart, $LOend) = split('\\\t', $toBedFormat);
	

	
	return $input if ($LOFrom eq $LOTo);
	

	#echo -e "chr1\t10199810\t10199811" | ./liftOver /dev/stdin hg19ToHg38.over.chain.gz /dev/stdout /dev/null 2>/dev/null ;dones
	my $out=`export PATH=/usr/local/packages/seq/:\$PATH; echo -e \"$toBedFormat\" | $liftOver /dev/stdin $LOFile /dev/stdout /dev/null 2>/dev/null`;
	
	if ( $outBed ne "bed" )
	{
		$out =~ s/\t/\:/;
		$out =~ s/\t/\-/;
	}
	
	return $out;
}



1;
__END__
