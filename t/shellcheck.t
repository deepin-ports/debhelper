#!/usr/bin/perl
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2026 Johannes Schauer Marin Rodrigues <josch@debian.org>

use strict;
use warnings;
use Test::More;

use List::Util qw(reduce);

# cartesian product by Andrew Rodland <andrew@cleverdomain.org>
# aka stackoverflow user https://stackoverflow.com/users/152948/hobbs
# https://stackoverflow.com/questions/2457096/2457928#2457928
sub cartesian_product {
    reduce {
        [map { my $item = $_; map [@$_, $item], @$a } @$b]
    } [[]], @_;
}

# Hash of sample replacements for #ITEM# placeholders in the autoscripts.
# Multiple replacements can be tested by making the value a list of strings
# instead of a simple string.
my %replacements = (
    CENTRALCAT        => '/etc/sgml/package.cat',
    CMDS              => 'u-f-s /path;u-f-d --x11r7-l /path',
    CONFILE_BASENAME  => 'sysusers files',
    DIRLIST           => 'foo bar baz',
    DIRS              => "foo\nbar\nbaz",
    ERROR_HANDLER     => ['exit 1',   'FIXME test shell escaping'],
    INITPARMS         => ['defaults', 'foo bar'],
    INSTALL_OPTIONS   => '--install link_path link_name impl_path priority',
    INVOKE_RCD_PARAMS => ['', '--skip-systemd-native '],
    JUSTDIRS          => "foo\nbar\nbaz",
    KVERS             => '7.0.1-arm64',
    PACKAGE           => 'mypkg',
    PARAMS            => 'param',
    PRIORITY          => '20',
    RESTART_ACTION    => 'restart',
    RM_OPTIONS        => '--remove link_name impl_path',
    SCRIPT            => 'pkgname',
    TMPFILES          => "foo bar baz",
    TMPFILES_PURGE    => "foo\nbar\nbaz",
    TMPFILES_REMOVE   => "foo\nbar\nbaz",
    UCFDEST           => 'dest',
    UCFSRC            => "ucfsrc",
    UNITFILE          => "'single-quoted-base'",
    UNITFILES         => 'foo bar baz',
    WM                => 'mywm',
    WMMAN             => '/usr/share/man/mywm.1.gz',
);

my @autoscripts = glob("autoscripts/*");

sub check_file {
    my $file    = shift;
    my $replace = shift;
    open my $readfd, '<', $file
      or die "failed to open ${file} for reading: $!";
    my @cmd       = qw(shellcheck --shell sh -);
    my $child_pid = open(my $writefd, "|-", @cmd)
      || die "failed to fork shellcheck: $!";

    while (my $line = readline($readfd)) {
        $line = $replace->($line);
        print $writefd $line;
    }
    close $readfd;
    close $writefd;
    return $?;
}

sub run_test {
    my $file         = shift;
    my %replacements = @_;
    my $replace      = sub {
        my $line = shift;
        foreach my $key (keys %replacements) {
            $line =~ s/#$key#/$replacements{$key}/g;
        }
        if ($line =~ /#[A-Z_]+#/) {
            diag("missing replacement: $line");
        }
        return $line;
    };
    return check_file($file, $replace);
}

# Assemble a list of key/value pairs with all the entries of %replacements
# which contain an ARRAY ref as a value. Those are the entries which we want
# to add to the cartesian product later.
my @factors
  = map { (ref $replacements{$_} eq "ARRAY") ? ([$_, $replacements{$_}]) : () }
  (sort keys %replacements);

# The number of tests that will be performed is the number of @autoscripts
# times the length of each array in @factors
plan(tests => reduce { $a * (scalar @$b) } (scalar @autoscripts), @factors);

foreach my $file (@autoscripts) {
    # cartesian_product() of the second entry of each tuple in @factors will
    # give us a list of factor lists. Each entry in a factor list corresponds
    # to the key stored in the first entry of the corresponding tuple in
    # @factors
    for my $factor (@{ cartesian_product(map { $_->[1] } @factors) }) {
        # The loop assumes that both @{$factor} as well as @factors have the
        # same length, which should be the case. Check for logic error just
        # to be sure.
        scalar @factors == scalar @{$factor} or die "logic error";
        my @msgs = ();
        for my $i (0 .. $#factors) {
            # We do the replacement directly in the %replacements hash which
            # will overwrite each of the list values which were in there
            # originally, but we already used that information and stored it
            # in @factors.
            $replacements{ $factors[$i][0] } = $factor->[$i];
            # Assemble an array of strings mapping keys to values that were
            # replaced to be able to output diagnostics later.
            push @msgs, "$factors[$i][0] = '$factor->[$i]'";
        }
        # Run shellcheck
        ok(0 == run_test($file, %replacements))
          or diag("shellcheck failed for $file with " . (join "; ", @msgs));
    }
}
