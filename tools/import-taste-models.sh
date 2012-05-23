#!/bin/sh

#This script is designed to import TASTE GUI examples
#into AADL-QA suite. This is not meant to be used
#directly by users, only by TASTE developers to populate
#automatically src/ directory with relevant examples.

#Configuration variables
AADLQADIR=/home/julien/wip/aadl-qa
TASTEDIR=/home/julien/wip/taste
TASTEGUIDIR=${TASTEDIR}/tastegui/

#######################################################
#######################################################


mkdir -p ${AADLQADIR}/tests/taste

echo "DESCRIPTION=Examples from TASTE GUI tool" > ${AADLQADIR}/tests/taste/MANIFEST.TS

for v in `ls ${TASTEGUIDIR}/examples/ | grep -v svn`; do
   if [ -d ${TASTEGUIDIR}/examples/$v ]; then
      if [ -f ${TASTEGUIDIR}/examples/$v/project.taste ]; then
         EXPORTDIR=${AADLQADIR}/tests/taste/tastegui-$v
         echo Exporting model $v in $EXPORTDIR
         (cp -f ${TASTEGUIDIR}/examples/$v/project.taste /tmp/)
         (cd /tmp/ && tar xzvf project.taste) >/dev/null 2>&1
         (mkdir -p ${EXPORTDIR}) >/dev/null 2>&1
         (cd /tmp/ && tar xzvf project.taste) >/dev/null 2>&1
         (cd /tmp/ && cp -f dataview.aadl ${EXPORTDIR}) >/dev/null 2>&1
         (cd /tmp/ && cp -f deploymentview.aadl ${EXPORTDIR}) >/dev/null 2>&1
         (cd /tmp/ && cp -f interfaceview.aadl ${EXPORTDIR}) >/dev/null 2>&1
         echo EXPECTED_RESULT=VALID > ${EXPORTDIR}/MANIFEST.TC
         echo OCARINA_USE_COMPONENTS_LIBRARY=NO >> ${EXPORTDIR}/MANIFEST.TC
         echo OCARINA_INSTANTIATE=YES >> ${EXPORTDIR}/MANIFEST.TC
         echo OCARINA_INSTANCES_NAMES=deploymentview.others interfaceview.others >> ${EXPORTDIR}/MANIFEST.TC
      fi
   fi
done
