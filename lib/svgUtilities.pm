sub plotSVGfromCoordinates {

	my %args				=	@_;
	my $svgcode				=	'<svg
	xmlns="http://www.w3.org/2000/svg"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	version="1.1"
	id="'.$args{ID}.'"
	onload="init(evt)"
	height="'.$args{IMGH}.'px"
	width="'.$args{IMGW}.'px"
	style="margin: auto; font-family: Helvetica, sans-serif;">

<defs>
'.$args{DEFS}.'
<style type="text/css">
<![CDATA['.$args{CSS}.']]>
</style>
</defs>';

	foreach my $plotKey ( grep{ $args{PO}->{ $_ }->{TYPE} =~ /.../ } sort { $a <=> $b } keys %{ $args{PO} }) {
		my $plotItem;

		# the plot types "link" and "linkend" are used to wrap multiple items, so they have to be excluded
		# from the standard item processing

		if ($args{PO}->{ $plotKey }->{TYPE} eq 'verbatim') {
			$plotItem =	$args{PO}->{ $plotKey }->{VALUE};

		} else {

			if ($args{PO}->{ $plotKey }->{TYPE} !~ /link/) {
				$plotItem = '<'.$args{PO}->{ $plotKey }->{TYPE};

				if (defined($args{PO}->{ $plotKey }->{X}) && $args{PO}->{ $plotKey }->{X} =~ /\d/)		{ $plotItem .= ' x="'.$args{PO}->{ $plotKey }->{X}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{CX}) && $args{PO}->{ $plotKey }->{CX} =~ /\d/)	{ $plotItem .= ' cx="'.$args{PO}->{ $plotKey }->{CX}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{Y}) && $args{PO}->{ $plotKey }->{Y} =~ /\d/)		{ $plotItem .= ' y="'.$args{PO}->{ $plotKey }->{Y}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{CY}) && $args{PO}->{ $plotKey }->{CY} =~ /\d/)	{ $plotItem .= ' cy="'.$args{PO}->{ $plotKey }->{CY}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{X1}) && $args{PO}->{ $plotKey }->{X1} =~ /\d/)	{ $plotItem .= ' x1="'.$args{PO}->{ $plotKey }->{X1}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{Y1}) && $args{PO}->{ $plotKey }->{Y1} =~ /\d/)	{ $plotItem .= ' y1="'.$args{PO}->{ $plotKey }->{Y1}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{X2}) && $args{PO}->{ $plotKey }->{X2} =~ /\d/)	{ $plotItem .= ' x2="'.$args{PO}->{ $plotKey }->{X2}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{Y2}) && $args{PO}->{ $plotKey }->{Y2} =~ /\d/)	{ $plotItem .= ' y2="'.$args{PO}->{ $plotKey }->{Y2}.'" ' };
				if (defined($args{PO}->{ $plotKey }->{W}) && $args{PO}->{ $plotKey }->{W} =~ /\d/)		{ $plotItem .= ' width="'.$args{PO}->{ $plotKey }->{W}.'" '};
				if (defined($args{PO}->{ $plotKey }->{H}) && $args{PO}->{ $plotKey }->{H} =~ /\d/) 		{ $plotItem .= ' height="'.$args{PO}->{ $plotKey }->{H}.'" '};
				if (defined($args{PO}->{ $plotKey }->{RX}) && $args{PO}->{ $plotKey }->{RX} =~ /\d/)	{ $plotItem .= ' rx="'.$args{PO}->{ $plotKey }->{RX}.'" '};
				if (defined($args{PO}->{ $plotKey }->{RY}) && $args{PO}->{ $plotKey }->{RY} =~ /\d/)	{ $plotItem .= ' ry="'.$args{PO}->{ $plotKey }->{RY}.'" '};
				if (defined($args{PO}->{ $plotKey }->{RADIUS}) && $args{PO}->{ $plotKey }->{RADIUS} =~ /\d/)	{ $plotItem .= ' r="'.$args{PO}->{ $plotKey }->{RADIUS}.'" '};
				if (defined($args{PO}->{ $plotKey }->{FILL}))		{ $plotItem .= ' fill="'.$args{PO}->{ $plotKey }->{FILL}.'" '};
				if (defined($args{PO}->{ $plotKey }->{STYLE}))		{ $plotItem .= ' style="'.$args{PO}->{ $plotKey }->{STYLE}.'" '};
				if (defined($args{PO}->{ $plotKey }->{CLASS}))		{ $plotItem .= ' class="'.$args{PO}->{ $plotKey }->{CLASS}.'" '};
				if (defined($args{PO}->{ $plotKey }->{TRANSFORM}))	{ $plotItem .= ' transform="'.$args{PO}->{ $plotKey }->{TRANSFORM}.'" '};
				if (defined($args{PO}->{ $plotKey }->{HREF}))		{ $plotItem .= ' xlink:href="'.$args{PO}->{ $plotKey }->{HREF}.'" '};
				if (defined($args{PO}->{ $plotKey }->{TOOLTIP}))	{ $plotItem .= ' onmousemove="ShowTooltip(evt, '."'".$args{PO}->{ $plotKey }->{TOOLTIP}."'".')" onmouseout="HideTooltip(evt)" '};

				if ($args{PO}->{ $plotKey }->{TYPE} =~ /line|rect/) {
					$plotItem .= ' />' }
				else {
					$plotItem .=	'>';
					$plotItem .=	$args{PO}->{ $plotKey }->{VALUE} =~ /./ ? $args{PO}->{ $plotKey }->{VALUE} : q{};
					$plotItem .=	'</'.$args{PO}->{ $plotKey }->{TYPE}.'>';
				}
			}
		}

		my $linkCode = q{};

		if ($args{PO}->{ $plotKey }->{LINK}) {
			$linkCode = '<a
xlink:href="'.$args{PO}->{ $plotKey }->{LINK}.'"';
			$linkCode .= $args{PO}->{ $plotKey }->{LINKSHOW} =~ /new/i ? '
xlink:show="new"' : q{};
			$linkCode .= $args{PO}->{ $plotKey }->{LINKLAB} =~ /\w/ ? '
xlink:title="'.$args{PO}->{ $plotKey }->{LINKLAB}.'"' : q{};
			$plotItem = $linkCode.'>
'.$plotItem;

			# a link closure is inserted if the item had link code but is not of the "link" type
			if ($args{PO}->{ $plotKey }->{TYPE} !~ /link/) {
				$plotItem .= '</a>';
			}
		}

		# a link closure is inserted if the item is of the "linkend" type
		if ($args{PO}->{ $plotKey }->{TYPE} =~ /linkend/) {
			$plotItem .= '</a>';
		}
		$svgcode .= "\n".$plotItem;
	}
	$svgcode .= '
</svg>';

	return	$svgcode;
}

################################################################################

sub cytobandSVGgradients {

	my %args =	@_;

	$args{ID} ||=	q{};

	return <<END;
<linearGradient id="$args{ID}gpos100" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="rgb(39,39,39)" />
	<stop offset="100%" stop-color="rgb(0,0,0)" />
</linearGradient>
<linearGradient id="$args{ID}gpos75" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="rgb(87,87,87)" />
	<stop offset="100%" stop-color="rgb(39,39,39)" />
</linearGradient>
<linearGradient id="$args{ID}gpos50" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="rgb(196,196,196)" />
	<stop offset="100%" stop-color="rgb(111,111,111)" />
</linearGradient>
<linearGradient id="$args{ID}gpos25" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="rgb(223,223,223)" />
	<stop offset="100%" stop-color="rgb(196,196,196)" />
</linearGradient>
<linearGradient id="$args{ID}gneg" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="white" />
	<stop offset="100%" stop-color="rgb(223,223,223)" />
</linearGradient>
<linearGradient id="$args{ID}gvar" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="rgb(196,196,196)" />
	<stop offset="100%" stop-color="rgb(111,111,111)" />
</linearGradient>
<linearGradient id="$args{ID}stalk" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="rgb(39,39,39)" />
	<stop offset="100%" stop-color="rgb(0,0,0)" />
</linearGradient>
<linearGradient id="$args{ID}acen" x1="0%" x2="80%" y1="0%" y2="0%" spreadMethod="reflect">
	<stop offset="0%" stop-color="rgb(163,55,247)" />
	<stop offset="100%" stop-color="rgb(138,43,226)" />
</linearGradient>
END

}

################################################################################

sub cytobandSVGgradientsVertical {

	my %args = @_;

	$args{ID} ||= q{};

	return '
<linearGradient id="'.$args{ID}.'gpos100" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="rgb(39,39,39)" />
		<stop offset="100%" stop-color="rgb(0,0,0)" />
</linearGradient>
<linearGradient id="'.$args{ID}.'gpos75" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="rgb(87,87,87)" />
		<stop offset="100%" stop-color="rgb(39,39,39)" />
</linearGradient>
<linearGradient id="'.$args{ID}.'gpos50" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="rgb(196,196,196)" />
		<stop offset="100%" stop-color="rgb(111,111,111)" />
</linearGradient>
<linearGradient id="'.$args{ID}.'gpos25" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="rgb(223,223,223)" />
		<stop offset="100%" stop-color="rgb(196,196,196)" />
</linearGradient>
<linearGradient id="'.$args{ID}.'gneg" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="white" />
		<stop offset="100%" stop-color="rgb(223,223,223)" />
</linearGradient>
<linearGradient id="'.$args{ID}.'gvar" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="rgb(196,196,196)" />
		<stop offset="100%" stop-color="rgb(111,111,111)" />
</linearGradient>
<linearGradient id="'.$args{ID}.'stalk" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="rgb(39,39,39)" />
		<stop offset="100%" stop-color="rgb(0,0,0)" />
</linearGradient>
<linearGradient id="'.$args{ID}.'acen" x1="0%" x2="0%" y1="0%" y2="80%" spreadMethod="reflect">
		<stop offset="0%" stop-color="rgb(163,55,247)" />
		<stop offset="100%" stop-color="rgb(138,43,226)" />
</linearGradient>
';
}

################################################################################

sub pgCirclePoint {

	my %args = @_;

	my $pointRad = $args{CIRCF} * 2 * PI;
	my $pointDeg = $args{CIRCF} * 360;

	# returning an array with X, Y, RAD and DEG
	return	(
		(sprintf "%.2f", cos( $pointRad ) * $args{RADIUS} + $args{CENTERX}),
		(sprintf "%.2f", sin( $pointRad ) * $args{RADIUS} + $args{CENTERY}),
		$pointRad,
		$pointDeg
	);

}

################################################################################

sub pgSVGpie {

	my %args = @_;

	$args{RADI} ||=	$args{pgV}->{imgw} / 2;
	$args{RADO} ||=	$args{pgV}->{imgw} / 2 + 20;
	$args{STYLE} ||= '';
	$args{CLASS} ||= '';
  	$args{LINK} ||= '#';

	my $largeArcFlag = $args{PIESTOPF} - $args{PIESTARTF} > 0.5 ? 1 : 0;

	my ( $startXi, $startYi ) =	pgCirclePoint(
		%args,
		RADIUS => $args{RADI},
		CIRCF => $args{PIESTARTF},
	);
	my ( $startXo, $startYo ) =	pgCirclePoint(
		%args,
		RADIUS => $args{RADO},
		CIRCF => $args{PIESTARTF},
	);

	my ( $stopXi, $stopYi ) = pgCirclePoint(
	    %args,
	    RADIUS => $args{RADI},
	    CIRCF => $args{PIESTOPF},
	);
	my ( $stopXo, $stopYo ) = pgCirclePoint(
	    %args,
	    RADIUS => $args{RADO},
	    CIRCF => $args{PIESTOPF},
	);

	my $pie = '
	<a xlink:href="'.$args{LINK}.'" target="_blank">
	<path
		d="'.join(' ',
			'M',
			$startXi,
			$startYi,
			'A',
			$args{RADI},
			$args{RADI},
			'0',
			$largeArcFlag,
			'1',
			$stopXi,
			$stopYi,
			'L',
			$stopXo,
			$stopYo,
			'A',
			$args{RADO},
			$args{RADO},
			'0',
			$largeArcFlag,
			'0',
			$startXo,
			$startYo,
		).'
	Z" '.($args{STYLE} =~ /../ ? 'style="'.$args{STYLE}.'" ' : q{}).($args{CLASS} =~ /../ ? 'class="'.$args{CLASS}.'"' : q{}).($args{TOOLTIP} ? ' onmousemove="ShowTooltip(evt, '."'".$args{TOOLTIP}."'".')" onmouseout="HideTooltip(evt)" ' : q{}).'
	/>
	</a>';

#	_d('###',$pie,'###');
	return	$pie;

}

################################################################################

sub _SVGaddTooltip {

	my $args = shift;
	my $toolX = 20;
	my $toolY = 40;

	return	'
<!--
	The "Tooltip" scripting and definitions was modified (using evt.pageX/Y) from Peter Collingridge
	(http://www.petercollingridge.co.uk/interactive-svg-components/tooltip). Didn t know a bit about
	SVG script embedding before - great example!
-->
	<script type="text/ecmascript">
		<![CDATA[

		function init(evt)
		{
			if ( window.svgDocument == null )
			{
			svgDocument		=	evt.target.ownerDocument;
			}

			tooltip			=	svgDocument.getElementById('."'tooltip'".');
			tooltip_bg	=	svgDocument.getElementById('."'tooltip_bg'".');

		}

		function ShowTooltip(evt, mouseovertext)
		{

			length = tooltip.getComputedTextLength();

			tooltip.setAttributeNS(null,"x",29);
			tooltip.setAttributeNS(null,"y",'.($toolY - 16).');
			tooltip.firstChild.data = mouseovertext;
			tooltip.setAttributeNS(null,"visibility","visible");

			tooltip_bg.setAttributeNS(null,"width",length+8);
			tooltip_bg.setAttributeNS(null,"x",25);
			tooltip_bg.setAttributeNS(null,"y",'.($toolY - 30).');
			tooltip_bg.setAttributeNS(null,"visibility","visible");
		}

		function HideTooltip(evt)
		{
			tooltip.setAttributeNS(null,"visibility","hidden");
			tooltip_bg.setAttributeNS(null,"visibility","hidden");
		}

		]]>
	</script>

<rect style="fill: #99eeff; stroke: none; opacity: 0.9;" id="tooltip_bg" x="0" y="0" rx="4" ry="4" width="80" height="20" visibility="hidden"/>
<text style="font-size: 11px;" id="tooltip" x="0" y="0" visibility="hidden">Tooltip</text>
';

}

################################################################################

sub pgCheckSVG {

	my $svg = $_[0];

	if ($svg =~ /svg>/is ) {
		return $svg }

	return '<svg
	xmlns="http://www.w3.org/2000/svg"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	version="1.1"
	id="array"
	onload="init(evt)"
	height="300"
	width="500px"
	style="margin: auto; font-family: Helvetica, sans-serif;">

<text x="150" y="160" style="font-size: 14; font-weight: 900; fill: #000000;" >no correct SVG data provided</text>

</svg>';

}

1;
