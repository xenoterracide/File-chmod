package File::chmod;

use Carp;
use strict;
use vars qw(
	$VERSION @ISA @EXPORT @EXPORT_OK $DEBUG
	$VAL $S $U $G $O $MODE $c
);

require Exporter;

@ISA = qw( Exporter AutoLoader );
@EXPORT = qw( chmod getchmod );
@EXPORT_OK = qw( symchmod lschmod getsymchmod getlschmod getmod );

$VERSION = '0.2';
$DEBUG = 1;

my %r = ('or' => [0,0400,0040,0004], 'full' => [0,0700,0070,0007]);
my %w = ('or' => [0,0200,0020,0002], 'full' => $r{'full'});
my %x = ('or' => [0,0100,0010,0001], 'full' => $r{'full'});


my ($SYM,$LS) = (1,2);


sub getmod {
	my @files = @_;
	my @return;

	for (@files){
		my $fm = (stat)[2] & 07777;
		my $s = ($fm & 07000)>>9;
		my ($u,$g,$o) = (($fm & 0700)>>6, ($fm & 0070)>>3, $fm & 0007);
		push @return, oct($s.$u.$g.$o);
	}

	return wantarray ? @return : $return[0];
}


sub chmod {
	my $mode = shift;
	my $how = determine_mode($mode);
	my @files = @_;

	return symchmod($mode,@files) if $how == $SYM;
	return lschmod($mode,@files) if $how == $LS;

	return CORE::chmod($mode, @files);
}

sub getchmod {
	my $mode = shift;
	my $how = determine_mode($mode);
	my @files = @_;

	return getsymchmod($mode,@files) if $how == $SYM;
	return getlschmod($mode,@files) if $how == $LS;

	return wantarray ? (($mode) x @files) : $mode;
}


sub symchmod {
	my $mode = shift;
	my @files = @_;
	my @return;
	my $ret = 1;

	@return = getsymchmod($mode,@files);
	for (@files){ $ret &= CORE::chmod(shift(@return),$_); }
	return $ret;
}

sub getsymchmod {
	my $mode = shift;
	my @files = @_;
	my @return;

	(determine_mode($mode) != $SYM) && do {
		carp "symchmod received non-symbolic mode: $mode";
		return 0;
	};

	for (@files){
		$VAL = getmod($_);

		for my $thismode (split /,/, $mode){
			local ($U,$G,$O,$MODE,$c);

			CHAR: for $c (split //, $thismode){
				for ($c){
					next if $MODE;
					/a/ && ($U=1,$G=2,$O=3) && next CHAR;
					/u/ && ($U=1) && next CHAR;
					/g/ && ($G=2) && next CHAR;
					/o/ && ($O=3) && next CHAR;
				}

				for ($c){
					/[-+=]/ && do {
						unless ($U || $G || $O){ ($U=1,$G=2,$O=3); }
						$MODE = $_;
						clear() if $_ eq "=";
						next CHAR;
					}
				}

				croak "Bad mode $thismode" if !$MODE;

				for ($c){
					if (/u/){
						u_or() if $MODE eq "+" or $MODE eq "=";
						u_not() if $MODE eq "-";
					}
					if (/g/){
						print "ENTERING /g/\n";
						g_or() if $MODE eq "+" or $MODE eq "=";
						g_not() if $MODE eq "-";
					}
					if (/o/){
						o_or() if $MODE eq "+" or $MODE eq "=";
						o_not() if $MODE eq "-";
					}
					if (/r/){
						r_or() if $MODE eq "+" or $MODE eq "=";
						r_not() if $MODE eq "-";
					}
					if (/w/){
						w_or() if $MODE eq "+" or $MODE eq "=";
						w_not() if $MODE eq "-";
					}
					if (/x/){
						x_or() if $MODE eq "+" or $MODE eq "=";
						x_not() if $MODE eq "-";
					}
					if (/s/){
						or_s() if $MODE eq "+" or $MODE eq "=";
						not_s() if $MODE eq "-";
					}
					if (/l/){
						or_l() if $MODE eq "+" or $MODE eq "=";
						not_l() if $MODE eq "-";
					}
					if (/t/){
						or_t() if $MODE eq "+" or $MODE eq "=";
						not_t() if $MODE eq "-";
					}
				}

				croak "Unknown mode: $mode";
			}
		}
		push @return, $VAL;
	}
	return wantarray ? @return : $return[0];
}


sub lschmod {
	my $mode = shift;
	my @files = @_;

	local $VAL;

	$VAL = getlschmod($mode,@files);

	return CORE::chmod($VAL,@files);
}

sub getlschmod {
	my $mode = shift;
	my @files = @_;

	((determine_mode($mode) != $LS) || length($mode) != 10) && do {
		carp "lschmod received non-ls mode: $mode";
		return 0;
	};

	local $VAL;

	my ($u,$g,$o) = ($mode =~ /^.(...)(...)(...)$/) || do {
		carp "lschmod received non-ls mode: $mode";
		return 0;
	};

	for (split //, $u){
		$VAL |= 0400 if /r/;
		$VAL |= 0200 if /w/;
		$VAL |= 0100 if /[xs]/;
		$VAL |= 04000 if /[sS]/;
	}

	for (split //, $g){
		$VAL |= 0040 if /r/;
		$VAL |= 0020 if /w/;
		$VAL |= 0010 if /[xs]/;
		$VAL |= 02000 if /[sS]/;
	}

	for (split //, $o){
		$VAL |= 0004 if /r/;
		$VAL |= 0002 if /w/;
		$VAL |= 0001 if /[xt]/;
		$VAL |= 01000 if /[Tt]/;
	}

	return wantarray ? (($VAL) x @files) : $VAL;
}


sub determine_mode {
	my $mode = shift;
	return 0 if $mode !~ /\D/;
	return $SYM if $mode =~ /[augo=+,]/;
	return $LS if $mode =~ /ST/;
	return $LS if $mode =~ /^.([r-][w-][xSs-]){2}[r-][w-][xTt-]$/;
	return $SYM;
}


sub clear {
	$U && ($VAL &= 02077);
	$G && ($VAL &= 05707);
	$O && ($VAL &= 07770);
}
	

sub u_or {
	my $val = $VAL;
	$G && ($VAL |= (($val & 0700)>>3 | ($val & 04000)>>1));
	$O && ($VAL |= (($val & 0700)>>6));
	next CHAR;
}

sub u_not {
	my $val = $VAL;
	$U && ($VAL &= ~(($val & 0700) | ($val & 05000)));
	$G && ($VAL &= ~(($val & 0700)>>3 | ($val & 04000)>>1));
	$O && ($VAL &= ~(($val & 0700)>>6));
	next CHAR;
}


sub g_or {
	my $val = $VAL;
	$U && ($VAL |= (($val & 070)<<3 | ($val & 02000)<<1));
	$O && ($VAL |= (($val & 070)>>3));
	next CHAR;
}

sub g_not {
	my $val = $VAL;
	$U && ($VAL &= ~(($val & 070)<<3 | ($val & 02000)<<1));
	$G && ($VAL &= ~(($val & 070) | ($val & 02000)));
	$O && ($VAL &= ~(($val & 070)>>3));
	next CHAR;
}


sub o_or {
	my $val = $VAL;
	$U && ($VAL |= (($val & 07)<<6));
	$G && ($VAL |= (($val & 07)<<3));
	next CHAR;
}

sub o_not {
	my $val = $VAL;
	$U && ($VAL &= ~(($val & 07)<<6));
	$G && ($VAL &= ~(($val & 07)<<3));
	$O && ($VAL &= ~(($val & 07)));
	next CHAR;
}


sub r_or {
	$U && ($VAL |= $r{'or'}[$U]);
	$G && ($VAL |= $r{'or'}[$G]);
	$O && ($VAL |= $r{'or'}[$O]);
	next CHAR;
}

sub r_not {
	$U && ($VAL &= ~$r{'or'}[$U]);
	$G && ($VAL &= ~$r{'or'}[$G]);
	$O && ($VAL &= ~$r{'or'}[$O]);
	next CHAR;
}


sub w_or {
	$U && ($VAL |= $w{'or'}[$U]);
	$G && ($VAL |= $w{'or'}[$G]);
	$O && ($VAL |= $w{'or'}[$O]);
	next CHAR;
}

sub w_not {
	$U && ($VAL &= ~$w{'or'}[$U]);
	$G && ($VAL &= ~$w{'or'}[$G]);
	$O && ($VAL &= ~$w{'or'}[$O]);
	next CHAR;
}


sub x_or {
	($VAL & 02000) && do {
		$DEBUG && carp("cannot set execute on locked file"); 1;
	} && next;
	$U && ($VAL |= $x{'or'}[$U]);
	$G && ($VAL |= $x{'or'}[$G]);
	$O && ($VAL |= $x{'or'}[$O]);
	next CHAR;
}

sub x_not {
	$U && ($VAL &= ~$x{'or'}[$U]);
	$G && ($VAL &= ~$x{'or'}[$G]);
	$O && ($VAL &= ~$x{'or'}[$O]);
	next CHAR;
}


sub or_s {
	($VAL & 02000) && do {
		$DEBUG && carp("cannot set-gid on locked file"); 1;
	} && next;
	($VAL & 00100) && do {
		$DEBUG && carp("execute bit must be on for set-uid"); 1;
	} && next;
	($VAL & 00010) && do {
		$DEBUG && carp("execute bit must be on for set-gid"); 1;
	} && next;
	$U && ($VAL |= 04000);
	$G && ($VAL |= 02000);
	$O && (carp "set-id has no effect for 'others'");
	next CHAR;
}

sub not_s {
	$U && ($VAL &= ~04000);
	$G && ($VAL &= ~02000);
	$O && (carp "set-id has no effect for 'others'");
	next CHAR;
}


sub or_l {
	($VAL & 00010) && do {
		$DEBUG && carp("cannot cause file locking on group executable file"); 1;
	} && next;
	($VAL & 02010) && do {
		$DEBUG && carp("cannot cause file locking on set-gid file"); 1;
	} && next;
	($U || $G || $O) && ($VAL |= 02000);
	next CHAR;
}

sub not_l {
	($U || $G || $O) && ($VAL &= ~02000);
	next CHAR;
}


sub or_t {
	$U && ($VAL |= 01000);
	$G && $DEBUG && (carp "sticky bit has no effect for 'group'");
	$O && $DEBUG && (carp "sticky bit has no effect for 'others'");
	next CHAR;
}

sub not_t {
	$U && ($VAL &= ~01000);
	$G && $DEBUG && (carp "sticky bit has no effect for 'group'");
	$O && $DEBUG && (carp "sticky bit has no effect for 'others'");
	next CHAR;
}

1;

__END__

=head1 NAME

File::chmod - Perl extension to implement symbolic and ls chmod modes

=head1 SYNOPSIS

  use File::chmod;

  # chmod takes all three types
  # these all do the same thing
  chmod(0666,@files);
  chmod("=rw",@files);
  chmod("-rw-rw-rw-",@files);

  # or

  use File::chmod qw( symchmod lschmod );

  chmod(0666,@files);		# this is the normal chmod
  symchmod("=rw",@files);	# takes symbolic modes only
  lschmod("-rw-rw-rw-",@files);	# takes "ls" modes only

  # more functions, read on to understand

=head1 DESCRIPTION

File::chmod is a utility that allows you to bypass system calls or bit
processing of a file's permissions.  It overloads the chmod() function
with its own that gets an octal mode, a symbolic mode (see below), or
an "ls" mode (see below).  If you wish not to overload chmod(), you can
export symchmod() and lschmod(), which take, respectively, a symbolic
mode and an "ls" mode.

Symbolic modes are thoroughly described in your chmod(1) man page, but
here are a few examples.

  chmod("+x","file1","file2");	# overloaded chmod(), that is...
  # turns on the execute bit for all users on those two files

  chmod("o=,g-w","file1","file2");
  # removes 'other' permissions, and the write bit for 'group'

  chmod("=u","file1","file2");
  # sets all bits to those in 'user'

"ls" modes are the type produced on the left-hand side of an C<ls -l> on a
directory.  Examples are:

  chmod("-rwxr-xr-x","file1","file2");
  # the 0755 setting; user has read-write-execute, group and others
  # have read-execute priveleges

  chmod("-rwsrws---","file1","file2");
  # sets read-write-execute for user and group, none for others
  # also sets set-uid and set-gid bits

The regular chmod() and lschmod() are absolute; that is, they are not
appending to or subtracting from the current file mode.  They set it,
regardless of what it had been before.  symchmod() is useful for allowing
the modifying of a file's permissions without having to run a system call
or determining the file's permissions, and then combining that with whatever
bits are appropriate.  It also operates separately on each file.

=head2 Functions

Exported by default:

=over 4

=item chmod(MODE,FILES)

Takes an octal, symbolic, or "ls" mode, and then chmods each file
appropriately.

=item getchmod(MODE,FILES)

Returns a list of modified permissions, without chmodding files.
Accepts any of the three kinds of modes.

  @newmodes = getchmod("+x","file1","file2");
  # @newmodes holds the octal permissons of the files'
  # modes, if they were to be sent through chmod("+x"...)

=back

Exported by request:

=over 4

=item symchmod(MODE,FILES)

Takes a symbolic permissions mode, and chmods each file.

=item lschmod(MODE,FILES)

Takes an "ls" permissions mode, and chmods each file.

=item getsymchmod(MODE,FILES)

Returns a list of modified permissions, without chmodding files.
Accepts only symbolic permisson modes.

=item getlschmod(MODE,FILES)

Returns a list of modified permissions, without chmodding files.
Accepts only "ls" permisson modes.

=item getmod(FILES)

Returns a list of the current mode of each file.

=back

=head2 Variables

=over 4

=item $File::chmod::DEBUG

If set to a true value, it will report carpings, similar to those produced
by chmod() on your system.  Otherwise, the functions will not report errors.
Example: a file can not have file-locking and the set-gid bits on at the
same time.  If $File::chmod::DEBUG is true, the function will report an
error.  If not, you are not carped of the conflict.  It is set to 1 as
default.

=head1 BUGS

I'm still trying to come up with sure-fire ways to distinguish between an
"ls" mode and a symbolic mode.  Let me know if you have a method for
determining the mode.  I'm not sure mine is infallible.

=head1 AUTHOR

  Jeff Pinyan
  jeffp@crusoe.net
  CPAN ID: PINYAN

=head1 SEE ALSO

  Stat::lsMode (by Mark-James Dominus)
  chmod(1) manpage
  perldoc -f chmod
  perldoc -f stat

=cut
