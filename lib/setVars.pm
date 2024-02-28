use CGI qw(param multi_param);

################################################################################

sub setDefaults {

  my $defaults = {
    'circ_radius' => 110,
    'circ_node_gaps' => 2,
    'ring_width' => 10,
    'collab' => 1,
    'conn_opacity' => 0.5,
    'connections' => {},
    'fontcol' => '#000000',
    'font_size' => 12,
    'gapwidth' => 5,
    'imgh' => 620,
    'legend_font_size' => 13,
    'legend_placement' => 'right',
    'legendsort' => 'size',
    'legend_y_gap' => 0,
    'legend_width' => 180,
    'nodes' => {},
    'nodesort' => 'random',
    'plot_bgcolor_hex' => '#ffffff',
    'nodesort' => 'random',
    'transparent' => 'opaque',
    'connections' => ""
  };

  # files

  $defaults->{nodes} = "";
  $defaults->{connections} = "";

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
