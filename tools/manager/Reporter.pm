# Default implementation of report generator.
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
	
package Reporter;
use strict;
use IO::File;

require Exporter;
our @ISA = qw(Exporter);

#----------------------------------------------------------------------
# Report file
our $report;

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
# Summary statistics
my %stats_tests_total = ();
my %stats_tests_passed = ();
my %stats_tests_failed = ();

#----------------------------------------------------------------------
# ReqCoverage statistics
my %req_covered = ();
my %req_failed = ();

#----------------------------------------------------------------------
# Reports for each test suite
my %reports = ();  # $reports{$tsname} = $html_report_text
my $cur_test_group;

sub report {
  my ($text) = @_;

  $reports{$cur_test_group} .= $text;
}

my %meta_info = ();
my %anchors = ();
my %test_versions = ();
my %tool_versions = ();
my $num_test_groups = 0;

#----------------------------------------------------------------------
sub process_test_group_start {
  my ($self,$test_group) = @_;

  $stats_tests_total{$test_group} = 0;
  $stats_tests_passed{$test_group} = 0;
  $stats_tests_failed{$test_group} = 0;
  $anchors{$test_group} = "tg$num_test_groups";
  $num_test_groups++;
}

#----------------------------------------------------------------------
sub incr_stats($$)
{
  my ($stats,$test_groups) = @_;

  foreach my $tg (@$test_groups) {
    $stats->{$tg}++;
  }
}

#----------------------------------------------------------------------
# HTML colors
my $dark_gray       = "#555555";
my $gray            = "#C8C8C8";
my $neutral_gray    = "#888888";
my $light_gray      = "#F0F0F0";
my $dark_blue       = "#000080";
my $dark_green      = "#006600";
my $fluorescent_green   = "#40FF40";
my $fluorescent_yellow  = "#FFFF40";
my $fluorescent_red     = "#FF6060";
my $green           = "#00A000";

#----------------------------------------------------------------------
sub to_html {
  my $text = shift;

  # Escape HTML entities
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  $text =~ s/ /&nbsp;/g;
  $text =~ s/[\n\r]+/<br \/>\n/g;
    
  return $text;
}

#----------------------------------------------------------------------
my $msgbox_id = 0;
sub print_failure($$$)
{
    my $tool_adapter = shift;
    my $test_case  = shift;
    my $result = shift;

    # Choose the color for the specified message severity.
    my $color = "red";
    
    # Give the message box a unique ID.
    my $message_box_id = "msgbox" . $msgbox_id; $msgbox_id++;

    # Start the line (with attached script that opens the detail block
    # on clicking).
    report("<tr class=\"ptl_$color\" title='Click here!' onclick=\"flip('$message_box_id');\">");

    # Print the test case name.
    report("<td>");
    report("$test_case->{'name'}");
    report("</td>\n");

    # Print severity and resolution.
    report("<td>failed</td>\n");
    report("<td>$result->{'_FAILURE'}</td>\n");

    # Finish the line.
    report("</tr>\n");

    # Print the detail block, which is initially hidden and unrolls when
    # the table row is clicked (via the javascript above).
    report("<tr id=\"$message_box_id\" style=\"display:none;\">\n");
    report("<td colspan=\"3\">");
    report("<div style='padding-left:32px;'>");
    report("Messages from the test:\n");
    report("<div style=\"color:$dark_gray;padding-left:32px;\">\n");
    if (defined($result->{'LOG'})) {
      report("<p style='font-family:monospace'>");    
      report(to_html($result->{'LOG'}));
      report("</p>");
    } else {
        report("(none)");
    }
    report("\n</div>\n");
    if (defined($test_case->{'manifest'}->{"REQ"})) {
      my $req = $test_case->{'manifest'}->{"REQ"};
      report("Reference to the specification: <a href='specification.html#"."$req'>$req</a>\n");
    }
    report("</div>");
    report("</td>");
    report("</tr>\n");
}

#----------------------------------------------------------------------
sub count_reqcoverage {
  my ($self,$tool_adapter,$test_case,$result) = @_;
  my $manifest = $test_case->{'manifest'};
  
  if (defined($manifest->{"REQ"})) {
    my $req = $manifest->{"REQ"};
    $req_covered{$req} = (!defined($req_covered{$req})) ? 1 : $req_covered{$req}+1;
    if ($result->{'_VERDICT'} ne "PASS") {
      my $failure = "$tool_adapter->{'tool'} failed: $result->{'_FAILURE'}\n$result->{'LOG'}";
      if (!defined($req_failed{$req})) {
        $req_failed{$req} = $failure;
      } else {
        $req_failed{$req} = "$req_failed{$req}\n$failure";
      }
    }
  }	 
}

#----------------------------------------------------------------------
sub process_test_case_result {
  my ($self,$tool_adapter,$test_case,$result) = @_;
  my $test_suite = $test_case->{'parent'}->{'name'};
  my $tool = $tool_adapter->{'tool'};
  my $test_group = "$tool:$test_suite";
  my @test_groups = ($test_group);

  if (!defined $tool_versions{$tool}) {
    $tool_versions{$tool} = (defined($tool_adapter->{'version'}))?$tool_adapter->{'version'}:"";
  }

  my $ts = $test_case->{'parent'};
  while (defined($ts->{'parent'})) {
    $ts = $ts->{'parent'};
    push @test_groups, "$tool:$ts->{'name'}";
  }
  push @test_groups, "$tool";
  
  foreach my $tg (@test_groups) {
    if (!defined($stats_tests_total{$tg})) {
      $self->process_test_group_start($tg);
    }
  }
  $cur_test_group = $test_group;
  if (!defined($reports{$test_group})) {
    $reports{$test_group} = "";
  }

  incr_stats(\%stats_tests_total,\@test_groups);
  if ($result->{'_VERDICT'} eq "PASS") {
    incr_stats(\%stats_tests_passed,\@test_groups);
  } else {
    incr_stats(\%stats_tests_failed,\@test_groups);
    print_failure($tool_adapter,$test_case,$result);
  }
  $self->count_reqcoverage($tool_adapter,$test_case,$result);
}

#----------------------------------------------------------------------
sub process_meta_info {
  my ($self,$info) = @_;

  for my $key ( keys %$info ) {
    $meta_info{$key} = $info->{$key};
  }
}

#----------------------------------------------------------------------
sub init_report {
  my ($self,$REPORTDIR) = @_;

  # Open the report files.
  $report = new IO::File;
  unless ($report->open ("> $REPORTDIR/index.html")) {
      die ("Could not open the report file for writing: $REPORTDIR/index.html");
  }
}

#----------------------------------------------------------------------
sub print_header {
  $report->print ("<html>\n");
  $report->print ("
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
<style type=\"text/css\">
.ptl_gray { background: #E6E6E6;}
.ptl_gray:hover { background: #D6D6F0;}
.ptl_green { background: #CDFFCD;}
.ptl_green:hover { background: #A0FFA0;}
.ptl_yellow { background: #FFFFCD;}
.ptl_yellow:hover { background: #FFFF90;}
.ptl_red { background: #FFCDCD;}
.ptl_red:hover { background: #FFA0A0;}
.ptl_gray,.ptl_green,.ptl_yellow,.ptl_red { cursor: pointer; }
#.view_srv { display: none; }
.view_as_is { display: none; }
</style>
</head>
  ");
  $report->print ("<body>\n");
  $report->print ("
<script language=\"javascript\" type=\"text/javascript\">
// <![CDATA[
function flip (message_box_id) {
    msgbox = document.getElementById(message_box_id);
    if (msgbox.style.display != 'none') {
        msgbox.style.display = 'none';
    }
    else {
        msgbox.style.display = '';
    }
}
// ]]>
</script>
            ");
}

#----------------------------------------------------------------------
sub print_footer {
  $report->print ("</body>\n</html>\n");
  $report->close ();
}

#---------------------------------------------------------------------
# Prints a single line of a two-column table.
#
# Arguments:
# $1 - The first column.
# $2 - The second column.
# $3 (optional) - The foreground color of the second column.
# $4 (optional) - The background color of the second column.
sub two_column_table_line {
  my $first_column = shift;
  my $second_column = shift;
  my $foreground_color = shift;
  my $background_color = shift;
    
  # Build the style specifier for the second column.
  my $second_column_style = "padding: 2px; margin: 2px;";
    
  # If the second column contains a number, print it right-aligned.
#  if ($second_column =~ /^[0-9\.]*$/) {
   $second_column_style .= "text-align: right; ";
#  }
    
  # Apply the foreground and background colors if specified.
  if ($foreground_color) {
      $second_column_style .= "color: $foreground_color; ";
  }
  if ($background_color) {
      $second_column_style .= "background-color: $background_color; ";
  }
  else {
      $second_column_style .= "background-color: $light_gray; ";
  }
    
  # Print the line with appropriate decorations.
  return "<tr style=\"padding: 4px; margin: 4px;\">".
  "<td style=\"background-color:$gray;\">$first_column</td>\n".
  "<td style=\"$second_column_style\">$second_column</td>\n".
  "</tr>\n";
}

#----------------------------------------------------------------------
sub get_short_title($) {
  my ($test_group) = @_;
  my $res = $test_group;
  my $indent = "";

  foreach my $tg (sort keys %stats_tests_total) {
    if ($test_group =~ m/^$tg[:\/](.*)$/) {
      $res = $1;
      $indent .= "&nbsp;&nbsp;";
    }
    if ($test_group eq $tg) {
      return "$indent$res";
    }
  }
  return $res;
}

#---------------------------------------------------------------------
sub report_index_line($) {
  my $test_group = shift;
  my $display_test_group = get_short_title($test_group);
  
  # Cut the left spaces to bring it out of the hyperlink
  my $leftspace = "";
  if ($display_test_group =~ /^((\s|&nbsp;)+)(.*)/ ) {
      $leftspace = $1;
      $display_test_group = $3;
  }

  my $text = "";
  # Row starts
  $text .= "<tr style='background-color:".$gray."'>";
    
  # The first column: the hyperlink to the anchor in the report
  $text .= "<td>";
  $text .= "&nbsp;&nbsp;&nbsp;&nbsp;".$leftspace
          ."<b><a href='#".$anchors{$test_group}."'"
          ." title='Click here to proceed to details'>"
          .$display_test_group."</a></b>";
  $text .= "</td>\n";
    
  # The second column: version of the testsuite
  $text .= "<td>";
  if (defined($test_versions{$test_group})) {
      $text .= "&nbsp; <font size='-1' color='$gray'>v "
            .$test_versions{$test_group}."</font>";
  }
  $text .= "</td>\n";
    
  # The 3rd column: status
  my $bg_color = $gray;
  my $status = "";
  if ($stats_tests_failed{$test_group} > 0) {
      $bg_color = $fluorescent_red;
      $status = "Failures: ".$stats_tests_failed{$test_group};
  }
  else {
      $bg_color = $fluorescent_green;
      $status = "Success";
  }
  $text .= "<td style=\"background-color:$bg_color\">$status";
  $text .= "</td>\n";
 
  # The 4th column: number of passed tests
  $text .= "<td>";
  $text .= "<span style='color:black'>Passed: ".
          $stats_tests_passed{$test_group};
  $text .= "</span>";
  $text .= "</td>\n</tr>\n";
  return $text;
}

#----------------------------------------------------------------------
sub test_groups_sort {
  $a =~ m/^([^:]+):?(.*)$/;
  my $a1 = $1; my $a2 = $2;
  $b =~ m/^([^:]+):?(.*)$/;
  if ($1 eq $a1) {
    return ($a2 cmp $2);
  } else {
    return ($a1 cmp $1);
  }
}

#----------------------------------------------------------------------
sub print_body {
  my ($self) = @_;
  my $tools = join(", ",sort keys %tool_versions);
  $report->print ("<h1>Report for $tools run $ENV{'AADLRUN'}</h1>\n");

  $report->print ("<h3>Test Info</h3>\n");
    
  # Print general information
  $report->print (
  "<table>\n"
  .two_column_table_line("Tests Started At",  $meta_info{'global_start_time'} )
  .two_column_table_line("Tests Finished At", $meta_info{'global_finish_time'} )
  .two_column_table_line("Operating System",  $meta_info{'os'}) 
  ."</table>\n"
  );

  # Print the index
  $report->print("<h3>Tests executed</h3>");
  $report->print("<table border='0' cellpadding='2' cellspacing='1'>");

  my $indent = "&nbsp;";
  my $color  = "#b0b0ff";
  foreach my $test_group (sort test_groups_sort keys %stats_tests_total) {
    if (!defined($reports{$test_group}) ) {
      # Title only
      my $short_title = get_short_title($test_group);
      $report->print( "<tr><td colspan='4' style='background-color:$color'>"
                     ."$indent<b>$short_title</b></td></tr>");
    } else {
#      $report->print( "<tr style='background-color:#dbdbe8'><td>"
#                     ."$indent&nbsp;&nbsp;<font color='#224466'><b>$test_group:</b></font></td>"
#                     ."<td>&nbsp; <font size='-1' color='$dark_gray'>"
##                     .($test_versions{$journal_title}?"v "
##                     .$test_versions{$journal_title}:"")."</font></td>"
#                     ."</font></td>"
##
#                     ."<td colspan='2'></td></tr>"
#                    );
      $report->print( report_index_line($test_group) );
    }
  }
  $report->print("</table>");

  # Details for each test group
  foreach my $test_group (sort test_groups_sort keys %stats_tests_total) {
    if (defined($reports{$test_group}) ) {
      $report->print("<hr />\n");
      $report->print("<h2><a name=\"".$anchors{$test_group}
              ."\"></a><font color=\"#336699\">".$test_group."</font> &nbsp; <font size='-1' color='#888888'>"
              .($test_versions{$test_group}?"v ".$test_versions{$test_group}:"")."</font></h2>\n");
      $report->print("<h4>Problem Summary</h4>\n\n");
      if ($reports{$test_group} eq "") {
        $report->print("<p><font color='#006600'><b>No problems were detected.</b></font></p>\n");
      } else {
        $report->print("<p>Click on lines in the table to see the details " .
                       "about each problem.</p>\n\n");
        $report->print("<table width=\"100%\">\n");
        $report->print("<thead>\n");
        $report->print("<tr style=\"font-weight:bold; background-color:$gray;\">\n");
        $report->print("<td>Test Name</td><td>Severity</td><td>Failure</td>\n");
        $report->print("</tr>\n");
        $report->print("</thead>\n");
        $report->print("<tbody>\n");
        $report->print($reports{$test_group});
        $report->print("</tbody>\n");
        $report->print("</table>\n");
      }
    }
  }
}

#----------------------------------------------------------------------
sub generate_statistics {
  my ($self,$REPORTDIR) = @_;
  my $statistics_file_name = "$REPORTDIR/statistics";

  my $file;
  unless (open($file, "> $statistics_file_name")) {
      print "Couldn't open file '$statistics_file_name' for writing.\n";
      return;
  }

  foreach my $test_group (sort keys %stats_tests_total) {
    print $file "$test_group: $stats_tests_total{$test_group} $stats_tests_passed{$test_group} $stats_tests_failed{$test_group}\n";
  }

  close($file);
}

#----------------------------------------------------------------------
sub generate_reqcoverage {
  my ($self,$REPORTDIR) = @_;
  my $reqcoverage_file_name = "$REPORTDIR/reqcoverage";

  my $file;
  unless (open($file, "> $reqcoverage_file_name")) {
      print "Couldn't open file '$reqcoverage_file_name' for writing.\n";
      return;
  }
  my %reqcoverage = ('covered' => \%req_covered, 'failed' => \%req_failed);
#  print $file "---COVERED:\n";
#  foreach my $req (keys %req_covered) {
#    print $file "$req: $req_covered{$req}\n";
#  }

#  print $file "---FAILED:\n";
#  foreach my $req (keys %req_failed) {
#    print $file "--REQ: $req\n$req_failed{$req}";
#  }
  require YAML;
  print $file YAML::Dump(%reqcoverage);
  close($file);
}

#----------------------------------------------------------------------
sub generate_reqreport {
  my ($self,$REPORTDIR) = @_;
  my $requality_dir;
  my $reqcoverage_file_name = "$REPORTDIR/reqcoverage";
  my $requality = `which requality`;
  ($requality_dir)  = ($requality =~ m/(.*)\/bin(\/)+requality\s*$/);
  my $reqreport = "$1/reqreport/reqreport.pl";
  if (! -e $reqreport) {
    print STDERR "WARNING: reqreport.pl not found ($reqreport) $requality $requality_dir\n";
    return;
  }
  
  system("$reqreport $self->{'reqproject'} $self->{'reqbase'} $reqcoverage_file_name $REPORTDIR");
}

#----------------------------------------------------------------------
sub print_summary {
  my ($self) = @_;

  print "--SUMMARY--\n";
  foreach my $test_group (sort keys %stats_tests_total) {
    if ($test_group =~ m/^([^:]*)$/) {
      print "$1: $stats_tests_passed{$test_group} PASSED, $stats_tests_failed{$test_group} FAILED\n";
    }
  }
}

#----------------------------------------------------------------------
sub generate_report {
  my ($self,$REPORTDIR) = @_;
  $self->init_report($REPORTDIR);
  $self->print_header();
  $self->print_body();
  $self->print_footer();
  $self->generate_statistics($REPORTDIR);
  $self->generate_reqcoverage($REPORTDIR);
  $self->generate_reqreport($REPORTDIR);
  $self->print_summary();
}

#-----------------------------------------------------------------------
1; # return value
