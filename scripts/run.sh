#!/bin/sh

WAKUCANARY=./bin/wakucanary

for node in `cat nodes.txt`; do
    ${WAKUCANARY} -a=${node} -p=relay
    echo $?
done