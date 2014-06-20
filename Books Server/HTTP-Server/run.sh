#!/bin/bash

JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.5/Home/

CLASSPATH=.

for i in `ls ./lib/*.jar`; do
	CLASSPATH=$CLASSPATH:$i;
done

$JAVA_HOME/bin/java -cp $CLASSPATH net.aetherial.books.export.http.HTTPExporter "$1" docroot $2 "$3"
