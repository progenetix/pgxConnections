use List::MoreUtils qw(any apply uniq);
use LWP::UserAgent;
use LWP::Simple;
use	Spreadsheet::Read;

sub pgWebFile2list {

	my %args =	@_;
	$args{HTTP} ||= $_[0];
	$args{DELCOMMENT} ||= 'T';

	my $dlLink = $args{HTTP};

  if ($dlLink =~ /dropbox\.com/) {
  	$dlLink =~ s/(\?dl=\w)?$/?dl=1/ }

	$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

	my $ua				=		new LWP::UserAgent;
  $ua->agent("Mozilla/8.0");

  my $req				=		new HTTP::Request 'GET' => $dlLink;
  $req->header('Accept' => 'text/plain');

  my $res =		$ua->request($req);
	my @filecontent;

	if ($dlLink =~ /\.xls/i) {
		my $book		=	ReadData($res->{_content});
		foreach my $currentRow (Spreadsheet::Read::rows($book->[1])) {
			push(
				@filecontent,
				join("\t", @{ $currentRow }),
			);
		}
	} else {
		@filecontent			  =		split("\n", $res->{_content});
		chomp	@filecontent;
	}

	if ($args{DELCOMMENT} =~ /^T/i) {
		@filecontent 			  = 	grep{ ! /^\#/ } @filecontent;
		@filecontent 			  = 	grep{ /./ } @filecontent;
	}

	return	\@filecontent;

}

################################################################################

sub pgFile2list {

	my %args						  =		@_;
	$args{FILE}					  ||= $_[0];
	$args{DELCOMMENT}		  ||= 'T';
	$args{DELEMPTY}			  ||= 'T';
	$args{COMMENTST}		  ||= '#';

	my @filecontent;

	if ($args{FILE} =~ /\.(ods)|(xlsx?)$/i) {

		@filecontent			  =		@{ pgSpreadsheet2list($args{FILE}) };

	} else {

		@filecontent			  =		split(/\r\n?|\n/, pgFile2string($args{FILE}));

	}

	if ($args{DELCOMMENT} =~ /^T/i) {
		@filecontent			  =		grep{ ! /^\#/ } @filecontent;
	}

	if ($args{DELEMPTY} =~ /^T/i) {
		@filecontent			  =		grep { /\w/ } @filecontent;
	}

	chomp	@filecontent;

	return	\@filecontent;

}

################################################################################

sub pgShiftHeaderToProgenetixKeys {

	my $list			=		$_[0];

  my $arrayKeys =   [ qw(TAGS) ];

	my @header		=		split("\t", shift @{ $list });
	my %keyPos		=		map{ $header[$_] =>	$_ } 0..$#header;
	my @returnList;

	foreach my $meta (@$list) {
		my @current	=		split("\t", $meta);
		push(
			@returnList,
			{ map{ $_ => $current[ $keyPos{ $_ } ] } keys %keyPos },
		);
	}

  for my $i (0..$#returnList) {
    foreach my $arrayKey (@$arrayKeys) {
      if ($returnList[$i]->{$arrayKey}) {
        if (ref $returnList[$i]->{$arrayKey} ne 'ARRAY') {
          $returnList[$i]->{$arrayKey}  =   [ split(/(?:,)|(?:\:\:)/, $returnList[$i]->{$arrayKey}) ];
        }
      }
    }
  }

	return \@returnList;

}

################################################################################

sub pgFile2string {

	my %args			=		@_;

	$args{FILE}		||=	$_[0];
  my $fContent  =   q{};

	if (! -f $args{FILE}) {

		_d('no file at', $args{FILE});
		return	q{};

	} else {

		open	FILE, "$args{FILE}" or die "No file $args{FILE} $!";

		local 	$/;															# no input separator
		$fContent   =	  <FILE>;
    close FILE;

  }

  return  $fContent;

}

################################################################################

sub pgReadJSONlist {

	my %args			=		@_;
	$args{FILE}		||= $_[0];
	my $json			=		JSON->new;
	return	[ map{ $json->relaxed(1)->decode( $_ ) }  read_file($args{FILE}) ];

}

################################################################################

sub pgReadJSONformatted {

	my %args 			=		@_;

	$args{FILE}		||= $_[0];

	my $json			=		JSON->new;

	open FILE, "$args{FILE}" or warn "No file $args{FILE} $!";
	local 	$/;
	my $parsed 		=		$json->relaxed(1)->decode( <FILE> );
	close	FILE;

	return	$parsed;

}

################################################################################

=pod

pgSortGroupIDs()

=cut

sub pgSortGroupIDs {

	my %args			=		@_;

	$args{SORTFILE}		    ||=	q{};

	my @sortedGroupIDs;

	if (
		$args{SORTFILE} =~ /\w\w\w/
		&&
		-e $args{SORTFILE}
	) {
		@sortedGroupIDs		  =		read_file($args{SORTFILE});
		chomp @sortedGroupIDs;
	} else {
		@sortedGroupIDs		  =		grep{! /ALLCASES/ } sort keys %{ $args{GROUPF} };
	}

	if ($args{pgV}->{sample_number_min} > 1) {
		@sortedGroupIDs		  =		grep{ $args{GROUPF}->{ $_ }->{SAMPLENO} >= $args{pgV}->{sample_number_min} } @sortedGroupIDs;
	}

	return \@sortedGroupIDs;

}

################################################################################

sub _defaultsFileReader {

	my %args			=	@_;

	$args{BASECORR}	      ||=	0;
	$args{GAINTHRESH}		  ||=	0.15;
	$args{LOSSTHRESH}		  ||=	-0.15;

	my %defs;

	foreach (grep{ /^\-?\w+?\t[\w\.\-\:]+?$/ } read_file($args{FILE}) ) {

		my @def			=		split("\t", $_);
		chomp	@def;
		$def[1]			=~	s/^\s*?([^\s]+?)\s*?$/$1/;

		if ($def[0] =~ /(seg)?GainThresh/i) {
			$defs{GAINTHRESH}	=	  $def[1];
			$defs{ -gth }		  =		$def[1];
		}
		if ($def[0] =~ /(seg)?LossThresh/i) {
			$defs{LOSSTHRESH}	=	  $def[1];
			$defs{ -lth }		  =		$def[1];
		}
		if ($def[0] =~ /segNormal/i) {
			$defs{BASECORR}	  =	-$def[1];
			$defs{ -blc }		  =		-$def[1];
	}}

	return %defs;

}

################################################################################

sub pgSegFileReader {

=pod

The pgSegFileReader reads in segmentation output files with a determined tab
order:

* experimentId
* chromosome
* base start
* base end
* segment mean
* probe number

=cut

	my %args			=		@_;

	$args{FILTER} 		    ||=	-1;
	$args{LOSSTHRESH}     ||=	-0.15;
	$args{GAINTHRESH}     ||=	0.15;
	$args{REVERSE}		    ||=	'n';

	my @arraySegs;

	my @segData		=		read_file($args{FILE});
	shift @segData;
	chomp @segData;
	@segData		  =		apply{ $_ =~ s/^X(\d+)/$1/ } @segData;

  my $segObjects;

	foreach (@segData) {

		my @csData	=		split "\t", $_;

		my (
      $segValue,
      $probeno
    )   =   ($csData[4], $csData[5]);

		if (
			$csData[4] =~ /^\-?1$/
			&&
			$csData[5] =~ /^\-?\d+?\.\d+?$/
			&&
			$csData[6] =~ /^\d+$/
		) {
			($segValue, $probeno)	=	($csData[5], $csData[6]);
		}
		$csData[1]	=~	s/^23$/X/;
		$csData[1]	=~	s/^24$/Y/;

		push(
      @{$segObjects},
      {
        UID             =>  $csData[0],
        assembly_id      =>  ($args{pgV}->{assembly_id}  ||= "GRCh36"),
				reference_name	  =>	$csData[1],
				start	          =>	$csData[2],
				end		          =>	$csData[3],
				info    =>  {
          probes        =>	$probeno,
          svlen         =>  ($csData[3] - $csData[2]),
          value         =>  $segValue,
        },
				variant_type		  =>	q{},
				experiment_type	=>	($args{TECHNIQUE} ||= 'acgh'),
			}
    );

  }

  if (scalar(uniq(map{ $_->{UID} } @{$segObjects})) > 1) {

    if ($args{UID} =~ /\w\w\w/) {

      $segObjects       =   [ grep{ $_->{UID} eq $args{UID} } @{$segObjects} ];

  }}

  if ($args{FILTER} > 0) {

    $segObjects =   [
      grep{
        ($_->{info}->{value} >= $args{GAINTHRESH})
        ||
        ($_->{info}->{value} <= $args{LOSSTHRESH})
      } @{$segObjects}
    ];

  }

	for my $i (0..$#{ $segObjects }) {

    if ($segObjects->[$i]->{info}->{value} >= $args{GAINTHRESH}) {
      $segObjects->[$i]->{variant_type}  =   'DUP' }
    elsif ($segObjects->[$i]->{info}->{value} <= $args{LOSSTHRESH}) {
      $segObjects->[$i]->{variant_type}  =   'DEL' }

  }

	return $segObjects;

}

################################################################################

sub _readProgenetixTabbed {

	my %args			=		@_;
	$args{FILE}		||=	$_[0];

	open PS, "$args{FILE}";
	my @in				=		grep{ /\w\w/ } <PS>;
	close	PS;
	chomp	@in;

	@in						=		apply{ $_ =~ s/[\'\"]//g } @in;
	my @keys			=		split("\t", shift @in);
	my $samples		=		[];

	foreach (@in) {

		my @values	=		split("\t", $_);
		my $cSample_r			=		{};

		foreach (@keys) {

			$cSample_r->{ uc($_) }	=	shift @values;

		}

		push(@{ $samples }, $cSample_r);

	}

	return	$samples;

}

################################################################################

sub probeFileCounter {

	my %args						=		@_;
	$args{FILE}				||=	$_[0];

	open PS, "$args{FILE}";
	my $ln							=		grep{ /\d/ } <PS>;
	close	PS;

	return $ln;

}

################################################################################

sub probeFileReader {

	my %args						=		@_;
	$args{FILE}					||=	$_[0];

	$args{NORMALIZE}		||=	-1;
	$args{FIXAFFY}			||=	'no';
	$args{REVERSE}			||=	'n';

	my $probes					=		[];

	open PS, "$args{FILE}";
	my @in							=		grep{ /\w/ } <PS>;
	close	PS;

	chomp @in;

	my $probeNo					=		0;

	if (
		$in[0] =~ /^\t\w/
		&&
		$in[1] =~ /^\w+?\t(\w\w?)\t\1\t/
		&&
		$in[123] =~ /^\w+?\t(\w\w?)\t\1\t/
		&&
		$in[-1] =~ /^\w+?\t(\w\w?)\t\1\t/
	) {

		$args{FIXAFFY}	=	'yes';

	}

	foreach (@in) {

		my @probeData			=		split;
		@probeData				=		apply{ s/ //g } @probeData;

		if ($args{FIXAFFY} =~ /y/i) {

			@probeData		  =	($probeData[0], $probeData[1], $probeData[3], $probeData[4]);
		}

		$probeData[0]			=~	s/[^\w]/_/g;

		# removes the prefix, which is later added back using the current probe
		# index; this avoids errors through duplicate source IDs
		$probeData[0]			=~	s/^ID_\d+?_//g;
		$probeNo++;

		if ($args{REVERSE} =~ /y/) { $probeData[3] *= -1 }

		if (
			$probeData[1] =~ /^\w\d?$/
			&&
			$probeData[2] =~ /^[\d\.]+?$/
			&&
			$probeData[3] =~ /^[\d\.e\-]+?$/
		) {

			$probeData[1]		=~	s/^23$/X/;
			$probeData[1]		=~	s/^24$/Y/;
			push(
        @$probes,
				{
        	probe_id		  =>	'ID_'.$probeNo.'_'.$probeData[0],
					chromosome    =>	$probeData[1],
					position		  =>	$probeData[2],
					value			    =>	$probeData[3] * 1,
				}
			);

	}}

	if ($args{NORMALIZE} == 1) {

		my @normSegments;

		foreach my $currentChro (1..22, 'X', 'Y') {

 			my @chroSegments			=	grep{ $_->{CHRO} == $currentChro } @$probes;
 			my %allBasePositions	=	map{ $_->{position} =>	1 } @chroSegments;

 			foreach my $basePos (sort keys %allBasePositions) {

 				my @allBaseValues 	=	map{ $_->{VALUE} } (grep{ $_->{position} == $basePos && $_->{VALUE} =~ /\d/ } @chroSegments);

 				if (scalar(@allBaseValues) > 0) {

 					push(
            @normSegments,
            {
 							chromosome	       =>	$currentChro,
 							position	=>	$basePos,
 							value	    =>	sprintf "%.4f", sum(@allBaseValues) / scalar(@allBaseValues),
 							probe_id	=>	$currentChro.'_'.$basePos,
 						}
 					);

		}}}

		$probes				=	\@normSegments;
	}

	# fastmap will just collapse all values for one position; this only can work if all values are
	# the same for this position (this was basically done to fix a data submission problem by a
	# collaborator ...)

	elsif ($args{NORMALIZE}  =~ /fastmap/i ) {

		my %fastMap			=	map{ 'chr'.$_->{CHRO}.'_'.$_->{position} =>	$_ } @$probes;
		$probes				=	[ values %fastMap ];

	}

	return	$probes;
}

################################################################################

sub pgGetArrayPaths {

=pod

returns a list reference containing objects with found array locations, based on the standard
arraymap hierarchy (series directory name = SERIESID, directories in these = UID/ARRAYID

=cut

	my %args						=	@_;

	$args{ARRAYIN}			||=	$args{pgP}->{loc_site_arraymap};
	$args{ARRAYOUT}			||=	$args{ARRAYIN};
	$args{UPDATE}				||=	'y';
	$args{ARRMAXDAYS}		||=	365;
	$args{TESTFILE}			||=	'arrayplot';

	my $arrays					=		[];

	# series

	my @arraySeries;

	opendir DIR, $args{ARRAYIN};

	if (any { /\w/ } @{ $args{pgV}->{ser_m} }) {

		foreach my $search (grep{ /\w/ } @{ $args{pgV}->{ser_m} }) {

			@arraySeries	=	(@arraySeries, (grep{ /^$search(:?[\w\-]+?)?$/ } -d, readdir(DIR)));

	}} else {

		@arraySeries		=	grep{ ! /^te?mp$/ } grep{ /^\w[\w\-]+?$/ } readdir(DIR);

	}

	close DIR;

	# arrays

	foreach my $currentSeries (@arraySeries) {

		my @currentArrays;

		opendir DIR, $args{ARRAYIN}.'/'.$currentSeries;

		if (any { /\w/ } @{ $args{pgV}->{uid_m} }) {

			foreach my $search (grep{ /\w/ } @{ $args{pgV}->{uid_m} }) {

				@currentArrays	= (@currentArrays, (grep{ /^$search/ } -d, readdir(DIR)));

		}} else {

			@currentArrays	=	grep{ ! /^te?mp$/ } grep{ /^\w[\w\-]+?$/ } readdir(DIR);

		}

		close DIR;

		@currentArrays		=		uniq(@currentArrays);

		foreach my $array (@currentArrays) {

			my $paths				=		{
														UID				=>	$array,
														ARRAYID		=>	$array,
														SERIESID	=>	$currentSeries,
													};

			foreach (qw(IN OUT)) {

				$paths->{ 'SERP'.$_ }		=		$args{ 'ARRAY'.$_ }.'/'.$currentSeries;
				$paths->{ 'PATH'.$_ }		=		$args{ 'ARRAY'.$_ }.'/'.$currentSeries.'/'.$array;
				$paths->{ 'SEGF'.$_ }		=		$args{ 'ARRAY'.$_ }.'/'.$currentSeries.'/'.$array.'/segments,cn.tsv';
				$paths->{ 'PROBEF'.$_ } =		$args{ 'ARRAY'.$_ }.'/'.$currentSeries.'/'.$array.'/probes,cn.tsv';
				$paths->{ 'DEFF'.$_ }		=		$args{ 'ARRAY'.$_ }.'/'.$currentSeries.'/'.$array.'/defaults.tab';

			}


			if ($args{TESTFILE} =~	/plot/i) {

				foreach my $imgtype (qw(SVG PNG)) {

					foreach (qw(IN OUT)) {

						$paths->{ $imgtype.$_ }					=		$args{ 'ARRAY'.$_ }.'/'.$currentSeries.'/'.$array.'/arrayplot,chr1.'.lc($imgtype);
						$paths->{ $imgtype.$_.'FULL' }	=		$args{ 'ARRAY'.$_ }.'/'.$currentSeries.'/'.$array.'/arrayplot.'.lc($imgtype);
						$paths->{ 'AGE'.$imgtype.$_ }		=		(time() - (@{stat($paths->{ $imgtype.$_ })})[10]) / 3600 / 24;

				}}

				if (
					$args{UPDATE} =~ /y/i
					||
					(
						($paths->{AGESVGOUT} > $args{ARRMAXDAYS})
						||
						($paths->{AGEPNGOUT} > $args{ARRMAXDAYS})
					)
				) {

					push(@{ $arrays }, $paths);

		}} elsif ($args{TESTFILE} =~	/probes/i) {

			if (
				$args{UPDATE} =~ /y/i
				||
				(! -f $paths->{PROBEFOUT})
			) {

					push(@{ $arrays }, $paths);

	}}}}

	return	$arrays;

}


################################################################################

sub pgSpreadsheet2list {

	my %args						=		@_;
	$args{FILE}					||= 	$_[0];

	use	Spreadsheet::Read;
	use	Spreadsheet::XLSX;
  use Spreadsheet::ReadSXC;

	my $book						=	ReadData($args{FILE});
	my @table;

	foreach my $currentRow (Spreadsheet::Read::rows($book->[1])) {

		push(
			@table,
			join("\t", @{ $currentRow }),
		);

	}

	return	\@table;

}

################################################################################

1;
