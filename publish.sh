#!/bin/sh

make policy.html
FILES="$(find . -maxdepth 1 -type f -name '*.html' -printf '%f ')"
scp $FILES opal@master.debian.org:public_html/java
