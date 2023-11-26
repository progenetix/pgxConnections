use CGI qw(param multi_param);

################################################################################

sub setDefaults {

  my $defaults = {
    'circ_radius' => 130,
    'circ_node_gaps' => 2,
    'ring_width' => 10,
    'collab' => 1,
    'conn_opacity' => 0.5,
    'connections' => {},
    'fontcol' => '#000000',
    'fontpx' => 15,
    'gapwidth' => 5,
    'imgh' => 620,
    'imgtype' => 'SVG',
    'legendfpx' => 13,
    'legendpos' => 'right',
    'legendsort' => 'size',
    'legend_y_gap' => 0,
    'legendw' => 180,
    'nodes' => {},
    'nodesort' => 'random',
    'plot_bgcolor_hex' => '#ffffff',
    'project' => 'compbiozurich',
    'nodesort' => 'random',
    'transparent' => 'opaque',
  };

  return $defaults;

}

################################################################################

sub pgReadParam {

  my %args = @_;
  foreach my $key (param()) {
    $args{pgV}->{$key} = param($key);
  }

  return $args{pgV};

}


1;
