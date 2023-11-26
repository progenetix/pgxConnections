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

sub pgFile2string {

	my %args = @_;

	$args{FILE} ||=	$_[0];
  my $fContent = q{};

	if (! -f $args{FILE}) {
		_d('no file at', $args{FILE});
		return	q{};
	} else {
		open	FILE, "$args{FILE}" or die "No file $args{FILE} $!";
		local $/;															# no input separator
		$fContent = <FILE>;
    close FILE;
  }

  return  $fContent;

}

################################################################################

sub pgSpreadsheet2list {

	my %args = @_;
	$args{FILE} ||= $_[0];

	use	Spreadsheet::Read;
	use	Spreadsheet::XLSX;
  use Spreadsheet::ReadSXC;

	my $book = ReadData($args{FILE});
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
