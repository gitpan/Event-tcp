#!./perl
use strict;
use warning;
use Test; plan test => 3;

use Event qw(loop unloop);

my $port = 7000 + int rand 2000;

if (fork == 0) { #child
    sleep 1;

    my $serv = Event->tcpserv(e_port => $port, e_cb => \&accept_connection);

    sub accept_connection {
	my ($w, $sock) = @_;
	Event->io(e_fd => $sock, e_poll => 'r', e_cb => \&close_connection);
    }

    sub close_connection {
	my ($e) = @_;
	close $e->w->{e_fd};
	unloop(0);
    }

    exit loop();

} else {
    my $state=0;
    my $c = Event->tcpclient(e_port => $port, e_cb => \&send_stuff,
			    e_comm_cb => \&comm_cb);
    ok ref $c, 'Event::tcpclient';
    
    #setsockopt($c->{e_fd}, IPPROTO_TCP, TCP_NODELAY, pack('l',1))
    #	or die "setsockopt: $!";

    sub comm_cb {
	my ($w, $st) = @_;
	ok $st, $state;
	++$state;
    }

    sub send_stuff {
	my ($e) = @_;
	syswrite $e->w->{e_fd}, '*', 1;
	unloop();
    }

    loop(); wait;
}
