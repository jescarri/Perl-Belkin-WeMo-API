#!/usr/bin/env perl

# $Id: Device.pm,v 1.4 2013-12-31 03:29:22 ericblue76 Exp $
#
# Author:       Eric Blue - ericblue76@gmail.com
# Project:      Belkin Wemo API
# Url:          http://eric-blue.com/belkin-wemo-api/
#

# ABSTRACT: Uses UPNP to control Belkin Wemo Switches

package WebService::Belkin::WeMo::Device;

use Data::Dumper;
use Net::UPnP::ControlPoint;
use Carp;

use strict;

sub new {

	my $class  = shift;
	my $self   = {};
	my %params = @_;

	if ( ( !defined $params{'ip'} ) && ( !defined $params{'name'} ) ) {
		croak("Insufficient parameters: ip or name are required!");
	}

	$self->{'_ip'}   = $params{'ip'};
	$self->{'_name'} = $params{'name'};
	$self->{'_db'}   = $params{'db'};
	$self->{'_scan'}   = $params{'scan'};
	if (defined $params{'deviceid'}) {
		$self->{'_deviceid'} = $params{'deviceid'};
	}
	my $discovered;
	my $wemoDiscover = WebService::Belkin::WeMo::Discover->new();
	if ( defined $params{'db'} ) {
			$discovered = $wemoDiscover->load($params{'db'});
		}
	if ( defined( $params{'ip'} ) ) {
			if ( !defined $discovered->{ $self->{'_ip'} } ) {
				croak "IP not found - on cache, Try to refresh it!";
				return undef;
		}
		$self->{_device} = $discovered->{ $self->{'_ip'} }->{'device'};
		$self->{_type} = $discovered->{ $self->{'_ip'} }->{'type'};
	}
	#Decouple the SCAN from the Device, to make if possible to run the agent from a different network.
	#If scan is 1 then the agent is running on the same network than the wemo Devices.
	if ( $self->{'_scan'} eq 1) {
		$discovered = $wemoDiscover->search();
		if ( defined( $params{'ip'} ) ) {
			if ( !defined $discovered->{ $self->{'_ip'} } ) {
				croak "IP not found - try running another discovery search!";
			}
	
			$self->{_device} = $discovered->{ $self->{'_ip'} }->{'device'};
			$self->{_type} = $discovered->{ $self->{'_ip'} }->{'type'};
		}
		if ( defined( $params{'name'} ) ) {
			my $found = 0;
			foreach ( keys( %{$discovered} ) ) {
				if ( $discovered->{$_}->{'name'} eq $params{'name'} ) {
					$found = 1;
					$self->{_device} = $discovered->{$_}->{'device'};
					last;
				}
			}
			if ( !$found ) {
				croak "Name not found - try running another discovery search!";
			}	
		}
	}
	
	# Load service - only basic/bridge is here for now, others will be supported later
	foreach my $service ( $self->{_device}->getservicelist() ) {

		if ( $service->getservicetype() =~ /urn:Belkin:service:basicevent:1/ ) {
			$self->{_basicService} = $service;
		}
		#Add service brige.
		if ( $service->getservicetype() =~ /urn:Belkin:service:bridge:1/ ) {
			$self->{_bridge} = $service;
		}
	}

	bless $self, $class;

	$self;

}

sub getType() {
    
    my $self = shift;
    
    if (defined($self->{_type})) {
        return $self->{_type};
    } else {
        return "undefined";
    }
    
    
}
sub getUDN() {
    
    my $self = shift;
    
    if (defined($self->{_udn})) {
        return $self->{_udn};
    } else {
        return "undefined";
    }
    
    
}
sub getFriendlyName() {

	my $self = shift;

	my $resp = $self->{_basicService}->postaction("GetFriendlyName");
	if ( $resp->getstatuscode() == 200 ) {
		return $resp->getargumentlist()->{'FriendlyName'};
	}
	else {
		croak "Got status code " . $resp->getstatuscode() . "!\n";
	}

}

sub isSwitchOn() {

	my $self = shift;

	my $resp = $self->{_basicService}->postaction("GetBinaryState");
	if ( $resp->getstatuscode() == 200 ) {
		return $resp->getargumentlist()->{'BinaryState'};
	}
	else {
		croak "Got status code " . $resp->getstatuscode() . "!\n";
	}

}

sub bulbOn() {

	my $self = shift;
	
	if ($self->getType ne "bridge") {
		warn "Method only supported for switches, not sensors.\n";
		return;
	}
	#The request needs an XML formated request, for now it is a copy/paste from a packet capture.
	my $resp = $self->{_bridge}->postaction("SetDeviceStatus",{ DeviceStatusList=> "&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;&lt;DeviceStatus&gt;&lt;IsGroupAction&gt;NO&lt;/IsGroupAction&gt;&lt;DeviceID available=&quot;YES&quot;&gt;$self->{'_deviceid'}&lt;/DeviceID&gt;&lt;CapabilityID&gt;10006&lt;/CapabilityID&gt;&lt;CapabilityValue&gt;1&lt;/CapabilityValue&gt;&lt;/DeviceStatus&gt;"				
						
	});
	if ( $resp->getstatuscode() == 200 ) {
		return $resp->getargumentlist()->{'BinaryState'};
	}
	else {
		print Dumper $resp;
		croak "Got status code " . $resp->getstatuscode() . "!\n";
	}

}

sub bulbOff() {

	my $self = shift;
	
	if ($self->getType ne "bridge") {
		warn "Method only supported for switches, not sensors.\n";
		return;
	}
	#The request needs an XML formated request, for now it is a copy/paste from a packet capture.
	my $resp = $self->{_bridge}->postaction("SetDeviceStatus",{ DeviceStatusList=> "&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;&lt;DeviceStatus&gt;&lt;IsGroupAction&gt;NO&lt;/IsGroupAction&gt;&lt;DeviceID available=&quot;YES&quot;&gt;$self->{'_deviceid'}&lt;/DeviceID&gt;&lt;CapabilityID&gt;10006&lt;/CapabilityID&gt;&lt;CapabilityValue&gt;0&lt;/CapabilityValue&gt;&lt;/DeviceStatus&gt;"				
						
	});
	if ( $resp->getstatuscode() == 200 ) {
		return $resp->getargumentlist()->{'BinaryState'};
	}
	else {
		print Dumper $resp;
		croak "Got status code " . $resp->getstatuscode() . "!\n";
	}

}

sub toggleSwitch() {

	my $self = shift;
	
	if ($self->getType() eq "sensor") {
        warn "Method only supported for switches, not sensors.\n";
	    return;
	}

	my $state  = $self->isSwitchOn();
	my $toggle = $state ^= 1;

	$self->on()  if $toggle == 1;
	$self->off() if $toggle == 0;

}

sub getBinaryState() {

	my $self = shift;

	my $resp =
	  $self->{_basicService}
	  ->postaction( "GetBinaryState");
	if ( $resp->getstatuscode() == 200 ) {

		my $state = $resp->getargumentlist()->{'BinaryState'};
		if ($state == 1) { 
		    return "on";
		} elsif ($state == 0) {
		    return "off";
		} else {
		    return "unknown";
		}
	}
	else {
		croak "Got status code " . $resp->getstatuscode() . "!\n";
	}

}

sub on() {

	my $self = shift;
	
    if ($self->getType() eq "sensor") {
        warn "Method only supported for switches, not sensors.\n";
	    return;
	}

	my $resp =
	  $self->{_basicService}->postaction( "SetBinaryState", { BinaryState => 1 } );
	if ( $resp->getstatuscode() == 200 ) {

		# Not this will be Error if the switch is already on
		return $resp->getargumentlist()->{'BinaryState'};
	}
	else {
		croak "Got status code " . $resp->getstatuscode() . "!\n";
	}

}

sub off() {

	my $self = shift;
	
	if ($self->getType() eq "sensor") {
	    warn "Method only supported for switches, not sensors.\n";
	    return;
	}

	my $resp =
	  $self->{_basicService}->postaction( "SetBinaryState", { BinaryState => 0 } );
	if ( $resp->getstatuscode() == 200 ) {

		# Not this will be Error if the switch is already off
		return $resp->getargumentlist()->{'BinaryState'};
	}
	else {
		croak "Got status code " . $resp->getstatuscode() . "!\n";
	}

}

1;

__END__


=head1 NAME

WebService::Belkin::Wemo::Device - Device class for controlling Wemo Switches
=head1 SYNOPSIS

Sample Usage:

my $wemo = WebService::Belkin::WeMo::Device->new(ip => '192.168.2.126', db => '/tmp/belkin.db');

OR

my $wemo = WebService::Belkin::WeMo::Device->new(name => 'Desk Lamp', db => '/tmp/belkin.db');



print "Name = " . $wemo->getFriendlyName() . "\n";
print "On/Off = " . $wemo->isSwitchOn() . "\n"; 

print "Turning off...\n";
$wemo->off();

print "Turning on...\n";
$wemo->on();

=head1 DESCRIPTION

The Belkin WeMo Switch lets you turn electronic devices on or off from anywhere inside--or outside--your home. 
The WeMo Switch uses your existing home Wi-Fi network to provide wireless control of TVs, lamps, stereos, and more. 
This library allows basic control of the switches (turning on/off and getting device info) through UPNP

=head1 METHODS

    * getFriendlyName - Get the name of the switch
    * isSwitchOn - Returns true (1) or false (0)
    * on - Turn switch on
    * off - Turn switch off
    * toggle - Toggle switch on/off
    * bulbOff - Turn off a light bulb via a bridge
    * bulbOn - Turn on a light bulb via a bridge


=head1 AUTHOR

Eric Blue <ericblue76@gmail.com> - http://eric-blue.com

=head1 COPYRIGHT

Copyright (c) 2013 Eric Blue. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut


