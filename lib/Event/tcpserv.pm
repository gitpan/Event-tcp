use strict;
use warning;
package Event::tcpserv;
use Carp;
use Symbol;
use Socket;
use Fcntl;
use Event 0.40;
use Event::Watcher qw(R W T);
require Event::io;
use vars qw($VERSION @ISA);
$VERSION = '0.06';
@ISA = 'Event::io';

'Event::Watcher'->register;

sub new {
    my $class = shift;
    my %arg = @_;

    my $port = delete $arg{e_port} || die "e_port required";
    my $cb = delete $arg{e_cb} || die "e_cb required";
    for (qw(e_fd e_poll)) { carp "$_ ignored" if delete $arg{$_}; }

    my $proto = getprotobyname('tcp');
    socket(my $sock = gensym, PF_INET, SOCK_STREAM, $proto)
	or die "socket: $!";
    setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, pack('l', 1))
	or die "setsockopt: $!";
    bind($sock, sockaddr_in($port, INADDR_ANY)) or die "bind: $!";
    listen($sock, SOMAXCONN)                    or die "listen: $!";

    $class->SUPER::new(%arg, e_fd => $sock, e_poll => R, e_reentrant => 0,
		       e_max_cb_tm => 5, e_cb => sub {
			   my ($e) = @_;
			   my $w=$e->w;
			   my $sock = gensym;
			   accept $sock, $w->{e_fd} or return;
	       # fcntl might be architecture dependent XXX
	       #my $fcntl = pack 'I', O_NONBLOCK | O_NDELAY;
	       #warn join(' ', unpack 'c*', $fcntl);
	       #fcntl $sock, F_SETFL, $fcntl or die "fcntl SETFL $!";
	       #fcntl $sock, F_GETFL, $fcntl or die "fcntl GETFL $!";
	       #warn join(' ', unpack 'c*', $fcntl);
			   $cb->($w, $sock);
		       });
}

1;

__END__
    Event->io(e_desc => $w->{e_desc}.' '.fileno($sock),
	      e_fd => $sock, e_prio => $e->{e_prio},
	      e_poll => R, e_reentrant => 0,
	      e_timeout => $timeout, e_max_cb_tm => 30,
	      e_cb => $cb);
