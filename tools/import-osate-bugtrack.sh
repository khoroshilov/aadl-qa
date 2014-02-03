#!/bin/sh

rm -rf /tmp/osate-examples
(cd /tmp && git clone https://github.com/osate/examples.git osate-examples)
mv /tmp/osate/examples/bugtrack-core ../osate-bugtrack-core
mv /tmp/osate/examples/bugtrack-emv2 ../osate-bugtrack-emv2
mv /tmp/osate/examples/bugtrack-plugins ../osate-bugtrack-plugins