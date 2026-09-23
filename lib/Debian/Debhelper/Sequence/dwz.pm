#!/usr/bin/perl
# Enable dh_dwz

use strict;
use warnings;
use Debian::Debhelper::Dh_Lib qw(compat error);

# In compat 12 + 13, `dh_dwz` was activate by default.
if (compat(10)) {
	insert_before('dh_strip', 'dh_dwz');
} elsif (not compat(13)) {
	insert_before('dh_strip', 'dh_dwz');
}

1;
