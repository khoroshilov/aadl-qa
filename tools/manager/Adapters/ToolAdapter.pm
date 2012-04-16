# Common interface class for all tool adapters.
#
# Copyright (C) 2012,
#   Alexey Khoroshilov, ISPRAS
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	
package ToolAdapter;
use strict;

require Exporter;
our @ISA = qw(Exporter);
#----------------------------------------------------------------------

# Class constructor
sub new {
  my ($class, %init_data) = @_;
	
  my $self  = {};

  for my $key ( keys %init_data ) {
    $self->{$key} = $init_data{$key};
  }

  bless $self, $class;
  return $self;
}

#----------------------------------------------------------------------
# Returns description of tool adapter.
sub get_description {
  my ($self) = @_;
  if (defined($self->{'description'})) {
    return $self->{'description'};
  } else {
    return "an adapter for $self->{'tool'}";
  }
}

#----------------------------------------------------------------------
# Do common preparation steps.
sub prepend_common_aadlfiles($$$) {
  my $manifest  = shift(@_);
  my $basepath  = shift(@_);
  my $aadlfiles = shift(@_);
  if (defined($manifest->{'INCLUDE_FILES'})) {
    foreach my $aadlfile (split " \t", $manifest->{'INCLUDE_FILES'}) {
      if (!($aadlfile =~ m/^\//)) {
        $aadlfile = $basepath."/".$aadlfile;
      }
      $aadlfiles = "$aadlfile $aadlfiles";
    }
  }
  if (defined($manifest->{'INCLUDE'})) {
    foreach my $include (split " \t", $manifest->{'INCLUDE'}) {
      if (!($include =~ m/^\//)) {
        $include = $basepath."/".$include;
      }
      $aadlfiles = "$include/*.aadl $aadlfiles";
    }
  }
  return $aadlfiles;
}

#----------------------------------------------------------------------
sub prepare_run {
  my ($self,$test_case) = @_;
  # Calculate all aadl files required
  my $aadlfiles = "$test_case->{'path'}/*.aadl";
  $aadlfiles = prepend_common_aadlfiles($test_case->{'manifest'},$test_case->{'path'},$aadlfiles);
  my $parent = $test_case->{'parent'};
  while(defined($parent)) {
    $aadlfiles = prepend_common_aadlfiles($parent->{'manifest'},$parent->{'path'},$aadlfiles);
    $parent= $parent->{'parent'};
  }
  $self->{'aadlfiles'} = $aadlfiles;
  # Prepare logdir
  $test_case->{'LOGDIR'} = "$ENV{'AADLLOGDIR'}/$ENV{'AADLRUN'}/$self->{'tool'}/$test_case->{'fullname'}";
  system("mkdir -p $test_case->{'LOGDIR'}");
  return 1; # OK
}

#----------------------------------------------------------------------
sub register_failure {
  my ($self,$test_case,$result,$errmsg) = @_;
  $result->{'_VERDICT'} = "FAIL";
  my $failure = defined($result->{'_FAILURE'}) ? $result->{'_FAILURE'}."\n" : "";
  $result->{'_FAILURE'} = "$failure"."$errmsg";
}

#----------------------------------------------------------------------
sub post_run {
  my ($self,$test_case,$result) = @_;
  # Check expected results
  if (!defined($result->{'_VERDICT'})) {
    $result->{'_VERDICT'} = "PASS";
  }
  my $manifest = $test_case->{'manifest'};
  foreach my $key ( keys %$manifest ) {
    if ($key =~ m/^EXPECTED_([a-zA-Z0-9_]*$)_OPT/) {
      my $name = $1;
      if (defined($result->{$name})) {
        if ($manifest->{$key} ne $result->{$name}) {
          $self->register_failure($test_case,$result,"$name is '$result->{$name}' instead of '$manifest->{$key}'");
        }
      }
    } elsif ($key =~ m/^EXPECTED_([a-zA-Z0-9_]*$)_MATCH/) {
      my $name = $1;
      if (defined($result->{$name})) {
        if ($result->{$name} =~ m/$manifest->{$key}/) {
          $self->register_failure($test_case,$result,"$name is '$result->{$name}' that does not match '$manifest->{$key}'");
        }
      } else {
        $self->register_failure($test_case,$result,"$name is undefined");
      }
    } elsif ($key =~ m/^EXPECTED_([a-zA-Z0-9_]*$)/) {
      my $name = $1;
      if (defined($result->{$name})) {
        if ($manifest->{$key} ne $result->{$name}) {
          $self->register_failure($test_case,$result,"$name is '$result->{$name}' instead of '$manifest->{$key}'");
        }
      } else {
        $self->register_failure($test_case,$result,"$name is undefined");
      }
    }
  }
  # Dump result
  open(FILE, ">", "$test_case->{'LOGDIR'}/_RESULT");
  foreach my $k ( keys %$result ) {
    foreach my $line (split "\n",$result->{$k}) {
      print FILE "$k=$line\n";
    }
  }
  close(FILE);
  return $result;
}

#----------------------------------------------------------------------
# Do run test case.
sub do_run {
  die "ToolAdapter->do_run() have to be redefined";
}

#----------------------------------------------------------------------
# Interface method to run test case.
sub run {
  my ($self,$test_case) = @_;
  $self->prepare_run($test_case);
  my $res = $self->do_run($test_case);
  return $self->post_run($test_case, $res);
}

#-----------------------------------------------------------------------
1; # return value
