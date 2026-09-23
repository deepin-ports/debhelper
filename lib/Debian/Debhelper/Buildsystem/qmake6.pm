package Debian::Debhelper::Buildsystem::qmake6;

use strict;
use warnings;
use parent qw(Debian::Debhelper::Buildsystem::qmake);
use Debian::Debhelper::Dh_Lib qw(get_build_tool);

sub DESCRIPTION {
	"qmake for QT 6 (*.pro)";
}

sub _qmake {
	return get_build_tool(command => "qmake6", required => 1);
}

1
