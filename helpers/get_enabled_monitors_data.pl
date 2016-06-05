#!/usr/bin/perl -T

use strict;
use bytes;
use ZoneMinder;

my @mons = zmDbGetMonitors();
foreach my $line (@mons)
{
    my @monitors = @$line;
    my @hosts = ();
    my @ports = ();
    my @usernames = ();
    my @passwords = ();
    foreach my $monitor (@monitors)
    {
        if ($monitor->{Enabled}){
                my @user_pass_host = split/:/, $monitor->{Host};
                push @usernames, $user_pass_host[0];
                my @pass_host = split/@/, $user_pass_host[1];
                push @passwords, $pass_host[0];
                push @hosts, $pass_host[1];
                push @ports, $monitor->{Port};
        }
    }
    print join(':', @usernames) . "\n";
    print join(':', @passwords) . "\n";
    print join(':', @hosts) . "\n";
    print join(':', @ports) . "\n";
}