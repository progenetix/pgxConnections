################################################################################

sub circleObjectConnections {

	my %args = @_;

	$args{MAXCONN} = 2000;

	my $areaF_0 = $args{STARTF};
	my $ind = max(keys %{ $args{PO} }) + 1;

	my @connections;

	for my $i (0..$#{ $args{PLOTREGIONS} }) {

		my $areaF = $args{BASESCALING} * ($args{PLOTREGIONS}->[$i]->{BASESTOP} - $args{PLOTREGIONS}->[$i]->{BASESTART});

		foreach my $sample (@{ $args{SAMPLES} }) {

			my @ints_0 = grep{ $_->{reference_name} eq $args{PLOTREGIONS}->[$i]->{CHRO} } @{ $sample->{ variants } };
			@ints_0 = grep{ $_->{end} >= $args{PLOTREGIONS}->[$i]->{BASESTART} } @ints_0;
			@ints_0 = grep{ $_->{start} <= $args{PLOTREGIONS}->[$i]->{BASESTOP} } @ints_0;

			for my $m (0..$#ints_0) {

				if ($ints_0[$m]->{start} <  $args{PLOTREGIONS}->[$i]->{BASESTART}) { $ints_0[$m]->{start} = $args{PLOTREGIONS}->[$i]->{BASESTART} }
				if ($ints_0[$m]->{end} >  $args{PLOTREGIONS}->[$i]->{BASESTOP}) { $ints_0[$m]->{end} = $args{PLOTREGIONS}->[$i]->{BASESTOP} }

				$ints_0[$m]->{STARTF} = $areaF_0 + $args{BASESCALING} * $ints_0[$m]->{start};
				$ints_0[$m]->{STOPF} = $areaF_0 + $args{BASESCALING} * $ints_0[$m]->{end};

			}

			my $connAreaF_0 = $areaF_0 + $areaF + $args{CHROGAPF};

			for my $k (($i+1)..$#{ $args{PLOTREGIONS} }) {

				my $connAreaF = $args{BASESCALING} * ($args{PLOTREGIONS}->[$k]->{BASESTOP} - $args{PLOTREGIONS}->[$k]->{BASESTART});

				my @ints_n = grep{ $_->{reference_name} eq $args{PLOTREGIONS}->[$k]->{CHRO} } @{ $sample->{ variants } };
				@ints_n = grep{ $_->{end} >= $args{PLOTREGIONS}->[$k]->{BASESTART} } @ints_n;
				@ints_n = grep{ $_->{start} <= $args{PLOTREGIONS}->[$k]->{BASESTOP} } @ints_n;

				for my $o (0..$#ints_n) {

					if ($ints_n[$o]->{start} <  $args{PLOTREGIONS}->[$k]->{BASESTART}) { $ints_n[$o]->{start} = $args{PLOTREGIONS}->[$k]->{BASESTART} }
					if ($ints_n[$o]->{end} >  $args{PLOTREGIONS}->[$k]->{BASESTOP}) { $ints_n[$o]->{end} = $args{PLOTREGIONS}->[$k]->{BASESTOP} }

					$ints_n[$o]->{STARTF} = $connAreaF_0 + $args{BASESCALING} * $ints_n[$o]->{start};
					$ints_n[$o]->{STOPF} = $connAreaF_0 + $args{BASESCALING} * $ints_n[$o]->{end};

					foreach my $startInterval (@ints_0) {

						my $conn = {
							CHRO1 => $startInterval->{reference_name},
							start1 => $startInterval->{STARTF},
							stop1 => $startInterval->{STOPF},
							TYPE1 => $startInterval->{variant_type},
							CHRO2 => $ints_n[$o]->{reference_name},
							start2 => $ints_n[$o]->{STARTF},
							stop2 => $ints_n[$o]->{STOPF},
							TYPE2 => $ints_n[$o]->{variant_type},
						};
						foreach (1, 2) {
						if ($conn->{ 'TYPE'.$_ } eq 'T') {
							$conn->{ 'COLOR'.$_ } = hex2rgb($args{pgV}->{plot_break_color_hex}) }
			            elsif ($conn->{ 'TYPE'.$_ } eq 'DUP') {
							$conn->{ 'COLOR'.$_ } = hex2rgb($args{pgV}->{plot_gain_color_hex}) }
			            elsif ($conn->{ 'TYPE'.$_ } eq 'DEL') {
							$conn->{ 'COLOR'.$_ } = hex2rgb($args{pgV}->{plot_loss_color_hex}) }
			            else {
			              	$conn->{ 'COLOR'.$_ } = hex2rgb('#dddddd') }
						}
						push @connections, $conn;
					}
				}
				$connAreaF_0 += $connAreaF + $args{CHROGAPF};
			}
		}
		$areaF_0 += $areaF + $args{CHROGAPF};

	}

  ##############################################################################
#_d(@{ $conn }{ qw(CHRO1 start1 stop1 COLOR1 CHRO2 start2 stop2 COLOR2) });

	if ($#connections < $args{MAXCONN}) {

		foreach (shuffle @connections) {
			foreach my $site (1,2) {
				foreach my $where (qw(start stop)) {
					(
						$_->{ $where.$site.'x' },
						$_->{ $where.$site.'y' },
						$_->{ $where.'Rad'.$site },
						$_->{ $where.'Deg'.$site },
					) = pgCirclePoint(
											%args,
											RADIUS => $args{RADIUS},
											CIRCF => $_->{ $where.$site },
										);

					$_->{'bez'.$where.$site.'x'} = sprintf "%.1f", $args{CENTERX} + cos( $_->{ $where.'Rad'.$site } ) * $args{RADIUS} * $args{CONNBEZRAD};
					$_->{'bez'.$where.$site.'y'} = sprintf "%.1f", $args{CENTERY} + sin( $_->{ $where.'Rad'.$site } ) * $args{RADIUS} * $args{CONNBEZRAD};

				}

				# won't be needed unless only few chromosomes are selected,
				# with one being > 50% of all combined and having a near full change
				# but since it is possible ...
				$_->{ 'largeArc'.$site } = $_->{ 'stopDeg'.$site } - $_->{ 'startDeg'.$site } > 180 ? 1 : 0;

			}

			$_->{COLOR1} ||= '127,127,127';
			$_->{COLOR2} ||= '127,127,127';

			my $fill = 'rgb('.$_->{COLOR1}.')';

			if ($_->{COLOR1} ne $_->{COLOR2}) { $fill = 'rgb(111,178,127)' }
			my $conn = <<END;
<path d="
	M $_->{start1x},$_->{start1y}
	C $_->{bezstart1x},$_->{bezstart1y} $_->{bezstart2x},$_->{bezstart2y} $_->{start2x},$_->{start2y}
	A $args{RADIUS},$args{RADIUS} 0 0,$_->{largeArc2} $_->{stop2x},$_->{stop2y}
	C $_->{bezstop2x},$_->{bezstop2y} $_->{bezstop1x},$_->{bezstop1y} $_->{stop1x},$_->{stop1y}
	A $args{RADIUS},$args{RADIUS} 0 0,$_->{largeArc1} $_->{start1x},$_->{start1y}
Z" style="stroke-width: 0.0;  fill: $fill; opacity: $args{CONNOPACITY};" />
END

			$args{PO}->{$ind++} = {
				TYPE => 'verbatim',
				VALUE => $conn,
			};

}}}

################################################################################

sub circleObjectAddArea {

	my %args = @_;
	my $areaF_0 = $args{STARTF};
	my $ind = max(keys %{ $args{PO} }) + 1;

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {
		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});
		$args{PO}->{$ind++} = {
			TYPE => 'verbatim',
			VALUE => pgSVGpie(
				%args,
				RADIUSI => $args{PLOTAREAR} - $args{PLOTAREAH},
				RADIUSO => $args{PLOTAREAR},
				PIESTARTF => $areaF_0,
				PIESTOPF => $areaF_0 + $areaF,
				STYLE => 'fill: '.$args{pgV}->{plot_areacolor_hex},
			),
		};

		# moving along the circle to the next plot area
		$areaF_0		+= $areaF + $args{CHROGAPF};

	}

}

################################################################################

sub circleObjectAddGenes {

	my %args = @_;

	my $areaF_0 = $args{STARTF};
	my $ind = max(keys %{ $args{PO} }) + 1;

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {

		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});
		my $geneRad = $args{RADIUS};
		my $geneCounter = 0;
		my $genes_r = [ grep{ $_->{CHRO} eq $plot_region->{CHRO} } @{ $args{GENES} } ];
		$genes_r = [ grep{ $_->{BASESTOP} >= $plot_region->{BASESTART} } @{ $genes_r } ];
		$genes_r = [ grep{ $_->{BASESTART} <= $plot_region->{BASESTOP} } @{ $genes_r } ];

		# randomized HEX color map

		my @colors = map {
			uc('#'.(join '',
				map {
					sprintf "%02x", (75+rand(175))
				} (0..2)))
		} (0..(scalar(@{ $genes_r })-1));

		for my $i (0..$#{ $genes_r }) { $samples->[$i]->{COLOR} = shift @colors }

		# gene area background
		$args{PO}->{$ind++} = {
			TYPE => 'verbatim',
			VALUE => pgSVGpie(
				%args,
				RADIUSI => $args{RADIUS} - $args{GENEAREAH} * 2,
				RADIUSO => $args{RADIUS},
				PIESTARTF => $areaF_0,
				PIESTOPF => $areaF_0 + $areaF,
				STYLE => 'fill: #fffcec; fill-opacity: 0.8;',
			),
		};

		foreach my $gene (sort { {$a}->{BASESTART} <=> {$b}->{BASESTART}} @{ $genes_r } ) {

			my $geneStartBase = $gene->{BASESTART} < $plot_region->{BASESTART} ? $plot_region->{BASESTART} : $gene->{BASESTART};
			my $geneStopBase = $gene->{BASESTOP} > $plot_region->{BASESTOP} ? $plot_region->{BASESTOP} : $gene->{BASESTOP};
			my $geneStartF = $areaF_0 + $args{BASESCALING} * ($geneStartBase - $plot_region->{BASESTART});
			my $geneStopF = $areaF_0 + $args{BASESCALING} * ($geneStopBase - $plot_region->{BASESTART});

			$args{PO}->{$ind++} = {
				TYPE => 'verbatim',
				VALUE => pgSVGpie(
					%args,
					LINK => $args{pgP}->{UCSClink}.'chr'.$gene->{CHRO}.'%3A'.$gene->{BASESTART}.'-'.$gene->{BASESTOP},
					LINKSHOW => 'new',
					LINKLAB => $gene->{gene_symbol}.' at chr'.$gene->{CHRO}.':'.$gene->{BASESTART}.'-'.$gene->{BASESTOP},
					RADIUSI => $geneRad - $args{GENEAREAH},
					RADIUSO => $geneRad,
					PIESTARTF => $geneStartF,
					PIESTOPF => $geneStopF,
					STYLE => 'fill: '.$gene->{COLOR}.'; fill-opacity: 0.5;',
				),
			};

			# genes are staggered on one of two lines
			$geneRad -= $args{GENEAREAH};
			$geneCounter++;
			if ($geneCounter =~ /(0|2|4|6|8)$/) {
				$geneRad = $args{RADIUS} }
		}

		# moving along the circle to the next plot area
		$areaF_0 += $areaF + $args{CHROGAPF};

	}

}

################################################################################

sub circleObjectAddGridY {

	my %args = @_;

	push(@{ $args{LABY} }, grep{ $_ != 0 } apply { $_ = '-'.$_ } @{ $args{LABY} });

	my $areaF_0 = $args{STARTF};
	my $ind = max(keys %{ $args{PO} }) + 1;

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {
		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});
		foreach (uniq(@{ $args{LABY} })) {
			my $labRad = sprintf "%.1f", $args{PLOTZEROR} + $_ * $args{PIXYFAC};
			if (
				$labRad < $args{PLOTAREAR}
				&&
				$labRad > ($args{PLOTAREAR} - $args{PLOTAREAH})
			) {
	   			$args{PO}->{$ind++} = {
  					TYPE => 'verbatim',
  					VALUE => pgSVGpie(
						%args,
						RADIUSI => $labRad-0.5,
						RADIUSO => $labRad+0.5,
						PIESTARTF => ($areaF_0 + $args{BASESCALING} *  $plot_region->{BASESTART}),
						PIESTOPF => ($areaF_0 + $args{BASESCALING} *  $plot_region->{BASESTOP}),
						STYLE => 'fill: '.($_ == 0 ? '#99ffdd' : '#ffffff'),
					),
	  			};
			}
		}
		# moving along the circle to the next plot area
		$areaF_0 += $areaF + $args{CHROGAPF};
	}

}

################################################################################

sub circleObjectAddHistogram {

	my %args = @_;

	my $areaF_0 = $args{STARTF};
	my $ind = max(keys %{ $args{PO} }) + 1;

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {
		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});
		my @intervalIndex = grep{
			$args{INTERVALS}->[$_]->{CHRO} eq $plot_region->{CHRO}
			&&
			$args{INTERVALS}->[$_]->{SEGSTOP}  >= $plot_region->{BASESTART}
			&&
			$args{INTERVALS}->[$_]->{SEGSTART} <= $plot_region->{BASESTOP}
		} 0..$#{ $args{INTERVALS} };

		# for the histogram, the arc for the histogram baseline is calculated; then, all intervals
		# are added as path points for the interval mid points, from the baseline +/- percent value
		my ( $chroArcX_0, $chroArcY_0 ) = pgCirclePoint(
			%args,
			RADIUS => $args{PLOTZEROR},
			CIRCF => $areaF_0,
		);

		my ( $chroArcX_n, $chroArcY_n ) = pgCirclePoint(
			%args,
			RADIUS => $args{PLOTZEROR},
			CIRCF => $areaF_0 + $areaF,
		);

		foreach my $GL (qw(dupfrequencies delfrequencies)) {
			my @gfvalues = map{ $args{INTF}->{ $GL }->[$_] } @intervalIndex;
			if (any { $_ > 0 } @gfvalues) {
				my $largeArc = $areaF > 0.5 ? 1 : 0;
				my $fillColor = type2hexC(%args, TYPE => $GL);

				# exception is made for single case circles
				if (scalar @{ $args{SAMPLES} } == 1) {
					foreach my $i (@intervalIndex) {
						my $cnF = $args{INTF}->{ $GL }->[$i];
						if ($cnF != 0) {
							$args{PO}->{$ind++} = {
								TYPE => 'verbatim',
								VALUE => pgSVGpie(
									%args,
									RADIUSI => $args{PLOTAREAR} - $args{PLOTAREAH},
									RADIUSO => $args{PLOTAREAR},
									PIESTARTF => ($areaF_0 + $args{BASESCALING} * $args{INTERVALS}->[$i]->{SEGSTART}),
									PIESTOPF => ($areaF_0 + $args{BASESCALING} * $args{INTERVALS}->[$i]->{SEGSTOP}),
									STYLE => 'fill: '.$fillColor.';',
								),
							};

						}
					}
				} else {

					my $histoSVG = '
	<path d=" ';
					$histoSVG .= join(' ' ,
						'M',
						$chroArcX_n,
						$chroArcY_n,
						'A',
						$args{PLOTZEROR},
						$args{PLOTZEROR},
						'0',
						$largeArc,
						'0',
						$chroArcX_0,
						$chroArcY_0,
						'L ',
					);

					foreach my $i (@intervalIndex) {
						my $cnF = $args{INTF}->{ $GL }->[$i];
						if ($GL =~ /del/i) { $cnF *= -1 }
						my $segHeight = $cnF / 2 * $args{PLOTAREAH} / 100;
						if ($GL =~ /LOSS/i) {$segHeight = -$segHeight}
						my ( $segX, $segY ) = pgCirclePoint(
							%args,
							RADIUS => $args{PLOTZEROR} + $segHeight,
							CIRCF => $areaF_0 + $args{BASESCALING} * ($args{INTERVALS}->[$i]->{SEGSTOP} + $args{INTERVALS}->[$i]->{SEGSTART}) / 2,
						);
						$histoSVG .= $segX.' '.$segY.' ';
					}

					$histoSVG .= '
		Z" style="stroke-width: 0.0;  fill: '.$fillColor.';" />';
 					$args{PO}->{$ind++} = {TYPE => 'verbatim', VALUE => $histoSVG};
				}
			}
		}
		# moving along the circle to the next plot area
		$areaF_0	+= $areaF + $args{CHROGAPF};
	}

}

################################################################################

sub circleObjectAddIdeogram {

	my %args = @_;

	my $areaF_0 = $args{STARTF};
	my $ind = max(keys %{ $args{PO} }) + 1;
	$args{RADIUS} -= $args{FONTPX};

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {
		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});
		my $labelF = $areaF_0 + $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART}) / 2;
		my ($X, $Y, $rad, $deg) = pgCirclePoint(
			%args,
			RADIUS => $args{RADIUS},
			CIRCF => $labelF,
		);

 		# the rotation for the chromosome labels is calculated, making them aligned along the circle
		# with the bottom facing the circle's center
		$deg += 90;

		$args{PO}->{$ind++} = {
			TYPE => 'verbatim',
			VALUE => '
	<text x="'.$X.'" y="'.$Y.'"
		style="text-anchor: middle; font-size: '.$args{FONTPX}.'px; fill: '.$args{FONTCOL}.';"
		transform="rotate('.$deg.' '.$X.' '.$Y.')">
		'.$plot_region->{CHRO}.'
	</text>',
		};
		$areaF_0 += $areaF + $args{CHROGAPF};
	}

	# ideogram ####################################################################

	$args{RADIUS} -= $args{FONTPX};
	$areaF_0 = $args{STARTF};

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {

		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});
		my $currAreaStopF = $areaF_0 + $areaF;

		# cytobands

		# elaborate workaround: the last band, which is narrower than the one before, would be
		# drawn over the previous one, giving some strange artefact due to rounding etc.
		# so, we move it to the back
		my @chroBands = @{ _sortedBands(%args, CHROS => [ $plot_region->{CHRO} ]) };
		my $lastband = pop(@chroBands);
		@chroBands = ($lastband, @chroBands);
		my $qter = _qter(%args, CHRO => $plot_region->{CHRO});

		foreach my $cytoBand (@chroBands) {

			next if (
				($args{CYTOBANDS}->{ $cytoBand }->{BASESTART} > $plot_region->{BASESTOP})
				||
				($args{CYTOBANDS}->{ $cytoBand }->{BASESTOP} < $plot_region->{BASESTART})
			);

			my $cbPlotStartBase = $args{CYTOBANDS}->{ $cytoBand }->{BASESTART} < $plot_region->{BASESTART} ? $plot_region->{BASESTART} : $args{CYTOBANDS}->{ $cytoBand }->{BASESTART};
			my $cbPlotStopBase = $args{CYTOBANDS}->{ $cytoBand }->{BASESTOP} > $plot_region->{BASESTOP} ? $plot_region->{BASESTOP} : $args{CYTOBANDS}->{ $cytoBand }->{BASESTOP};

			my $cbPlotStartF = $areaF_0 + $args{BASESCALING} * ($cbPlotStartBase - $plot_region->{BASESTART});
			my $cbPlotStopF = $areaF_0 + $args{BASESCALING} * ($cbPlotStopBase - $plot_region->{BASESTART});

			# circ_radius valus are saved in separate variables, to be changed for centromers etc.

			my $bandStartRad = $args{RADIUS};
			my $bandStopRad = $args{RADIUS} - $args{CHROW};

			if (
				$args{CYTOBANDS}->{ $cytoBand }->{STAINING} =~ /cen/i
				||
				$args{CYTOBANDS}->{ $cytoBand }->{BASESTOP} >= ($qter - 1)
				||
				$args{CYTOBANDS}->{ $cytoBand }->{BASESTART} == 0
			) {
				$bandStartRad		-= 1;
				$bandStopRad		+= 1;
			}

			if (
				$args{CYTOBANDS}->{ $cytoBand }->{STAINING} =~ /stalk/i
			) {
				$bandStartRad		-= 2;
				$bandStopRad		+= 2;
			}

      		my $staining = staining2hex($args{CYTOBANDS}->{$cytoBand}->{STAINING});

  			$args{PO}->{$ind++} = {
				TYPE => 'verbatim',
				VALUE => pgSVGpie(
					%args,
					RADIUSI => $bandStopRad,
					RADIUSO => $bandStartRad,
					PIESTARTF => $cbPlotStartF,
					PIESTOPF => $cbPlotStopF,
					STYLE => 'fill: '.$staining.';',
					TOOLTIP => $cytoBand.': '.$args{CYTOBANDS}->{ $cytoBand }->{BASESTART}.' - '.$args{CYTOBANDS}->{ $cytoBand }->{BASESTOP},
				)
			};

		# adding a band label if there is enough space
 			if (
 				($cbPlotStopF - $cbPlotStartF) > 0.03
 				&&
 				$args{CYTOBANDS}->{ $cytoBand }->{STAINING} !~ /(stalk)|(cen)/i
 			) {
				my $labelF = ($cbPlotStopF + $cbPlotStartF) / 2;
				my ($X, $Y, $rad, $deg) = pgCirclePoint(
					%args,
					RADIUS => $args{RADIUS} - $args{FONTPX} - 4,
					CIRCF => $labelF,
				);

				# the rotation for the chromosome labels is calculated, making them aligned along the circle
				# with the bottom facing the circle's center
				# => should be changed to be along a path ...
				if ( $deg > 90 && $deg <270 ) { $deg += 180 }
				$deg = $deg > 180 ? $deg - 90 : $deg + 90;

				$args{PO}->{$ind++} = {
          			TYPE => 'verbatim',
          			VALUE => '
	<text x="'.$X.'" y="'.$Y.'"
		style="text-anchor: middle; font-size: '.$args{FONTPX}.'px; fill: '.($args{CYTOBANDS}->{ $cytoBand }->{STAINING} =~ /neg/ ? '#666666' : '#fff8dc').';"
		transform="rotate('.$deg.' '.$X.' '.$Y.')">
		'.$cytoBand.'
	</text>'
				};
			}
		}

		# since a simple gradient assignment does seem to have some problems with LibRSVG, it is
		# faked by overlaying the chromosomes with semi-transparent circle segments
		$args{PO}->{$ind++} = {
			TYPE => 'verbatim',
			VALUE => pgSVGpie(
				%args,
				RADIUSI => $args{RADIUS} - $args{CHROW} + 5,
				RADIUSO => $args{RADIUS} - 5,
				PIESTARTF => $areaF_0,
				PIESTOPF => $currAreaStopF,
				STYLE => 'fill: rgb(255,255,255); fill-opacity: 0.2',
			)
		};

		$args{PO}->{$ind++} = {
			TYPE => 'verbatim',
			VALUE => pgSVGpie(
				%args,
				RADIUSI => $args{RADIUS} - $args{CHROW} + 7,
				RADIUSO => $args{RADIUS} - 7,
				PIESTARTF => $areaF_0,
				PIESTOPF => $currAreaStopF,
				STYLE => 'fill: rgb(255,255,255); fill-opacity: 0.2',
			)
		};

		$args{PO}->{$ind++} = {
			TYPE => 'verbatim',
			VALUE => pgSVGpie(
				%args,
				RADIUSI => $args{RADIUS} - $args{CHROW} + 8,
				RADIUSO => $args{RADIUS} - 7,
				PIESTARTF => $areaF_0,
				PIESTOPF => $currAreaStopF,
				STYLE => 'fill: rgb(255,255,255); fill-opacity: 0.2',
	        )
		};
		# moving along the circle to the next plot area
		$areaF_0 += $areaF + $args{CHROGAPF};
	}
}

################################################################################

sub circleObjectAddLabelsY {

	my %args = @_;

	push(@{ $args{LABY} }, grep{ $_ != 0 } apply { $_ = '-'.$_ } @{ $args{LABY} });

	foreach (uniq(@{ $args{LABY} })) {

		my $labRad = sprintf "%.1f", $args{PLOTZEROR} + $_ * $args{PIXYFAC};

		if (
			$labRad < $args{PLOTAREAR}
			&&
			$labRad > ($args{PLOTAREAR} - $args{PLOTAREAH})
		) {
			my ($X, $Y, $rad, $deg) = pgCirclePoint(
				CENTERX => $args{CENTERX},
				CENTERY => $args{CENTERY},
				RADIUS => $labRad,
				CIRCF => $args{ROTATIONF}
			);

			$args{PO}->{$ind++} = {
				TYPE => 'text',
				X => $X,
				Y => $Y + $args{FONTPX} / 2 - 2,
				VALUE => ($args{PLOTT} =~ /array/i ? $_ : abs($_)).$args{PLOTUNIT},
				STYLE => 'text-anchor: middle; font-size: '.$args{FONTPX}.'px; fill: #666666;'
			};

}}}

################################################################################

sub circleObjectAddMarkers {

	my %args = @_;

	my $areaF_0 = $args{STARTF};

	my $ind = max(keys %{ $args{PO} }) + 1;
	my $backind = 10;

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {

		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});

		my @regMarks = grep{ $_->{CHRO} eq $plot_region->{CHRO} } @{ $args{REGMARKS} };
		@regMarks = grep{ $_->{BASESTOP} >= $plot_region->{BASESTART} } @regMarks;
		@regMarks = grep{ $_->{BASESTART} <= $plot_region->{BASESTOP} } @regMarks;

		foreach $regMark (@regMarks) {

			my $regMarkStartBase = $regMark->{BASESTART} < $plot_region->{BASESTART} ? $plot_region->{BASESTART} : $regMark->{BASESTART};
			my $regMarkStopBase = $regMark->{BASESTOP} > $plot_region->{BASESTOP} ? $plot_region->{BASESTOP} : $regMark->{BASESTOP};
			my $regMarkStartF = $areaF_0 + $args{BASESCALING} * ($regMarkStartBase - $plot_region->{BASESTART});
			my $regMarkStopF = $areaF_0 + $args{BASESCALING} * ($regMarkStopBase - $plot_region->{BASESTART});

 			$args{PO}->{ $backind++ } = {
				TYPE => 'verbatim',
				VALUE => pgSVGpie(
					%args,
					RADIUSI => $args{RADIUS} - 2,
					RADIUSO => $args{IDEORAD} + 2,
					PIESTARTF => $regMarkStartF,
					PIESTOPF => $regMarkStopF,
					STYLE => 'fill: rgb(255,0,0); fill-opacity: 0.2; stroke:rgb(255,0,0); stroke-width: 0.5px; stroke-opacity: 0.5;',
		      	)
			};

 			$args{PO}->{$ind++} = {
				TYPE => 'verbatim',
				VALUE => pgSVGpie(
					%args,
					RADIUSI => $args{RADIUS} - 2,
					RADIUSO => $args{IDEORAD} + 2,
					PIESTARTF => $regMarkStartF,
					PIESTOPF => $regMarkStopF,
					STYLE => 'fill: rgb(255,0,0); fill-opacity: 0.2; stroke:rgb(255,0,0); stroke-width: 0.5px; stroke-opacity: 0.5;',
				)
			};
		}

		# moving along the circle to the next plot area
		$areaF_0	+= $areaF + $args{CHROGAPF};

	}
}

################################################################################

sub circleObjectAddProbes {

	my %args = @_;

	my $areaF_0 = $args{STARTF};

	my $ind = max(keys %{ $args{PO} }) + 1;

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {

		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});
		my @currentProbes = grep{ $_->{CHRO} eq $plot_region->{CHRO} } @{ $args{PROBES} };
		@currentProbes = grep{ $_->{BASEPOS} <= $plot_region->{BASESTOP} } @currentProbes;
		@currentProbes = grep{ $_->{BASEPOS} >= $plot_region->{BASESTART} } @currentProbes;

		foreach (@currentProbes) {
			my $probeF = $areaF_0 + $args{BASESCALING} * ($_->{BASEPOS} - $plot_region->{BASESTART});
			my $probeRad = sprintf "%.1f", $args{PLOTZEROR} + ($_->{VALUE} + $args{BASECORR}) * $args{PIXYFAC};
			my ($dotX, $dotY, $rad, $deg) = pgCirclePoint(
				%args,
				RADIUS => $probeRad,
				CIRCF => $probeF,
			);
			$args{PO}->{$ind++} = {
				LINK => (scalar(@currentProbes) < 2000 ? $args{pgP}->{UCSClink}.'chr'.$chro.'%3A'.($_->{BASEPOS} - 999).'-'.($_->{BASEPOS} + 1000) : q{}),
				LINKLAB => (scalar(@currentProbes) < 2000 ? $_->{BASEPOS} : q{}),
				LINKSHOW => 'new',
				TYPE => 'verbatim',
				VALUE => '<circle cx="'.$dotX.'" cy="'.$dotY.'" r="'.$dotR.'" />',
			};
		}
		# moving along the circle to the next plot area
		$areaF_0 += $areaF + $args{CHROGAPF};
	}
}

################################################################################

sub circleObjectAddSegments {

	my %args = @_;

	my $areaF_0 = $args{STARTF};
	my $ind = max(keys %{ $args{PO} }) + 1;

	foreach my $plot_region (@{ $args{PLOTREGIONS} }) {
		my $areaF = $args{BASESCALING} * ($plot_region->{BASESTOP} - $plot_region->{BASESTART});

		my @segments = grep{ $_->{reference_name} eq $plot_region->{CHRO} } @{ $args{SEGDATA} };
		@segments = grep{ $_->{end} >= $plot_region->{BASESTART} } @segments;
		@segments = grep{ $_->{start} <= $plot_region->{BASESTOP} } @segments;

		foreach $seg (@segments) {
			my $segPlotStartBase = $seg->{start} < $plot_region->{BASESTART} ? $plot_region->{BASESTART} : $seg->{start};
			my $segPlotStopBase = $seg->{end} > $plot_region->{BASESTOP} ? $plot_region->{BASESTOP} : $seg->{end};
			my $segPlotStartF = $areaF_0 + $args{BASESCALING} * ($segPlotStartBase - $plot_region->{BASESTART});
			my $segPlotStopF = $areaF_0 + $args{BASESCALING} * ($segPlotStopBase - $plot_region->{BASESTART});
			my $segPlotRad = sprintf "%.1f", $args{PLOTZEROR} + ($seg->{info}->{value} + $args{BASECORR}) * $args{PIXYFAC};
 			$args{PO}->{$ind++} = {
				TYPE => 'verbatim',
				VALUE => pgSVGpie(
					%args,
					LINK => $args{pgP}->{UCSClink}.'chr'.$seg->{reference_name}.'%3A'.$seg->{start}.'-'.$seg->{end},
					LINKSHOW => 'new',
					LINKLAB => $seg->{info}->{value}.($args{BASECORR} !~ 0 ? ' (corrected by '.$args{BASECORR}.' for plotting)' : q{}).' at chr'.$chro.':'.$seg->{start}.'-'.$seg->{end},
					RADIUSI => $segPlotRad - 1,
					RADIUSO => $segPlotRad + 1,
					PIESTARTF => $segPlotStartF,
					PIESTOPF => $segPlotStopF,
					CLASS => ($seg->{info}->{value} + $args{BASECORR} > 0 ? 'gb' : 'lb'),
				),
			};
		}
		# moving along the circle to the next plot area
		$areaF_0 += $areaF + $args{CHROGAPF};
	}
}

################################################################################

1;
