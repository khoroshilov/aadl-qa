# Tool adapter for Ocarina.
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

package OcarinaAdapter;
use strict;

use ToolAdapter;
our @ISA = qw(ToolAdapter); # Inherit ToolAdapter
#-----------------------------------------------------------------------

#----------------------------------------------------------------------
# Run test case.
sub do_run {
  my ($self,$test_case) = @_;
  my %result = ();
  print "OcarinaAdapter->do_run($test_case->{'name'}):\n";
  system("echo ocarina $self->{'aadlfiles'}");
  my $code = system("ocarina -aadlv2 $self->{'aadlfiles'} >$test_case->{'LOGDIR'}/log.txt 2>&1");
  $result{'RESULT'} = ($code eq 0) ? "VALID" : "INVALID";
  $result{'LOG'} = `cat $test_case->{'LOGDIR'}/log.txt`;
  return \%result;
}

#-----------------------------------------------------------------------
1; # return value
