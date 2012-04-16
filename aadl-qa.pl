#!/usr/bin/perl

# AADL QA Main Script
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

use strict;
use Switch;
use FindBin;

#----------------------------------------------------------------------
my $CMD       = shift;


#----------------------------------------------------------------------
my $reqproject = "$FindBin::Bin/requirements/AADL-CTS";
my $src        = "$FindBin::Bin/src";
my $gensrc     = "$FindBin::Bin/gensrc";
my $logdir     = "$FindBin::Bin/journals";
my $reportdir  = "$FindBin::Bin/reports";
my $aadlgen    = "$FindBin::Bin/tools/aadlgen/aadlgen.pl";
my $manager    = "$FindBin::Bin/tools/manager/manager.pl";
my $gensrcts   = "$FindBin::Bin/gensrc/AADL-CTS";
my $reqbase    = "$FindBin::Bin/gensrc/AADL-CTS/reqdb.txt";

#----------------------------------------------------------------------
# Generate gensrc from requality project
sub tests_gensrc() {
  if (-e "$gensrcts") {
    system("rm -rf $gensrcts");
  }
  system("$aadlgen $reqproject $gensrcts");
}

#----------------------------------------------------------------------
# Run all tests for the tools given
sub tests_run() {
  my $tools = join(" --tool ",@ARGV);
  if (! -e $gensrc) {
    print "ERROR: $gensrc not found\n";
    print "\nRun 'aadl-qa.pl gensrc'\n";
    exit 1;
  }
  system("$manager --src $src --src $gensrc --logdir $logdir --reportdir $reportdir --reqproject $reqproject --reqbase $reqbase --tool $tools");
}

#----------------------------------------------------------------------
# Clean all generated files
sub tests_clean() {
  system("rm -rf $gensrc $logdir $reportdir");
}

#----------------------------------------------------------------------
# Print all supported tools
sub print_supported_tools() {
  system("$manager --list-tools");
}

#----------------------------------------------------------------------
sub print_usage() {
  print <<USAGE;
  aadl-qa.pl run <tools> - Run all tests for <tools> and generate report
  aadl-qa.pl gensrc      - Generate AADL tests from other sources
  aadl-qa.pl clean       - Remove all generates files
  aadl-qa.pl --help      - Print this message
  
  The list of tools supported:  
USAGE
  print_supported_tools();
}

#----------------------------------------------------------------------
switch ($CMD) {
  case "--help" { print_usage();  }
  case "gensrc" { tests_gensrc(); }
  case "run"    { tests_run();    }
  case "clean"  { tests_clean();  }
  else          { print "Unknown command: $CMD\n\n"; print_usage();  }
}
