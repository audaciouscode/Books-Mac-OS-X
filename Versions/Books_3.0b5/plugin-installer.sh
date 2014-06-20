#!/bin/bash

mkdir /tmp/books-plugin-update

cd /tmp/books-plugin-update

curl -s $1 > download.tbz

tar -xjf download.tbz

rm download.tbz

mkdir ~/Library/Application\ Support/Books/Plugins

cp -Rf * ~/Library/Application\ Support/Books/Plugins

cd /tmp

rm -R /tmp/books-plugin-update