# Event::io with auto reconnect
use strict;
use warning;
package Event::tcpclient;
use Carp;
use Symbol;
use Socket;
use Event 0.40;
use Event::Watcher qw(R W T);
require Event::io;
use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = 'Event::io';

use constant RECONNECT_TM => 5;

'Event::Watcher'->register;

sub new {
    my $class = shift;
    my %arg = @_;
    my $iaddr;
    if (exists $arg{e_host}) {
	my $host = delete $arg{e_host};
	$iaddr = inet_aton($host) || die "Lookup of host '$host' failed";
    } elsif (exists $arg{e_iaddr}) {
	$iaddr = delete $arg{e_iaddr};
    } else {
	$iaddr = inet_aton('localhost');
    }
    my $port = delete $arg{e_port} || die "e_port is required";
    my $okcb = delete $arg{e_cb} || die "e_cb required";
    my $comm_cb = delete $arg{e_comm_cb};
    $arg{e_reentrant} = 0;
    my $o = $class->SUPER::new(%arg);
    $o->use_keys(qw(e_iaddr e_port e_okcb e_comm_cb));
    $o->{e_port} = $port;
    $o->{e_iaddr} = $iaddr;
    $o->{e_okcb} = $okcb;
    $o->{e_comm_cb} = $comm_cb || \&_default_state_cb;
    $o->{e_comm_cb}->($o, 0)
	if !$o->connect_to_host;
    $o;
}

sub _default_state_cb {
    my ($o, $yes) = @_;
    my $host = inet_ntoa $o->{e_iaddr};
    if ($yes) {
	warn "Event: '$o->{e_desc}' reconnected with $host #$o->{e_port}\n"
    } else {
	warn "Event: '$o->{e_desc}' lost connection with $host #$o->{e_port}\n"
    }
}

sub connect_to_host {
    my ($o) = @_;
    my $fd = gensym;
    socket($fd, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
	or die "socket: $!";
    if (!connect($fd, sockaddr_in($o->{e_port}, $o->{e_iaddr}))) {
	#warn $!; save in watcher? XXX
	$o->{e_timeout} = RECONNECT_TM;
	$o->{e_cb} = \&disconnected;
	return
    }
    $o->{e_fd} = $fd;
    $o->{e_cb} = $o->{e_okcb};
    1
}

sub disconnected {
    my ($e) = @_;
    my $o = $e->w;
    my $cb = $o->{e_comm_cb};
    $cb->($o, 0)
	if $o->{e_fd};
    $o->connect_to_host;
    $cb->($o, 1)
	if $o->{e_fd};
}

1;
__END__
