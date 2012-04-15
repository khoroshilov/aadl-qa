#!/usr/bin/perl -w

# AADL Generator from Requality project
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

#----------------------------------------------------------------------
my $reqproject = shift;
my $gensrc     = shift;

sub usage {
  print "Usage: aadlgen.pl <requality_project> <output_dir>\n";
}
if (! -d "$reqproject/root/Requirements") {
  usage();
  print "<requality_project> in '$reqproject' not found\n";
  exit 1;
}

#----------------------------------------------------------------------
sub detect_requality_exe {
my $uname = `uname -p`;
my $requality_exe = ($uname =~ m/.*64/) ? "requality.64" : "requality";
my $requality = `which $requality_exe`;
  $requality =~ s/^\s+//;
  $requality =~ s/\s+$//;
  return $requality;
}

#----------------------------------------------------------------------
my $TDIR;
my $TNAME;
my $TREQ;
my @TLOCS;
my %ATTRS;
my $TEST;
my $testcnt = 0;

sub generate_test($$$) {
my $LOCATIONS = shift;
my $ATTRIBUTES = shift;
my $CODE = shift;

  system("mkdir -p $TDIR");
  open(FILE, ">", "$TDIR/$TNAME.html");
  print FILE "$TEST";
  close(FILE);
  #system("html2text $TDIR/$TNAME.html > $TDIR/$TNAME.aadl");
  system("sed -e 's/<[^>]*>//g' -e 's/&gt;/>/g' -e 's/&gt;/</g' -e 's/&nbsp;/ /g' -e 's/&[lr]dquo;/\"/g' -e 's/&[a-z]*;//g' $TDIR/$TNAME.html > $TDIR/$TNAME.aadl");
  system("rm $TDIR/$TNAME.html");
  open(FILE, ">", "$TDIR/MANIFEST.TC");
  print FILE "REQ=$TREQ\n";
  my $i = 1;
#  foreach my $location (@$LOCATIONS) {
#    print FILE "LOCATION$i=$location\n";
#    $i++;
#  }
  if (!defined($ATTRIBUTES->{'EXPECTED_RESULT'})) {
    print FILE "EXPECTED_RESULT=VALID\n";
  }
  foreach my $key (keys %$ATTRIBUTES) {
    next if ($key =~ m/^_.*/);
    print FILE "$key=$ATTRIBUTES->{$key}\n";
  }
  close(FILE);
  $testcnt++;
}

#----------------------------------------------------------------------
# Main
my $requality = detect_requality_exe();
if (! -e $requality) {
  print "requality=$requality\n";
  die "requality executable not found";
}
my $repodir = "$gensrc";
my $tmpldir = "$FindBin::Bin/aadlgen.tmpl";
if (system("$requality report $tmpldir $reqproject $repodir") != 0) {
  die "requality db extraction failed";
}
my $reqdb = "$repodir/reqdb.txt";
if (! -e $reqdb) {
  die "$reqdb not generated";
}

# Generate MANIFEST file for test suite
system("mkdir -p $gensrc");
open(FILE, ">", "$gensrc/MANIFEST.TS");
print FILE <<ENDMANIFEST;
DESCRIPTION=Test Suite generated from Requality
ENDMANIFEST
close(FILE);
# Generate test cases
if (open (SOURCE_FILE, "<", $reqdb)) {
  while (<SOURCE_FILE>) {
    if (m/---id:\s*\/Requirements\/(.*)\/([^\/\s]*)[\s]*$/) {
      if (defined($TNAME) && defined($TEST)) {
        generate_test(\@TLOCS,\%ATTRS,$TEST);
      }
      $TDIR  = "$gensrc/$1/$2";
      $TNAME = $2;
      $TREQ = "/Requirements/$1/$2";
      @TLOCS = ();
      %ATTRS = ();
      $TEST = "";
    } elsif (m/--location:\s*\/Documents\/([^\s]*)[\s]*$/) {
      push @TLOCS, "$1";
    } elsif (m/--attr\[([^\]]*)\]:\s*([^\s]*)[\s]*$/) {
      $ATTRS{$1} = $2;
    } elsif (m/--attr\[([^\]]*)\]:\s*/) {
      $ATTRS{$1} = "";
    } else {
      $TEST = $TEST."$_";
    }
  }
  close(SOURCE_FILE);
}
if (defined($TNAME)) {
  generate_test(\@TLOCS,\%ATTRS,$TEST);
}
print "\n$testcnt tests successfully generated!\n";
