$VERSION = '0.31';
	my @return = map { (stat)[2] & 07777 } @_;
	my $ret = 0;
	for (@_){ $ret++ if CORE::chmod(shift(@return),$_) }
	return $ret;
					$or = (/[=+]/ ? 1 : 0);
				/u/ and $or ? u_or() : u_not();
				/g/ and $or ? g_or() : g_not();
				/o/ and $or ? o_or() : o_not();
				/r/ and $or ? r_or() : r_not();
				/w/ and $or ? w_or() : w_not();
				/x/ and $or ? x_or() : x_not();
				/s/ and $or ? s_or() : s_not();
				/l/ and $or ? l_or() : l_not();
				/t/ and $or ? t_or() : t_not();
	return CORE::chmod(getlschmod($mode,@_),@_);
	warn $ERROR{EDECMOD};
	$W & 4 and $VAL |= 0004;
	$W & 4 and $VAL &= ~0004;
	$W & 4 and $VAL |= 0002;
	$W & 4 and $VAL &= ~0002;
	if ($VAL & 02000){ $DEBUG and warn($ERROR{ENEXLOC}), return }
	if ($VAL & 02000){ $DEBUG and warn($ERROR{ENSGLOC}), return }
	if (not $VAL & 00100){ $DEBUG and warn($ERROR{ENEXUID}), return }
	if (not $VAL & 00010){ $DEBUG and warn($ERROR{ENEXGID}), return }
	$W & 4 and $DEBUG and warn $ERROR{ENULSID};
	$W & 4 and $DEBUG and warn $ERROR{ENULSID};
	if ($VAL & 02010){ $DEBUG and warn($ERROR{ENLOCSG}), return }
	if ($VAL & 00010){ $DEBUG and warn($ERROR{ENLOCEX}), return }
	$W & 2 and $DEBUG and warn $ERROR{ENULSBG};
	$W & 4 and $DEBUG and warn $ERROR{ENULSBO};
	$W & 2 and $DEBUG and warn $ERROR{ENULSBG};
	$W & 4 and $DEBUG and warn $ERROR{ENULSBO};
This is File::chmod v0.31.
If set to a true value, it will report warnings, similar to those produced
error.  If not, you are not warned of the conflict.  It is set to 1 as
=head2 0.30 to 0.31

=over 4

=item B<fixed getsymchmod() bug>

Whoa.  getsymchmod() was doing some crazy ish.  That's about all I can say.
I did a great deal of debugging, and fixed it up.  It ALL had to do with two
things:

  $or = (/+=/ ? 1 : 0); # should have been /[+=]/

  /u/ && $ok ? u_or() : u_not(); # should have been /u/ and $ok

=item B<fixed getmod() bug>

I was using map() incorrectly in getmod().  Fixed that.

=item B<condensed lschmod()>

I shorted it up, getting rid a variable.

=back

Certain calls to warn() were not guarded by the $DEBUG variable, and now they
    $DEBUG && warn("execute bit must be on for set-uid"); 1;