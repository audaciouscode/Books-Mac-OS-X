#!/bin/bash

/usr/bin/xsltproc xml-java.xsl "$1" > src/net/aetherial/books/me/BookCollection.java 

JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.4/Home

./ant/bin/ant -Darch=`/usr/bin/uname -p`

cp /tmp/books-build/bin/Books.jar ~/Desktop

rm -R /tmp/books-build


