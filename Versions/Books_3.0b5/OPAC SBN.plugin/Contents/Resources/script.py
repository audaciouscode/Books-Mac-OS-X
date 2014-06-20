#!/usr/bin/python

from string import replace
from PyZ3950 import zoom
from PyZ3950.zmarc import *
from xml.dom.minidom import Document, parseString, parse

def getMarcValues (record, dataField, subField):
	values = []

	m = MARC8_to_Unicode ()
	
	try:	
		for df in record.fields[dataField]:
			items = []
			
			if (subField == None):
				for sf in df[2]:
					items.append (m.translate (sf[1]))
			else:
				for sf in df[2]:
			
					if sf[0] == subField:
						items.append (m.translate (sf[1]))
						
			values.append (items)

	except KeyError:
		pass

	return values

def makeField (document, book, name, record, dataField, subField=None):
	values = getMarcValues (record, dataField, subField)

	stringValue = ""
	for value in values:
		if (stringValue != ""):
			stringValue += "; "

		itemValue = ""
		
		for item in value:
			if (itemValue != ""):
				itemValue += " "
			itemValue += item
			
		stringValue += itemValue

	if (stringValue != ""):
		if (name == "title"):
			book.setAttribute ("title", stringValue)

		fieldElement = document.createElement ("field")
		fieldElement.setAttribute ("name", name);
		textElement = document.createTextNode (stringValue)
		fieldElement.appendChild (textElement)
		book.appendChild (fieldElement)

# Start program
		
dom = parse ("/tmp/books-quickfill.xml")

fields = dom.getElementsByTagName ("field")

title = ""
authors = ""
isbn = None

for field in fields:
	field.normalize ()
	
	if (field.firstChild != None):
		if (field.getAttribute ("name") == "title"):
			title = "" + field.firstChild.data
		elif (field.getAttribute ("name") == "authors"):
			authors = "" + field.firstChild.data
		elif (field.getAttribute ("name") == "isbn"):
			isbn = "" + field.firstChild.data

queryString = ''

if (isbn != None):
#	isbn = replace (replace (isbn, "-", ""), " ", "");
	queryString = 'isbn="' + isbn + '"' 

# elif (field == "LCCN"):
# 	field = "lccn"
else:
	queryString = 'ti="' + title + '"'
	
	if (authors != ""):
		queryString = queryString + ' and au="' + authors + '"'

conn = zoom.Connection ('opac.sbn.it', 3950)
conn.databaseName = 'nopac'
conn.preferredRecordSyntax = 'USMARC'

query = zoom.Query ('CCL', str(queryString))
query

doc = Document ()
root = doc.createElement ("importedData")
doc.appendChild (root)
collection = doc.createElement ("List")
collection.setAttribute ("name", "Importato dall\'OPAC SBN")
root.appendChild (collection)

res = conn.search (query)

count = 0

for r in res:
	m = MARC (MARC=r.data)

	bookElement = doc.createElement ("Book")

	makeField (doc, bookElement, "Library of Congress Control Number", m, 1, 'a')
	makeField (doc, bookElement, "ISBN", m, 20, 'a')
	makeField (doc, bookElement, "ISSN", m, 35, 'a')
	makeField (doc, bookElement, "Library of Congress Classification Number", m, 5, 'a')
	makeField (doc, bookElement, "title", m, 245, 'a')
	makeField (doc, bookElement, "authors", m, 100, 'a')
	makeField (doc, bookElement, "edition", m, 490, 'a')
	makeField (doc, bookElement, "publishPlace", m, 260, 'a')
	makeField (doc, bookElement, "publisher", m, 260, 'b')
	makeField (doc, bookElement, "publishDate", m, 260, 'c')
	makeField (doc, bookElement, "Language", m, 44, 'a')
	makeField (doc, bookElement, "genre", m, 655, 'a')
	makeField (doc, bookElement, "editors", m, 700, 'a')

	collection.appendChild (bookElement)

	if count > 50:
		break

	count = count + 1
	
conn.close ()

print doc.toprettyxml(encoding="UTF-8", indent=" ")

sys.stdout.flush()

