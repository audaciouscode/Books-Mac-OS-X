#!/bin/bash

# /usr/bin/ruby xml2csv.rb /tmp/books-export/books-export.xml > /tmp/books-export/books.csv

echo title \"$1\" > /tmp/books-export/palm.info
cat ./palm.info >> /tmp/books-export/palm.info

if [ `/usr/bin/uname -p` = "powerpc" ]; then
	./ppc/csv2pdb -i /tmp/books-export/palm.info /tmp/books-export/books.csv "$3"
else
	./intel/csv2pdb -i /tmp/books-export/palm.info /tmp/books-export/books.csv "$3"
fi