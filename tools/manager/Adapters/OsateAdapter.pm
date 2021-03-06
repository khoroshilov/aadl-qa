# Tool adapter for Ocarina.
#
# Copyright (C) 2014,
#   Julien Delange, CMU/SEI
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

package OsateAdapter;
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
  my $instance_option;
  my $instance_name;
  my $instances_names;
  my $tool;
  my $tooldir;
  my $aadlfiles;
  my $firstpassed = 0;
  my $line;
  my $retcode = 2;

  print "[OSATE] Processing " . $test_case->{'name'} . " " ;
  $result{'RESULT'} = "INVALID";
  $tool = `which ramses.sh`;
  chomp ($tool);
  if ( ! -f $tool)
  {
    print "OSATE/Ramses not found\n";
    $result{'RESULT'} = "INVALID";
    return \%result;
  }
  
  if ( defined ($test_case->{'manifest'}{'OCARINA_USE_COMPONENTS_LIBRARY'}) and 
     ($test_case->{'manifest'}{'OCARINA_USE_COMPONENTS_LIBRARY'} eq "YES"))
  {
    print "[Osate] Pass test " . $test_case->{'name'} . "because it relies on ocarina\n";
    $result{'RESULT'} = $test_case->{'manifest'}{'EXPECTED_RESULT'};
    return \%result; 
  }

  
  $tooldir = `dirname $tool`;
  chomp ($tooldir);
  opendir MYDIR , $test_case->{'path'} or die "Cannot open test dir\n";
  
  $aadlfiles = "";
  $firstpassed = 0;
  while (my $f = readdir (MYDIR))
  {
    if ($f =~ /aadl$/)
    {
      $aadlfiles .= "," if ($firstpassed == 1);
      $aadlfiles .= "" . $test_case->{'path'} . "/" . $f;
      $firstpassed = 1;
    }
  }
  close MYDIR;
  
  $cmd = "(cd $tooldir && ./ramses.sh --parse -l all -m " . $aadlfiles . ")"; 
#print STDERR $cmd."\n";
 
  open CMD, "$cmd 2>&1 |";
  while ( ($line = <CMD>) && ($retcode == 2))
  {
	$result{'LOG'} .= $line;
	if ($line =~ /.*Syntaxe Error.*/)
	{
	  $retcode = 0;
	}
	if ($line =~ /.*Fatal Error.*/)
	{
	  $retcode = 0;
	}
	if ($line =~ /.*Error.*/)
	{
	  $retcode = 0;
	}
	if ($line =~ /.*Task Parse.*is done.*/)
	{
	  $retcode = 1;
	}
   }

   close CMD;
   if ($retcode == 1)
   {
      $result{'RESULT'} = "VALID";
   }
   
   $expected = $test_case->{'manifest'}{'EXPECTED_RESULT'}; 
  $expected =~ tr/a-z/A-Z/;
   
  if ( $result{'RESULT'} eq $expected)
  {
      print "- OK\n";
  }
  else
  {
      print "- ERROR (result=".$result{'RESULT'}." ; expected=".$expected.")\n";
  }
  return \%result;
}

#-----------------------------------------------------------------------
1; # return value
