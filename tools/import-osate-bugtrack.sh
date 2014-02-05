#!/bin/sh
testdir=`pwd`/../tests/
#rm -rf /tmp/osate-examples
#(cd /tmp && git clone https://github.com/osate/examples.git osate-examples)

for suite in bugtrack-core bugtrack-emv2 bugtrack-plugins; do
(cd /tmp/osate-examples/$suite
for v in *; do
  if [ -d $v ]; then
    if [ ! -d "$testdir/osate-$suite/$v" ]; then
      mkdir -p "$testdir/osate-$suite/$v" ;
      cp -rf $v/* "$testdir/osate-$suite/$v/" ;
    fi
    if [ ! -f "$testdir/osate-$suite/$v/MANIFEST.TC" ]; then
      echo "OCARINA_USE_COMPONENTS_LIBRARY=NO" >> "$testdir/osate-$suite/$v/MANIFEST.TC" ;
      echo "EXPECTED_RESULT=valid" >> "$testdir/osate-$suite/$v/MANIFEST.TC"  ;
      echo "DESCRIPTION=initial test for bug $v on the OSATE bugtrack for project $v" >> "$testdir/osate-$suite/$v/MANIFEST.TC" 
    fi
  fi
  if [ ! -f "$testdir/osate-$suite/MANIFEST.TS" ]; then
      echo "DESCRIPTION=testsuite for OSATE, project $suite" >> "$testdir/osate-$suite/MANIFEST.TS" ; 
  fi
done)
done

