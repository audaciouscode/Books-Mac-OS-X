#!/bin/sh

/usr/bin/xsltproc tab-delimited.xsl /tmp/books-export/books-export.xml > "$1"
