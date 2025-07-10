#!/bin/bash
echo "NON_INTERACTIVE=0"
[[ ! -t 0 ]] && echo "NON_INTERACTIVE=1"
echo "Testing output..."
if [[ ! -t 0 ]]; then
    echo "This is NON-INTERACTIVE mode"
else
    echo "This is INTERACTIVE mode"
fi
