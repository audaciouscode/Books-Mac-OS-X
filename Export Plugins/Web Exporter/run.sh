#!/bin/bash

src="/tmp/books-export/books-export.xml"
dest=$1

rm -R "$dest - Old"
mv "$dest" "$dest - Old"

/System/Library/Frameworks/JavaVM.framework/Versions/1.5/Home/bin/java -Xmx1024M \
	-cp web-export.jar -Djava.awt.headless=true net.aetherial.books.webexporter.WebExporter "$src" "$dest"
	
cp -R resources/* "$dest"

xsltproc slim-export.xsl "$src" > "$dest"/books-export.xml
# cp "$src" "$dest"