#!/usr/bin/perl -w

use YAML;
use FindBin;

my $REQPROJECT = shift;
my $REQCOVERAGE = shift;
my $OUT = shift;

#----------------------------------------------------------------------
my %req2loc = ();
my %reqcoverage = ();

#----------------------------------------------------------------------
sub load_reqcatalogue($) {
  my ($REQFILE) = @_;
  my $TREQ;
	
  if (open (SOURCE_FILE, "<", $REQFILE)) {
    while (<SOURCE_FILE>) {
      if (m/---id:\s*\/Requirements\/(.*)\/([^\/\s]*)[\s]*$/) {
        $TREQ = "/Requirements/$1/$2";
	$req2loc{$TREQ} = ();
      } elsif (m/--location:\s*\/Documents\/([^\s]*)[\s]*$/) {
        push @{ $req2loc{$TREQ} }, "$1";
      } else {
        # Ignore Test code
      }
    }
    close(SOURCE_FILE);
  }
}

#----------------------------------------------------------------------
sub load_reqcoverage($) {
  my ($REQCOVERAGE) = @_;

  open(FILE, "<", $REQCOVERAGE) or die "can't open reqcoverage file: $!";
  my $content = do { local $/; <FILE> };
  close(FILE);
  %reqcoverage = Load($content);
}

#----------------------------------------------------------------------
my $script = <<ENDSCRIPT;
<div id="error_window" style="display: none; border: solid 1px black; position: absolute; z-index: 1000;" onclick="javascript:event.cancelBubble = true;"> 
<table cellpadding="0" cellspacing="0" border="0" style="width: 17em;"> 
  <tr style="background-color: #d0d0d0; color: black;"> 
    <td align="right" style="border-bottom: solid 1px black;"><img src="images/environment-spacer.gif" width="7" height="1" alt="" /></td> 
    <td align="center" width="100%" style="border-bottom: solid 1px black;"><b>Information</b></td> 
    <td align="right" style="border-bottom: solid 1px black;"><img src="images/close.png" onclick="javascript:initDialog(null);" width="20" height="20" title="Close" alt="X" style="cursor: pointer;" /></td> 
  </tr> 
  <tr> 
    <td colspan="3" style="padding: 5px; white-space: nowrap; background-color: #ffffd0;" id="error_text"></td> 
  </tr> 
</table> 
</div> 

<table cellpadding="0" cellspacing="0" border="0" style="display: none; position: absolute; z-index: 999;" id="shadow"> 
  <tr> 
    <td width="14" height="14" style="background: url('images/shadow_tl.png') no-repeat;"></td> 
    <td height="14" style="background: url('images/shadow_tc.png') repeat-x;"></td> 
    <td width="14" height="14" style="background: url('images/shadow_tr.png') no-repeat;"></td> 
  </tr> 
  <tr> 
    <td width="14" style="background: url('images/shadow_ml.png') repeat-y;"></td> 
    <td style="background: url('images/shadow_mc.png') repeat;" id="shadow_center"></td> 
    <td width="14" style="background: url('images/shadow_mr.png') repeat-y;"></td> 
  </tr> 
  <tr> 
    <td width="14" height="14" style="background: url('images/shadow_bl.png') no-repeat;"></td> 
    <td height="14" style="background: url('images/shadow_bc.png') repeat-x;"></td> 
    <td width="14" height="14" style="background: url('images/shadow_br.png') no-repeat;"></td> 
  </tr> 
</table>


<script type="text/javascript" language="javascript"> 
// <![CDATA[
 
// Array to store preloaded images.
var preload_images_arr = new Array();

// Preload images so that there was no flickering when showing previously invisible
// (and not loaded by the browser) picture.
function preload_images(image_names) {
        for (var i = 0; i < image_names.length; ++i) {
                var name = image_names[i];
                if (name.indexOf('themes/') != 0)
                        name = 'images/' + name;
                preload_images_arr[i] = new Image;
                preload_images_arr[i].src = name;
        }
}

preload_images(new Array('status_collapse.png', 'close.png', 'shadow_bc.png', 'shadow_bl.png', 'shadow_br.png', 'shadow_mc.png', 'shadow_ml.png', 'shadow_mr.png', 'shadow_tc.png', 'shadow_tl.png', 'shadow_tr.png'));
 
var just_shown_dialog = false;          // Indicates that the dialog was just shown (to prevent its hiding from onBodyClick)
var dialog = null;                      // The dialog itself
var dialog_caller = null;               // Element which caused the dialog to appear
var dialog_caller_class = null;         // Normal class name of the dialog caller (to be restored when the dialog is closed)
var dialog_shadow = document.getElementById('shadow');
var dialog_shadow_center = document.getElementById('shadow_center');
 
// Hides the previous dialog (if it was shown) and prepare data for
// displaying the new one.
// CALLER - the HTML element which caused the dialog to appear and (possibly)
// will change its appearance because of that.
function initDialog(caller) {
	if (dialog_caller && dialog_caller_class)
		dialog_caller.className = dialog_caller_class;
	dialog_shadow.style.display = 'none';
	if (dialog)
		dialog.style.display = 'none';
	if (!caller || (caller == dialog_caller)) {
		dialog_caller = null;
		dialog_caller_class = null;
		return false;
	}
	else {
		dialog_caller = caller;
		dialog_caller_class = caller.className;
		return true;
	}
}
 
// Shows the dialog at the specified position and adjusts the shadow below it.
function showDialog(show_dlg, pos) {
	dialog = show_dlg;
	dialog.style.left = pos.x + 'px';
	dialog.style.top = pos.y + 'px';
	dialog.style.display = '';
	just_shown_dialog = true;
	dialog_shadow_center.width = dialog.offsetWidth - 15;
	dialog_shadow_center.height = dialog.offsetHeight - 15;
	dialog_shadow.style.left = pos.x + 'px';
	dialog_shadow.style.top = pos.y + 'px';
	dialog_shadow.style.display = '';
}
 
function onBodyClick() {
	if (!just_shown_dialog)
		initDialog(null);
	just_shown_dialog = false;
}
 
var error_texts = new Array();
 
function show_hide_tooltip(elem_parent, id, event) {
	if (!initDialog(elem_parent))
		return;
	var tt_window = document.getElementById('error_window');
	if (tt_window) {
		var tt_text = document.getElementById('error_text');
		if (tt_text) {
			if (error_texts[id])
				tt_text.innerHTML = error_texts[id];
			else
				tt_text.innerHTML = '<font color="red"><b>Sorry, no information for this item was found!</b></font>';
			var scrollTop = document.body.scrollTop;
			if (scrollTop == 0)
			{
			    if (window.pageYOffset)
			        scrollTop = window.pageYOffset;
			    else
			        scrollTop = (document.body.parentElement) ? document.body.parentElement.scrollTop : 0;
			}
			var scrollLeft = document.body.scrollLeft;
			if (scrollLeft == 0)
			{
			    if (window.pageXOffset)
			        scrollLeft = window.pageXOffset;
			    else
			        scrollLeft = (document.body.parentElement) ? document.body.parentElement.scrollLeft : 0;
			}
			var div_top = event.clientY + scrollTop + 10;
			var div_left = event.clientX + scrollLeft + 500;
			tt_window.style.display = '';
			var div_width = (tt_window.style.pixelWidth || tt_window.offsetWidth);
			var wnd_width = (document.body.clientWidth || window.innerWidth);
			if (div_left + div_width > wnd_width + scrollLeft)
				div_left = wnd_width + scrollLeft - div_width;
			if (div_left < scrollLeft)
				div_left = scrollLeft;
			showDialog(tt_window, {x: div_left, y: div_top});
			event.cancelBubble = true;
		}
	}
}
 
function __onBodyClick() {
	initDialog(null);
}
 
// ]]>
</script>
<!-- SCRIPT PLACEHOLDER -->
ENDSCRIPT



sub generate_reqreport($$) {
my $REQPROJECT = shift;
my $OUTDIR = shift;
my %htmlfiles = ();
my $req2doc_init = "";

  # Extract all html files required
  foreach my $req (keys %req2loc) {
    foreach my $location (@{ $req2loc{$req} }) {
      if ($location =~ m/^(.*)\/([^\/]*)$/) {
        $htmlfiles{$1} = 1;
      } else {
        die "Unexpected location: $location";
      }
    }
  }
  # Copy all html files
  open(FILE, ">", "$OUTDIR/script.tmp");
  print FILE "$script";
  close(FILE);
  foreach my $htmlfile (keys %htmlfiles) {
    my $reqcss = ".requality_text_covered {background:#A0FFA0;} .requality_text_failed {background:#FFA0A0}";

    system("cp -rf $REQPROJECT/root/Documents/${htmlfile}_resources/* $OUTDIR/");
    system("sed -e 's!\\(/\\* Font Definitions \\*/\\)!$reqcss \\1!' $OUTDIR/${htmlfile} >$OUTDIR/$htmlfile.new && mv $OUTDIR/$htmlfile.new $OUTDIR/$htmlfile");
    system("sed -e \"s/<body/<body onclick=\\\"javascript:if \\(typeof\\(onBodyClick\\)!='undefined'\\) onBodyClick\\(\\);\\\"/\" $OUTDIR/${htmlfile} >$OUTDIR/$htmlfile.new && mv $OUTDIR/$htmlfile.new $OUTDIR/$htmlfile");
    system("sed -e '/<body/ {\n r $OUTDIR/script.tmp\n }' $OUTDIR/${htmlfile} >$OUTDIR/$htmlfile.new && mv $OUTDIR/$htmlfile.new $OUTDIR/$htmlfile");
  }
  system("cp -rf $FindBin::Bin/images $OUTDIR/");
  # Update status of locations
  foreach my $req (keys %{ $reqcoverage{'covered'} }) {
    my $failed;
    my $class = "covered";
    my $reqf = $req;
    $reqf =~ s/\//\\\//g;
    if (defined($reqcoverage{'failed'}->{$req})) {
      $failed = $reqcoverage{'failed'}->{$req};
      $class = "failed";
    }
#print "Process: $req [$class]\n";
    foreach my $location (@{ $req2loc{$req} }) {
#print "  loc: $location\n";
      if ($location =~ m/^(.*)\/([^\/]*)$/) {
        my $htmlfile = $1;
        my $locid = $2;
        $req2doc_init = $req2doc_init."req2doc['$req'] = \"$htmlfile\";\n";

        system("sed -e 's/requality_text id_$locid/requality_text_$class id_$locid/g' $OUTDIR/$htmlfile >$OUTDIR/$htmlfile.new && mv $OUTDIR/$htmlfile.new $OUTDIR/$htmlfile");
        if (defined($failed)) {
          system("sed -e \"s/\\(<a name=\\\"$locid\\\" id=\\\"id_$locid\\\" class=\\\"requality_id\\\">\\)/\\1 <a name=\\\"$reqf\\\"><\\/a><a href=\\\"#"."$locid\\\" onclick=\\\"javascript:show_hide_tooltip\\(this, '$reqf', event\\); return false;\\\"><img src=\\\"images\\/question.png\\\" width=\\\"16\\\" height=\\\"16\\\" alt=\\\"?\\\" \\/><\\/a>/\" $OUTDIR/$htmlfile >$OUTDIR/$htmlfile.new && mv $OUTDIR/$htmlfile.new $OUTDIR/$htmlfile");
          $failed =~ s/'/\\'/g;
          $failed =~ s/\n/<br\/>/g;
          my $init_script = <<ENDSCRIPT;
<script type="text/javascript" language="javascript"> 
// <![CDATA[
error_texts['$req'] = '<pre>$failed</pre>';
// ]]>
</script>
ENDSCRIPT
          open(FILE, ">", "$OUTDIR/script.tmp");
          print FILE "$init_script";
          close(FILE);
          system("sed -e '/<!-- SCRIPT PLACEHOLDER -->/ {\n r $OUTDIR/script.tmp\n }' $OUTDIR/${htmlfile} >$OUTDIR/$htmlfile.new && mv $OUTDIR/$htmlfile.new $OUTDIR/$htmlfile");
        }
      }
    }
  }
  system("rm -f $OUTDIR/script.tmp");

  my $req2doc = <<ENDDOC;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
</head>
<body onload="javascript: onLoad();">

<script type="text/javascript" language="javascript"> 
// <![CDATA[

var req2doc = new Array();

$req2doc_init

function onLoad() {
  var req;
  var arr = document.location.toString().split("#");
  var msg = document.getElementById("message");
  if(arr.length > 1)
  {
    req = arr[1];
    if (req2doc[req]) {
      document.location = req2doc[req] + "#" + req;
    } else {
      msg.innerText = "Requirement '" + req + "' not found";
    }
  } else {
    msg.innerText = "No requirement selected";
  }
}


// ]]>
</script>

<p id="message"> </p>
</body>
ENDDOC

  open(FILE, ">", "$OUTDIR/specification.html");
  print FILE "$req2doc";
  close(FILE);
}

my $reqbase = "$REQPROJECT/reqdb.txt";
load_reqcatalogue($reqbase);
load_reqcoverage($REQCOVERAGE);
generate_reqreport($REQPROJECT,$OUT);


