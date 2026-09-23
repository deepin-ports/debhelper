#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use File::Basename qw(dirname);
use lib dirname(dirname(__FILE__));
use Test::DH;
use Debian::Debhelper::Dh_Lib qw(!dirname);

use constant BUILD_ID_PREFIX => 'a0';
use constant BUILD_ID_SUFFIX => 'a1a2a3a4a5a6a7a7a9aaabacadaeafb0b1b2b3';

plan(tests => 1);

our @TEST_DH_EXTRA_TEMPLATE_FILES = (qw(
	debian/changelog
	debian/control
));

each_compat_subtest {
	my ($compat) = @_;

	my $gen_path = 'debian/.debhelper/libfoo0';
	mkdirs $gen_path;
	open(my $build_ids, '>', "$gen_path/dbgsym-build-ids") or die("open $gen_path/dbgsym-build-ids: $!");;
	print $build_ids "${\BUILD_ID_PREFIX}${\BUILD_ID_SUFFIX} ";
	close $build_ids or die("close $gen_path/dbgsym-build-ids: $!");

	my $build_id_path = "$gen_path/dbgsym-root/usr/lib/debug/.build-id/${\BUILD_ID_PREFIX}";
	mkdirs $build_id_path;
	create_empty_file "$build_id_path/${\BUILD_ID_SUFFIX}";

	ok(run_dh_tool('dh_gencontrol'));

	my $dbgsym_control =  "$gen_path/dbgsym-root/DEBIAN/control";
	open(my $control, '<', $dbgsym_control) or die("open $dbgsym_control: $!");
	my @lines = @{readlines($control)};
	my $matches = grep /^\s*Multi-Arch:\s*same\s*$/, @lines;
	ok($matches, "found 'Multi-Arch: same' in @lines");
};
