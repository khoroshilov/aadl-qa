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
  my $cmd;
  my $code;
  my $expected;
  my $components_file;

   $components_file = "";

  $components_file = `ocarina-config --prefix`;
  chomp ($components_file);
  $components_file .= "/share/ocarina/AADLv2/ocarina_components.aadl";


  $expected = "";

  if (! -f $components_file)
  {
   $components_file = "";
  }

  $components_file = "" if ( defined ($test_case->{'manifest'}{'OCARINA_USE_COMPONENTS_LIBRARY'})
                            and ($test_case->{'manifest'}{'OCARINA_USE_COMPONENTS_LIBRARY'} eq "NO"));

  print "[Ocarina] EXECUTING TEST $test_case->{'name'}: ";

  $cmd = "ocarina -aadlv2 -f $self->{'aadlfiles'} ". $components_file . " >$test_case->{'LOGDIR'}/log.txt 2>&1";
  $code = system($cmd);
  if ($code == 0)
  {
      $result{'RESULT'} = "VALID";
  }
  else
  {
      $result{'RESULT'} = "INVALID";
  }

  $expected = $test_case->{'manifest'}{'EXPECTED_RESULT'};

  if ($expected eq  $result{'RESULT'})
  {
      print "- OK\n";
  }
  else
  {
      print "- ERROR (result=".$result{'RESULT'}." ; expected=".$expected.")\n";
  }

  $result{'LOG'} = `cat $test_case->{'LOGDIR'}/log.txt`;
  if ($result{'LOG'} =~ m/Execution terminated by unhandled exception/) {
    $self->register_failure($test_case,\%result,"Segmentation fault");
  }
  return \%result;
}

#-----------------------------------------------------------------------
1; # return value
