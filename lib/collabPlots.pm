use List::Util qw(min max shuffle sum);
use List::MoreUtils qw(any apply uniq);

sub collabPlots {

	my %args = @_;

	$args{NODESIZE} ||= 20;
	$args{pgV}->{imgw} ||= $args{pgV}->{imgh} + $args{pgV}->{legendw};
	$args{CENTERX} ||= $args{pgV}->{imgh} / 2;
	$args{CENTERY} ||= $args{pgV}->{imgh} / 2;
	$args{pgV}->{label_rad} ||= $args{pgV}->{circ_radius} + $args{pgV}->{ring_width} + $args{pgV}->{gapwidth};
	$args{pgV}->{radConns} ||= $args{pgV}->{circ_radius} - $args{pgV}->{gapwidth};

	use constant PI => 4 * atan2(1, 1);

	$args{BezRad} = 0.5;

	$args{pgV}->{fontcol} = '#ffffff' if ($args{pgV}->{plot_bgcolor_hex} =~ /000000/ && $args{pgV}->{fontcol} =~ /000000/);
	$args{pgV}->{fontcol} = '#000000' if ($args{pgV}->{plot_bgcolor_hex} =~ /ffffff/ && $args{pgV}->{fontcol} =~ /ffffff/);

	###############################################################################
	###############################################################################
	###############################################################################

	# tab-delimited connections file
	# format is userID(A) - tab - userID(B) - tab - connectionType (not used)

	# tab-delimited users file
	# format is group_label	group_lat	group_lon	item_size	item_label	item_link	markerType

	$args{pgP}->{loc_projectpath} = $args{pgP}->{loc_collab}.'/'.$args{pgV}->{project};
	$args{pgP}->{loc_connFile} = $args{pgP}->{loc_projectpath}.'/connections.txt';
	$args{pgP}->{loc_nodesFile} = $args{pgP}->{loc_projectpath}.'/people.txt';

	# reading the connections file
	my @connIn;
	if ($args{pgV}->{connections} =~ /...../) {
	  @connIn = @{ pgWebFile2list( $args{pgV}->{connections} ) } }
	elsif (-f $args{pgP}->{loc_connFile}) {
		@connIn = @{ pgFile2list( FILE => $args{pgP}->{loc_connFile} ) } }

	@connIn = apply { s/['"]//gxms } @connIn;

	# reading the nodes file
	my @nodesIn;
	if ($args{pgV}->{nodes} =~	/../) {
		@nodesIn = @{ pgWebFile2list( $args{pgV}->{nodes} ) } }
	else {
		@nodesIn = @{ pgFile2list( FILE => $args{pgP}->{loc_nodesFile} ) } }

	@nodesIn = apply { s/['"]//gxms } @nodesIn;
	my $connOut = {};
	my $entities = {};
	my $nodesOut = {};

	# collecting the per name information in an href

	foreach (@nodesIn) {
		if ($_ =~ /^#/) { next }
		my ($entity, $lat, $lon, $count, $name, $link) = split("\t", $_);		

		if ($lat !~ /^\-?\d+?(\.\d+?)?$/) {
			next }
		
		my $ID = $name;
		$ID =~ s/^.+\s(\w+)$/$1/;
		$nodesOut->{$ID} = {
			NAME => $name,
			INSTITUTION => $entity,
			LINK => $link,
		};

		$entities->{$entity}->{COLOR} = '128,255,84';
		$entities->{$entity}->{LABELL} = $entities->{$entity}->{INSTITUTION};
	}

	# now making the any-2-any connections if none were loaded

	if (@connIn < 1) {
		my @nodes = sort(keys %{$nodesOut});
		for (my $i=0; $i < $#nodes; $i++) {
			for (my $k=$i+1; $k <= $#nodes; $k++) {
				push(@connIn, join("\t", ($nodes[$i], $nodes[$k])));
	}}}

	my @conCols = map { join ",", map { sprintf "%.0f", rand(255) } (0..2) } (0..$#connIn);
	my @instCols = map { join ",", map { sprintf "%.0f", rand(255) } (0..2) } (0..$#nodesIn);

	# collecting connections per name pair in an href

	foreach (@connIn) {
		my @connection = split("\t", $_);
		if (
			(any { lc($_) eq lc($connection[0]) } keys %{$nodesOut})
			&&
			(any { lc($_) eq lc($connection[1]) } keys %{$nodesOut})
		) {
      my $connColor;
      if ($connection[2] =~ /^\d\d?\d?\,\d\d?\d?\,\d\d?\d?$/) {
        $connColor = $connection[2] }
      else {
        $connColor = shift(@conCols) }
			my $ID = join('::', sort(($connection[0], $connection[1])));
			$connOut->{$ID} = {
				MEMBERS => [sort(($connection[0], $connection[1]))],
				COLOR => $connColor
			};
		}
	}

	foreach (keys %{$entities}) { $entities->{$_}->{COLOR} = shift @instCols };

	# sorting the nodes

	my @nodesSorted;

	if ($args{pgV}->{nodesort} =~ /node/) {
		@nodesSorted = sort keys %{$nodesOut};
	} elsif ($args{pgV}->{nodesort} =~ /inst/) {
		foreach my $inst (sort keys %{$entities}) {
			push(
				@nodesSorted,
				sort grep{ $nodesOut->{$_}->{INSTITUTION} =~ /^$inst$/i } keys %{$nodesOut},
			);
	}} else {
		@nodesSorted = shuffle keys %{$nodesOut}
	}

	###############################################################################
	# plotting the nodes & connections
	###############################################################################

	my $baseCorrection = 0;

	foreach my $ID (@nodesSorted) {
		$nodesOut->{$ID}->{baseStart} = $baseCorrection;
		$nodesOut->{$ID}->{baseStop} = $baseCorrection + $args{NODESIZE};
		$nodesOut->{$ID}->{baseLabel} = $baseCorrection + $args{NODESIZE} / 2;
		$baseCorrection	+= $args{NODESIZE} + $args{pgV}->{circ_node_gaps};
	}

	my $circleSize = $baseCorrection;

	my $SVG = '<svg
xmlns="http://www.w3.org/2000/svg"
xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1"
height="'.$args{pgV}->{imgh}.'px"
width="'.$args{pgV}->{imgw}.'px"
style="'.($args{pgV}->{transparent} !~ /transparent/ ? 'background-color: #ffffff; ' : q{}).'font-family: helvetica, sans-serif; "
>';

if ($args{pgV}->{transparent} !~ /transparent/) {
	$SVG .= '
<rect x="0" y="0" width="'.$args{pgV}->{imgw}.'" height="'.$args{pgV}->{imgh}.'" style="fill: '.$args{pgV}->{plot_bgcolor_hex}.';" />';

}

	###############################################################################
	# drawing the circle / entities
	###############################################################################

	foreach my $ID (@nodesSorted) {

		$nodesOut->{$ID}->{NAME} = _EscapeXML($nodesOut->{$ID}->{NAME});
		$nodesOut->{$ID}->{LINK} = _EscapeXML($nodesOut->{$ID}->{LINK});
		$nodesOut->{$ID}->{INSTITUTION} = _EscapeXML($nodesOut->{$ID}->{INSTITUTION});

		my $chroF_0 = $nodesOut->{$ID}->{baseStart} / $circleSize;
		my $chroF_n = ($nodesOut->{$ID}->{baseStart} + $args{NODESIZE}) / $circleSize;
		$SVG .= pgSVGpie(
			%args,
			RADI => $args{pgV}->{circ_radius},
			RADO => $args{pgV}->{circ_radius} + $args{pgV}->{ring_width},
			PIESTARTF => $chroF_0,
			PIESTOPF => $chroF_n,
			STYLE => 'fill: rgb('.$entities->{ $nodesOut->{$ID}->{INSTITUTION} }->{COLOR}.')',
			LINK => $nodesOut->{$ID}->{LINK},
		);

		my $circFraction = ($nodesOut->{$ID}->{baseStart} + $args{NODESIZE} / 2 ) / $circleSize;

		# adapting the text position a bit depending on the text direction, so it is really centered

		if ($circFraction > 0.75 || $circFraction < 0.25) { $circFraction += 0.005 }
		if ($circFraction > 0.25 && $circFraction < 0.75) { $circFraction -= 0.003 }

		my (
				$X,
				$Y,
				$rad,
				$deg,
		) = pgCirclePoint(
			%args,
			RADIUS => $args{pgV}->{label_rad},
			CIRCF => $circFraction,
		);

		# the rotation for the chromosome labels is calculated, making them aligned along the circle
		# with the bottom facing the circle's center (currently only used for SVG plotting)

		my $anchorPoint = 'start';

		if ( $deg > 90 && $deg <270 ) {
			$deg += 180;
			$anchorPoint = 'end';
		}

		if ($args{pgV}->{fontpx} > 0) { 
			$SVG .= '
<a
	xlink:href="'.$nodesOut->{$ID}->{LINK}.'"
	xlink:show="new"
	xlink:title="'.$nodesOut->{$ID}->{NAME}.'"
>
<text x="'.$X.'" y="'.$Y.'"
	style="text-anchor: '.$anchorPoint.'; font-size: '.$args{pgV}->{fontpx}.'px; fill: '.$args{pgV}->{fontcol}.';"
	transform="rotate('.(sprintf "%.2f", $deg).' '.$X.' '.$Y.')">
	'.$nodesOut->{$ID}->{NAME}.'
</text>
</a>';
		}

	}

	###############################################################################
	# drawing the legend, only if requested
	###############################################################################

	if ($args{pgV}->{legendw} > 1) {

		my $legendX = $args{pgV}->{imgw} - $args{pgV}->{fontpx} * 2;
		my $legendFontPx = $args{pgV}->{legendfpx};
		my $entityNumber = scalar(keys %{$entities});

		while ( $args{pgV}->{imgh} < (2 * $legendFontPx * ($entityNumber + 1)) ) { $legendFontPx-- }

		my $topLegendY = $legendFontPx * 2;
		my $bottomLegendY = $legendFontPx;
		my @down = sort keys %{$entities};
		my @up = ();

		if ($args{pgV}->{legendsort} =~ /size/i) {
			@down = sort { length($b) <=> length($a) } @down }
		if ($args{pgV}->{legendsort} =~ /random/i) {
			@down = shuffle(@down) }
		my $legendItemH = $entityNumber * 2 * $legendFontPx + 2 * $legendFontPx;

		if ($args{pgV}->{legendpos} =~ /split/) {
			$args{pgV}->{legend_y_gap} = $args{pgV}->{imgh} - $legendItemH - 4 * $legendFontPx }

		if ($args{pgV}->{legendpos} =~ /split|center/) {

			my (@even, @odd);

			my $i = 0;
			push @{ $i++ % 2 ? \@odd : \@even }, $_ for @down;

			@down = @even;
			@up = @odd;
			if ($args{pgV}->{legendsort} =~ /size/i) {
				@up = sort { length($a) <=> length($b) } @up }

			$topLegendY = $args{pgV}->{imgh} / 2 - @down * 2 * $legendFontPx + $legendFontPx / 2 - $args{pgV}->{legend_y_gap} / 2;
			$bottomLegendY = $args{pgV}->{imgh} / 2 + $legendFontPx / 2 + $args{pgV}->{legend_y_gap} / 2;

		}

		if ($args{pgV}->{legendpos} =~ /bottom/) {

			if ($args{pgV}->{legendsort} =~ /size/i) {
				@up = sort { length($a) <=> length($b) } @down }

			@down = ();
			$bottomLegendY = $args{pgV}->{imgh} - @up * $legendFontPx * 2 - $legendFontPx * 2;

		}

		foreach (@down) {
			$SVG			.= '
<rect x="'.$legendX.'" y="'.$topLegendY.'" width="'.($args{pgV}->{fontpx} + 1).'" height="'.($legendFontPx + 1).'" fill="rgb('.$entities->{$_}->{COLOR}.')" />
<text
	x="'.($legendX - $args{pgV}->{fontpx}).'" y="'.($topLegendY + $legendFontPx - 1).'"
	style="text-anchor: end; font-size: '.$legendFontPx.'px; fill: '.$args{pgV}->{fontcol}.';"
>'._EscapeXML($_).'</text>';

			$topLegendY		+= $legendFontPx * 2;

		}

		foreach (@up) {

			$SVG			.= '
<rect x="'.$legendX.'" y="'.$bottomLegendY.'" width="'.($args{pgV}->{fontpx} + 1).'" height="'.($legendFontPx + 1).'" fill="rgb('.$entities->{$_}->{COLOR}.')" />
<text
	x="'.($legendX - $args{pgV}->{fontpx}).'" y="'.($bottomLegendY + $legendFontPx - 1).'"
	style="text-anchor: end; font-size: '.$legendFontPx.'px; fill: '.$args{pgV}->{fontcol}.';"
>'._EscapeXML($_).'</text>';

			$bottomLegendY	+= $legendFontPx * 2;

	}}

	###############################################################################
	# drawing connections
	###############################################################################

	if (keys %{$connOut} > 100) { $args{pgV}->{conn_opacity} = 0.1 };

	foreach my $ID (shuffle keys %{$connOut}) {

		my ($ID1, $ID2) = @{ $connOut->{$ID}->{MEMBERS} };

		if ($ID1 =~ /../ && $ID2 =~ /../ && $ID1 ne $ID2) {

			my $randF = 0.01 * shuffle(35..45);
			my $randS = 0.01 * shuffle(-23..23);
			my %connFs = (
        connstartF1 => ($nodesOut->{$ID1}->{baseStart} + $args{NODESIZE} * ($randF + $randS)) / $circleSize,
        connstopF1 => ($nodesOut->{$ID1}->{baseStart} + $args{NODESIZE} * (1-$randF + $randS)) / $circleSize,
        connstartF2 => ($nodesOut->{$ID2}->{baseStart} + $args{NODESIZE} * ($randF + $randS)) / $circleSize,
        connstopF2 => ($nodesOut->{$ID2}->{baseStart} + $args{NODESIZE} * (1-$randF + $randS)) / $circleSize,
      );

			foreach my $where (qw(start stop)) {

				foreach my $site (1,2) {
					(
						$connOut->{$ID}->{ $where.$site.'x' },
						$connOut->{$ID}->{ $where.$site.'y' },
						$connOut->{$ID}->{ $where.'Rad'.$site }
					) = pgCirclePoint(
						%args,
						RADIUS => $args{pgV}->{radConns},
						CIRCF => $connFs{ 'conn'.$where.'F'.$site },
					);

					$args{BezRad} = 0.1 * shuffle(4..9);

					$connOut->{$ID}->{ 'bez'.$where.$site.'x' } = sprintf "%.1f", $args{CENTERX} + cos( $connOut->{$ID}->{ $where.'Rad'.$site } ) * $args{pgV}->{radConns} * $args{BezRad},
					$connOut->{$ID}->{ 'bez'.$where.$site.'y' } = sprintf "%.1f", $args{CENTERY} + sin( $connOut->{$ID}->{ $where.'Rad'.$site } ) * $args{pgV}->{radConns} * $args{BezRad},

			}}

			$SVG						.= '
<path d="
	M '.$connOut->{$ID}->{start1x}.','.$connOut->{$ID}->{start1y}.'
	C '.$connOut->{$ID}->{bezstart1x}.','.$connOut->{$ID}->{bezstart1y}.' '.$connOut->{$ID}->{bezstart2x}.','.$connOut->{$ID}->{bezstart2y}.' '.$connOut->{$ID}->{start2x}.','.$connOut->{$ID}->{start2y}.'
	A '.$args{pgV}->{radConns}.','.$args{pgV}->{radConns}.' 0 0,1 '.$connOut->{$ID}->{stop2x}.','.$connOut->{$ID}->{stop2y}.'
	C '.$connOut->{$ID}->{bezstop2x}.','.$connOut->{$ID}->{bezstop2y}.' '.$connOut->{$ID}->{bezstop1x}.','.$connOut->{$ID}->{bezstop1y}.' '.$connOut->{$ID}->{stop1x}.','.$connOut->{$ID}->{stop1y}.'
	A '.$args{pgV}->{radConns}.','.$args{pgV}->{radConns}.' 0 0,0 '.$connOut->{$ID}->{start1x}.','.$connOut->{$ID}->{start1y}.'
	Z" style="stroke-width: 1;  fill: rgb('.$connOut->{$ID}->{COLOR}.'); opacity: '.$args{pgV}->{conn_opacity}.';"
/>';

	 }}

	$SVG .= '
</svg>';

	return	$SVG;

}

################################################################################

sub _EscapeXML {

	my $xml = $_[0];
	my %escapes = (
		"&" => '&amp;',
		'"' => '&quot;',
		"'" => '&apos;',
		"<" => '&lt;',
		">" => '&gt;',
	);

	foreach (keys %escapes) { $xml =~	s/$_/$escapes{$_}/g }

	$xml =~	s/\&amp\;amp\;/&amp;/g;

	return	$xml;

}


1;
