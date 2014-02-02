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
use Getopt::Long;


#----------------------------------------------------------------------
my $no_statistics  = 0;
my $no_reqcoverage = 0;
my $no_reqreport   = 0;
GetOptions(
           "no-statistics"  => \$no_statistics,
           "no-reqcoverage" => \$no_reqcoverage,
           "no-reqreport"   => \$no_reqreport
          );
my $CMD       = shift;


#----------------------------------------------------------------------
my $reqproject = "$FindBin::Bin/requirements/AADL-CTS";
my $src        = "$FindBin::Bin/tests";
my $logdir     = "$FindBin::Bin/journals";
my $reportdir  = "$FindBin::Bin/reports";
my $manager    = "$FindBin::Bin/tools/manager/manager.pl";

#----------------------------------------------------------------------
# Generate gensrc from requality project
sub tests_gensrc() {
my @test_suites_list = ();

  if (-d $src) {
    @test_suites_list = `find $src -name MANIFEST.TS | sort`;
    foreach my $tsmanifest ( @test_suites_list ) {
      $tsmanifest =~ m/$src(.*)\/MANIFEST.TS/;
      my $test_suite = $1;    
      if (-f "$src$test_suite/build.pl") {
        print("Generate tests for '$test_suite'\n");
        my $res = system("$src$test_suite/build.pl");
        my $msg = ($res == 0) ? "OK" : "FAIL";
        print("Generate tests for '$test_suite': $msg\n");
      }
    }
  }
}

#----------------------------------------------------------------------
# Run all tests for the tools given
sub tests_run() {
  my $tools = join(" --tool ",@ARGV);
  my $options = "";
  $options = $options." --no-statistics" if ($no_statistics);
  $options = $options." --no-reqcoverage" if ($no_reqcoverage);
  $options = $options." --no-reqreport" if ($no_reqreport);
  system("$manager $options --src $src --logdir $logdir --reportdir $reportdir --reqproject $reqproject --tool $tools");
}

#----------------------------------------------------------------------
# Clean all generated files
sub tests_clean() {
  system("rm -rf $logdir $reportdir");
}

#----------------------------------------------------------------------
# Print all supported tools
sub print_supported_tools() {
  system("$manager --list-tools");
}

#----------------------------------------------------------------------
sub print_usage() {
  print <<USAGE;
  aadl-qa.pl run [opts] <tools> - Run all tests for <tools> and generate report
  aadl-qa.pl gensrc             - Generate AADL tests from other sources
  aadl-qa.pl clean              - Remove all generates files
  aadl-qa.pl --help             - Print this message

  'run' options:
    --no-statistics             - Do not generate statistics data
    --no-reqcoverage            - Do not generate reqcoverage data
    --no-reqreport              - Do not generate reqcoverage report
  
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
