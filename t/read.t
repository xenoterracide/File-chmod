use strict;
use warnings;
use Test::More;
use English '-no_match_vars';
use File::Temp ();
use File::chmod qw( chmod getmod );
$File::chmod::UMASK = 0;

#plan skip_all => "Windows perms work differently" if $OSNAME eq 'MSWin32';

my $tmp = File::Temp->new;
my $fn  = $tmp->filename;
note sprintf "original state of %s: %o\n", $fn, getmod( $fn );

ok chmod("+r", $fn ), "chmod +r $fn";
ok -r $fn, "$fn readable";

ok chmod("-r", $fn ), "chmod -r $fn";
ok ! -r $fn, "$fn not readable";

# test a second time because there's a good chance it was the first
ok chmod("+r", $fn ), "chmod +r $fn";
ok -r $fn, "$fn readable";

done_testing;
