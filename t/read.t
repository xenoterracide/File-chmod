use strict;
use warnings;
use Test::More;
use English '-no_match_vars';
use File::Temp ();
use File::chmod qw( chmod getmod );
$File::chmod::UMASK = 0;

plan skip_all => "Windows perms work differently" if $OSNAME eq 'MSWin32';

my $tmp = File::Temp->new;
my $fn  = $tmp->filename;
note sprintf "original state of %s: %o\n", $fn, getmod( $fn );

subtest '+/-r' => sub {
	plan skip_all => 'test will not pass as root'
		if $REAL_USER_ID == 0 or $EFFECTIVE_USER_ID == 0;

	ok chmod("+r", $fn ), "chmod +r $fn";
	ok -r $fn, "$fn readable";

	ok chmod("-r", $fn ), "chmod -r $fn";
	ok ! -r $fn, "$fn not readable";

	# test a second time because there's a good chance it was the first
	ok chmod("+r", $fn ), "chmod +r $fn";
	ok -r $fn, "$fn readable";
};

done_testing;
