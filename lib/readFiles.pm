use LWP::UserAgent;
use LWP::Simple;

################################################################################

sub pgWebFile2list {
	my $dlLink = $_[0];

	# Dropbox fix...
  	if ($dlLink =~ /dropbox\.com/) {
  		$dlLink =~ s/(\?dl=\w)?$/?dl=1/ }

	$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
	my $ua = new LWP::UserAgent;
	$ua->agent("Mozilla/8.0");
	my $req = new HTTP::Request 'GET' => $dlLink;
	$req->header('Accept' => 'text/plain');
	my $res = $ua->request($req);
	my @filecontent = split("\n", $res->{_content});
	chomp	@filecontent;
	return	\@filecontent;
}

################################################################################

sub pgFile2list {
	my $file = $_[0];
	my @filecontent = split(/\r\n?|\n/, pgFile2string($file));
	chomp @filecontent;
	return \@filecontent;
}

################################################################################

sub pgFile2string {
	my $file = $_[0];
  	my $fContent = q{};
  	my $fError = "";
	open FILE, $file or die "No file $file $!";
	local $/;												# no input separator
	$fContent = <FILE>;
    close FILE;
	return $fContent;
}

################################################################################

1;
