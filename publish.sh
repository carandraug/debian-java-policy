#!/bin/sh

make policy.html
scp debian-java-policy.html/*html opal@people.debian.org:public_html/java
