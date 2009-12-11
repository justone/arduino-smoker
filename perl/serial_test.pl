#!/usr/bin/perl

use warnings;
use strict;
use Device::SerialPort;

$|++;

my $port = init_serial();

my $lines = 0;
while (1) {
    my $str = $port->lookfor();
    next unless $str;
    print "$str\n";
    $lines++;
    if ( $lines > 5 ) {
        $port->write("Got 5\n");
        $lines = 0;
    }
}

sub init_serial {
    my @devs = qw(/dev/tty.usbserial-FTELR4YH /dev/tty.usbserial-A7006SAd);

    my $port = undef;
    for my $port_dev (@devs) {
        $port = Device::SerialPort->new($port_dev);
        last if $port;
    }
    if ( !$port ) {
        die "No known devices found to connect to serial: $!\n";
    }

    $port->databits(8);
    $port->baudrate(9600);
    $port->parity("none");
    $port->stopbits(1);

    return $port;
}
