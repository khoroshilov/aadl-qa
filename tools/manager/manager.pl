#!/usr/bin/perl

# AADL QA Test Manager
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
use FindBin;
use Getopt::Long;


sub BEGIN {
	# Add current directory to the @INC to be able to include modules
	# from the same directory where this script is located.
	unshift @INC, $FindBin::Bin, $FindBin::Bin.'/Adapters';
}

use ToolAdapter;
use Reporter;
#----------------------------------------------------------------------
my @SRCDIRS;
my $LOGDIR;
my $REPORTDIR;
my @TOOLS;
my $REQPROJECT;
my $REQBASE;
my $keep_journals = 1;
my $list_tools_only = 0;
GetOptions("src=s"        => \@SRCDIRS,
           "logdir=s"     => \$LOGDIR,
           "reportdir=s"  => \$REPORTDIR,
           "tool=s"       => \@TOOLS,
           "reqproject=s" => \$REQPROJECT,
           "reqbase=s"    => \$REQBASE,
           "clean"        => sub {$keep_journals=0;},
           "list-tools"   => \$list_tools_only
          );


#----------------------------------------------------------------------

sub trim {
	my ($s) = @_;
	(defined $s) or return error("trim(undefined)");
	$s =~ s/^\s+//; # Remove spaces in the beginning of the line
	$s =~ s/\s+$//; # Remove trailing spaces
	return $s;
}

sub load_config {
  my $filename = shift(@_);
  my %config   = ();

  if (open(FILE, $filename)) {
    while (<FILE>) {
      s/[\r\n]//g;
      if (/^([^= ]+)[ ]*=\s*(.*)$/) {
        $config{$1} = $2;
      }
    }
    close(FILE);
  } else {
      print "ERROR: Config file $filename is unavailable\n";
  }
  return \%config;
}

#----------------------------------------------------------------------
# Print descriptor for debug purposes.
sub print_value($$) {
  my $value = shift(@_);
  my $indent = shift(@_);

  if (ref($value) eq "HASH") {
    foreach my $key (keys %{$value}) {
      for(my $i=0;$i<$indent;$i++) {
        print "  ";
      }
      my $newvalue = $$value{$key};
      if (ref($newvalue) eq "HASH") {
        if ($key eq "parent") {
          print "$key: $newvalue->{'name'}\n";
        } else {
          print "$key:\n";
          print_value($newvalue,$indent+1);
        }
      } else {
        print "$key -> $newvalue\n";
      }
    }
  } else {
    for(my $i=0;$i<$indent;$i++) {
      print "  ";
    }
    print "$value\n";
  }
}

#----------------------------------------------------------------------
sub detect_OS {
  if ( system ("which lsb_release >/dev/null 2>&1") == 0 ) {
    # The OS version is determined via the lsb_release tool
    # (this should be a canonical, distro independent way).
    my $res = trim(`lsb_release -s -d`);
       $res =~ s/^\"(.*)\"$/$1/;  # remove quotes if any
       return $res;
  } else {
    my $res = `cat /etc/issue`;
    if ( $res ne "" ) {
      $res =~ s/\n.*//s; # leave only the first line
      return $res;
    }
  }
  return "$^O";;
}

#----------------------------------------------------------------------
sub load_reporter {
  # Support for several implementations can be added later
  return Reporter->new(@_);
}

#----------------------------------------------------------------------
sub load_test_cases($$) {
  my $tspath = shift(@_);
  my $parent = shift(@_);
  my @test_cases_list = `find $tspath -name MANIFEST.TC | sort`;
  my %test_cases = ();
  foreach my $tcmanifest ( @test_cases_list ) {
    $tcmanifest =~ m/$tspath(.*)\/MANIFEST.TC/;
    my $test_case = $1;
    my $test_case_desc = {
                name       => $test_case,
                fullname   => "$parent->{'name'}$test_case",
                manifest   => load_config($tcmanifest),
                path       => "$tspath$test_case",
                parent     => $parent
            };
    $test_cases{$test_case} = $test_case_desc;
  }
  return \%test_cases;
}

sub is_leaf_test_suite($$) {
  my $tspath = shift(@_);
  my $allts  = shift(@_);
  foreach my $tsmanifest ( @$allts ) {
    $tsmanifest =~ m/(.*)\/MANIFEST.TS/;
    my $tspath2 = $1;
    if (($tspath ne $tspath2) && ($tspath2 =~ m/^$tspath/)) {
      return 0;
    }
  }
  return 1;
}

sub load_test_suites($$) {
  my $test_suites = shift(@_);
  my $tspath = shift(@_);
  my @test_suites_list = `find $tspath -name MANIFEST.TS | sort`;
  foreach my $tsmanifest ( @test_suites_list ) {
    $tsmanifest =~ m/$tspath(.*)\/MANIFEST.TS/;
    my $test_suite = $1;
    my $test_suite_desc = {
                name       => $test_suite,
                manifest   => load_config($tsmanifest),
                path       => "$tspath$test_suite"
            };
    if (is_leaf_test_suite("$tspath$test_suite",\@test_suites_list)) {
      $test_suite_desc->{'test_cases'} = load_test_cases("$tspath$test_suite",$test_suite_desc);
    }
    # find parent test suite
    foreach my $ts ( reverse keys %$test_suites ) {
      if ($test_suite =~ m/^$ts/) {
        $test_suite_desc->{'parent'} = $test_suites->{$ts};
        last;
      }
    }
    # store test suite descriptor
    $test_suites->{$test_suite} = $test_suite_desc;
  }
  return 1;
}

#----------------------------------------------------------------------

# This function creates a tool adapter.
sub load_tool_adapter {
  my ($tool) = @_;	
  my $module_file = $tool."Adapter.pm";

  # Link up the module
  eval {
    require $module_file;
  };
  if ($@) { # Any errors?
    die "Loading module $module_file failed";
  }

  my $class_name = $module_file;
  $class_name =~ s/\.pm$//;

  my $tool_adapter = $class_name->new( tool => $tool );

  return $tool_adapter;
}

#----------------------------------------------------------------------
sub run_tool_tests($$$) {
  my $test_suites = shift(@_);
  my $tools = shift(@_);
  my $reporter = shift(@_);

  foreach my $tool (@$tools) {
    my $tool_adapter = load_tool_adapter($tool);
    foreach my $ts (sort keys %$test_suites) {
      #print "--$test_suites->{$ts}->{'name'}:\n";
      if (defined ($test_suites->{$ts}->{'test_cases'})) {
        my $test_cases = $test_suites->{$ts}->{'test_cases'};
        foreach my $tc (sort keys %$test_cases) {
          my $test_case = $test_cases->{$tc};
          #print "Test test case for $tool: $test_case->{'name'}\n";
          my $result = $tool_adapter->run($test_case);
          $reporter->process_test_case_result($tool_adapter,$test_case,$result);
        }
      }
    }
  }
}

#----------------------------------------------------------------------
sub list_all_tool_adapters() {
  opendir(DIR, "$FindBin::Bin/Adapters");
  my @adapters = readdir(DIR); 
  closedir(DIR);
  foreach my $adapter (@adapters) {
    next unless ($adapter =~ m/(.*)Adapter.pm/);
    next if ($adapter eq "ToolAdapter.pm");
    eval {
      require $adapter;
    };
    my $tool = $1;
    my $class_name = $tool."Adapter";
    my $tool_adapter = $class_name->new( tool => $tool );    
    my $description = $tool_adapter->get_description();
    print "    $tool\t- $description\n";
  }
}

#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------
if ($list_tools_only) {
  list_all_tool_adapters();
  exit 0;
}
system("mkdir -p $LOGDIR");
if (! -d "$LOGDIR") {
  die "Cannot create '$LOGDIR'";
}
system("mkdir -p $REPORTDIR");
if (! -d "$REPORTDIR") {
  die "Cannot create '$REPORTDIR'";
}
$ENV{'AADLLOGDIR'} = $LOGDIR;
my ($second, $minute, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
$ENV{'AADLRUN'} = sprintf "%04d%02d%02d-%02d%02d%02d", $year+1900, $month+1, $day, $hour, $minute, $second;

# Load required staff
my %args = ( "reqproject" => $REQPROJECT, 
             "reqbase"    => $REQBASE 
           );
my $reporter = load_reporter(%args);
my %all_test_suites = ();
foreach my $src (@SRCDIRS) {
  load_test_suites(\%all_test_suites,$src);
}

# Run tests
my $start_time = `date "+%d-%b-%Y %H:%M:%S"`;
run_tool_tests(\%all_test_suites,\@TOOLS,$reporter);
my $finish_time = `date "+%d-%b-%Y %H:%M:%S"`;

# Generate reports
my %info = ( 
  global_start_time  => $start_time,
  global_finish_time => $finish_time,
  os                 => detect_OS()
);
$reporter->process_meta_info(\%info);
$reporter->generate_report($REPORTDIR);

if (!$keep_journals) {
  system("rm -rf $LOGDIR");
}

# Debug only
#foreach my $key (sort keys %$all_test_suites) {
#  print "$key:\n";
#  print_value($$all_test_suites{$key},1);  
#}



                
