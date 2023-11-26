use CGI qw(param multi_param);

################################################################################

sub pgReadParam {

  my %args = @_;

  foreach my $key (param()) {

    my $pgVkey = lc($key);

    if ($key =~ /_m$/) {

      # list style form fields have the tag "_m" and are stored in list context
      # additionally, comma-concatenated values are split

      $args{pgV}->{$pgVkey} = [ map{ split(/(<hr\/?>)|\n|\r|(<li?\/?>)/, $_) } param($key) ];

      # removal of everything (i.e. subsettext ...) following a square bracket is based on the
      # collection of multiple ICD etc. values in a common text area using the menu style
      # pop-up selector
      # now
      if ( grep( /$key/,  qw(icdm_m icdt_m pmid_m platform_m text_m) ) ) {
        $args{pgV}->{$pgVkey}   =   [ apply{ $_ =~ s/(\w+?) ?\[.*?$/$1/ } @{ $args{pgV}->{$key} } ] }

      # lists values are comma-separated when from a text field => split ','
      # but in geo_m there are city, country, continent => skip splitting
      if ($key !~ /geo_m/ ) {
        $args{pgV}->{$pgVkey}   =   [ uniq(map{ split(',', $_) } @{ $args{pgV}->{$key} }) ] }

    } else {

      $args{pgV}->{$pgVkey}     =   param($key);

  }}

  return $args{pgV};

}


1;
