#!/bin/bash

find . -type f -exec sh -c 'echo "=== {} ==="; cat "{}"' \; > output.txt

tree
