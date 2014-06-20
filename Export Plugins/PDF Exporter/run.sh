#!/bin/bash

/usr/bin/xsltproc --stringparam date "`date`" "$1" "$2" > /tmp/books-export/output.fo

CLASSPATH="."

for i in `ls ./fop-jars`; do 
	CLASSPATH=$CLASSPATH:./fop-jars/$i
done

rm "$3"

if [ -e ../../../../../../Fonts/ARIALUNI*.TTF ] ; then
	/usr/bin/java -cp $CLASSPATH org.apache.fop.cli.Main -c config.xml /tmp/books-export/output.fo "$3"
elif [ -e /Library/Fonts/ARIALUNI*.TTF ] ; then 
	/usr/bin/java -cp $CLASSPATH org.apache.fop.cli.Main -c config.xml /tmp/books-export/output.fo "$3"
elif [ -e ../../../../../../Fonts/Cyberbit.ttf ] ; then
	/usr/bin/java -cp $CLASSPATH org.apache.fop.cli.Main -c config-cyberbit.xml /tmp/books-export/output.fo "$3"
elif [ -e /Library/Fonts/Cyberbit.ttf ] ; then 
	/usr/bin/java -cp $CLASSPATH org.apache.fop.cli.Main -c config-cyberbit.xml /tmp/books-export/output.fo "$3"
else
	/usr/bin/java -cp $CLASSPATH org.apache.fop.cli.Main /tmp/books-export/output.fo "$3"
fi

rm /tmp/books-export/output.fo