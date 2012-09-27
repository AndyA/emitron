#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use POSIX qw( strftime );
use Storable qw( dclone );

use constant UT      => '°C';
use constant SPEAKER => 'phool';

my $ts  = ts();
my $log = "$ts-sense.log";
open my $lf, '>', $log or die "Can't write $log: $!\n";
print "Logging to $log\n";

my $speaker = st->new( wiggle => 1 );
my $logger  = st->new( wiggle => 0 );

while () {
  chomp( my @s = `sensors` );
  my $sd  = parse_sensors( @s );
  my $rep = report(
    $sd,
    sub {
      my $vv = shift;
      $vv->{key} =~ /Temperature/i && $vv->{u} eq UT;
    }
  );

  $speaker->if_diff( $rep, sub { speak( fmt( shift ) ) } );
  $logger->if_diff( $rep, sub { mention( fmt( shift ) ) } );
  sleep 2;
}

sub ts  { strftime '%Y%m%d-%H%M%S',     localtime }
sub tsp { strftime '%Y/%m/%d %H:%M:%S', localtime }

sub speak {
  chomp( my $msg = join '', @_ );
  system 'ssh', SPEAKER, 'say', $msg;
}

sub mention {
  chomp( my $msg = join '', @_ );
  my $ts = tsp();
  for my $ln ( split /\n/, $msg ) {
    print "$ts $ln\n";
    print $lf "$ts $ln\n";
  }
}

sub fmt {
  my $diff = shift;
  return join ', ', map { "$_->{key}: $_->{v} $_->{u}" }
   map { $diff->{$_} } sort keys %$diff;
}

sub st::new {
  my ( $class, %args ) = @_;
  return bless { prev => undef, wiggle => 1, %args }, $class;
}

sub st::changed {
  my ( $self, $k, $a, $b ) = @_;
  return unless defined $a || defined $b;
  return 1 unless defined $a && defined $b;
  return abs( $a - $b ) > $self->{wiggle};
}

sub st::_changed {
  my ( $self, $k, $a, $b ) = @_;
  my $c = $self->_changed( $k, $a, $b );
  print +( $c ? '***' : '   ' ), " $k $a $b (", $self->{wiggle}, ")\n";
  return $c;
}

sub st::diff {
  my ( $self, $rep ) = @_;
  my $prev = $self->{prev};
  return $self->{prev} = dclone $rep unless $prev;
  my $diff = {};
  for my $k ( keys %$rep ) {
    $diff->{$k} = $prev->{$k} = $rep->{$k}
     if !$prev->{$k}
     || $self->changed( $k, $prev->{$k}{v}, $rep->{$k}{v} );
  }
  return $diff;
}

sub st::if_diff {
  my ( $self, $rep, $cb ) = @_;
  my $diff = $self->diff( $rep );
  $cb->( $diff ) if keys %$diff;
}

sub report {
  my ( $sd, $like ) = @_;
  my $rep = {};
  for my $dev ( sort keys %$sd ) {
    for my $adaptor ( sort keys %{ $sd->{$dev} } ) {
      for my $key ( sort keys %{ $sd->{$dev}{$adaptor} } ) {
        my $v  = $sd->{$dev}{$adaptor}{$key};
        my $vv = {
          dev     => $dev,
          adaptor => $adaptor,
          key     => $key,
          %$v
        };
        if ( $like->( $vv ) ) {
          my $kk = join '/', $dev, $adaptor, $key;
          $rep->{$kk} = $vv;
        }
      }
    }
  }
  return $rep;
}

sub parse_sensors {
  my @l  = @_;
  my $sd = {};
  my ( $dev, $adaptor );
  for my $ln ( @l ) {
    if ( $ln =~ /^(\S+)\s*$/ ) {
      $dev = $1;
    }
    elsif ( $ln =~ /^Adapter:\s+(.*)/ ) {
      $adaptor = $1;
    }
    elsif ( $ln =~ /\s*(.+?):\s*([+-]?\d+(?:\.\d+)?)\s*(\S+)/ ) {
      my ( $key, $val, $unit ) = ( $1, $2, $3 );
      $val += 0;
      $sd->{$dev}{$adaptor}{$key} = { v => $val, u => $unit };
    }
  }
  return $sd;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

__END__

atk0110-acpi-0
Adapter: ACPI interface
Vcore Voltage:      +1.00 V  (min =  +0.85 V, max =  +1.60 V)
 +3.3 Voltage:      +3.30 V  (min =  +2.97 V, max =  +3.63 V)
 +5 Voltage:        +5.10 V  (min =  +4.50 V, max =  +5.50 V)
 +12 Voltage:      +12.01 V  (min = +10.20 V, max = +13.80 V)
CPU FAN Speed:     2657 RPM  (min =  600 RPM, max = 7200 RPM)
CHASSIS FAN Speed: 2657 RPM  (min =  600 RPM, max = 7200 RPM)
CPU Temperature:    +38.0°C  (high = +60.0°C, crit = +95.0°C)
MB Temperature:     +31.0°C  (high = +45.0°C, crit = +75.0°C)

fam15h_power-pci-00c4
Adapter: PCI adapter
power1:       34.16 W  (crit =  95.04 W)

k10temp-pci-00c3
Adapter: PCI adapter
temp1:        +13.9°C  (high = +70.0°C)
                       (crit = +83.5°C, hyst = +80.5°C)

