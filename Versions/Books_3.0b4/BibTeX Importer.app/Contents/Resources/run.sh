#!/bin/bash

./bibtex2xml.py "$1" > /tmp/books-bibtex
./bibReader.rb /tmp/books-bibtex
