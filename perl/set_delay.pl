#!/usr/bin/perl

use warnings;
use strict;
use Device::SerialPort;

$|++;

my $port = init_serial();

my $delay = shift || 1;

# so that the next write doesn't confuse the Arduino
sleep 2;

$port->write("setDelay $delay");

while (1) {
    my $str = $port->lookfor();
    next unless $str;
    print "$str\n";
}

sub init_serial {
    my @devs
        = qw(/dev/tty.usbserial-FTELR4YH /dev/tty.usbserial-A7006SAd /dev/tty.usbserial-A7007bpS);

    my $port = undef;
    for my $port_dev (@devs) {
        print "Trying $port_dev...\n";
        $port = Device::SerialPort->new($port_dev);
        if ($port) {
            print "Connected to port $port_dev\n";
            last;
        }
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
