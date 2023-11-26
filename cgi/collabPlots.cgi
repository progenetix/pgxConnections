#!/usr/bin/perl -w

################################################################################
#                                                                              #
# Progenetix & arrayMap site scripts                                           #
#                                                                              #
# molecular cytogenetics, Comparative Genomic Hybridization, genomic arrays    #
# data analysis & visualization                                                #
#                                                                              #
# © 2000-2022 Michael Baudis: m@baud.is                                        #
#                                                                              #
################################################################################

=podmd
This plotter is based on a dirty "reduction" of the previous PG
package - many code remnants in the libraries ...
=cut

use strict;

use CGI::Carp qw(fatalsToBrowser);
use Cwd;
use Data::Dumper;

BEGIN { unshift @INC, '../lib' };

use readFiles;
use setVars;

use collabPlots;
use pgCircleModules;
use svgUtilities;

################################################################################
# parameter defaults & modifications ###########################################
################################################################################

=podmd

#### Examples (compbiozurich logo):

* compbiozurich logo
    - https://progenetix.org/cgi-bin/collabplots.cgi?nodes=https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/master/collab/people.tab&nodesort=random&connections=https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/master/collab/connections.tab&plot_bgcolor_hex=%23ffffff&fontcol=%23000000&radius=65&gapwidth=2&chrowidth=6&legendw=-1&fontpx=-1&imgtype=SVG&transparent=opaque&Submit=Submit&embed=1&imgh=200&imgw=200&conn_opacity=0.6&debug=
=cut

# print 'Content-type: text/plain'."\n\n";

my %args;
$args{pgV} = pgReadParam(%args);

my $nodesRef = 'https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/master/collab/people.tab';
my $connRef = 'https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/master/collab/connections.tab';

$args{pgV}->{plot_bgcolor_hex} //'#ffffff';
$args{pgV}->{fontcol} //='#000000';
$args{pgV}->{fontpx} //= 15;
$args{pgV}->{imgh} //= 620;
$args{pgV}->{legendw} //= 180;
$args{pgV}->{legendfpx}	//= 13;
$args{pgV}->{circradius} //= 125;
$args{pgV}->{imgtype} //= 'SVG';
$args{pgV}->{embed} //= '-1';
$args{pgV}->{nodesort} //= 'random';
$args{pgV}->{transparent} //= 'opaque';
$args{pgV}->{legendsort} //= 'size';

$args{pgV}->{map} //= -1;
$args{pgV}->{collab} //= 1;

$args{pgV}->{api_doctype} = lc($args{pgV}->{imgtype});

################################################################################
if ($args{pgV}->{debug} == 1) {
	print	'Content-type: text/plain'."\n\n" }
################################################################################

if (! $args{pgV}->{nodes}) {
	$args{pgV}->{nodes} = $nodesRef;
	$args{pgV}->{connections} = $connRef;
}

print 'Content-type: image/svg+xml'."\n\n";
print collabPlots(%args);
exit;

1;
