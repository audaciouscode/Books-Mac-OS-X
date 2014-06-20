#!/bin/sh

JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.5/Home

$JAVA_HOME/bin/java -jar ipod.jar /tmp/books-export/books-export.xml "$1"