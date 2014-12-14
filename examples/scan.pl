#!/usr/bin/perl

BEGIN { push( @INC, "../lib" ); }

use WebService::Belkin::WeMo::Device;
use WebService::Belkin::WeMo::Discover;
use Data::Dumper;
use strict;

$SIG{PIPE} = 'IGNORE';

my $wemoDiscover = WebService::Belkin::WeMo::Discover->new();

# Enable debug to see what's going on with UPNP.
# Note: if running in a VM, make sure bridged networking is enabled not NAT
# $Net::UPnP::DEBUG = 1;
my $discovered = $wemoDiscover->search();

$wemoDiscover->save("./belkin.db");


foreach my $ip (keys %{$discovered}) {
	print "Found $ip\n";
	print "Friendly Name = $discovered->{$ip}->{'name'}\n";
	print "Type = $discovered->{$ip}->{'type'}\n";
	print "UDN = $discovered->{$ip}->{'udn'}\n";
	if($discovered->{$ip}->{'type'} eq "bridge"){
		my $wemo = WebService::Belkin::WeMo::Device->new(ip =>$ip, deviceid => '94103EA2B277D34D', scan => 0,db => './belkin.db');
		print "ip = $ip" . " name = " . $wemo->getFriendlyName() . " type = " . $wemo->getType() . "\n";
		$wemo->bulbOn();
	}
}

#print Dumper $discovered;
