#!/bin/bash

INPUT_FILE=$1

# start tags
sed -i "s/┋PAGE-tag:\s*\(\w*\)┊/<PAGE tag=\"\1\">/g" $INPUT_FILE
sed -i "s/┋CONV-tag:\(\w*\)┊/<CONV tag=\"\1\">/g" $INPUT_FILE

# end tags
sed -i "s/┊PAGE-tag:\s*\(\w*\)┋/<\/PAGE>/g" $INPUT_FILE
sed -i "s/┊CONV-tag:\(\w*\)┋/<\/CONV>/g" $INPUT_FILE