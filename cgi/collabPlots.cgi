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
    - http://progenetix.org/cgi/pgxConnections/cgi/collabPlots.cgi?nodes=https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/main/collab/people.tab&nodesort=inst&connections=https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/main/collab/connections.tab&legendw=120
=cut

# print 'Content-type: text/plain'."\n\n";

my %args;

$args{pgV} = setDefaults();
$args{pgV} = pgReadParam(%args);

################################################################################
if ($args{pgV}->{debug} == 1 or $args{pgV}->{help} == 1) {
	print	'Content-type: text/plain'."\n\n";
}

if ($args{pgV}->{help} == 1) {
	print '####################################'."\n";
	print '**Plot Parameters**'."\n\n".'Modify through query string:'."\n\n";
	my $dump = Dumper($args{pgV});
    print $dump;
	print '####################################'."\n\n";
	exit;
}


################################################################################
# print Dumper($args{pgV});

my $nodesRef = 'https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/master/collab/people.tab';
my $connRef = 'https://raw.githubusercontent.com/compbiozurich/compbiozurich.github.io/master/collab/connections.tab';

$args{pgV}->{api_doctype} = lc($args{pgV}->{imgtype});


if (! $args{pgV}->{nodes}) {
	$args{pgV}->{nodes} = $nodesRef;
	$args{pgV}->{connections} = $connRef;
}

print 'Content-type: image/svg+xml'."\n\n";
print collabPlots(%args);
exit;

1;
