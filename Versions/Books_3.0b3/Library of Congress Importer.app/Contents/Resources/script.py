#!/usr/bin/python

from PyZ3950 import zoom
from PyZ3950.zmarc import *
from xml.dom.minidom import Document, parseString

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

query = sys.argv[1]
field = sys.argv[2]

if (field == "Author"):
	field = "au"
elif (field == "ISBN"):
	field = "isbn"
elif (field == "LCCN"):
	field = "lccn"
else:
	field = "ti"

conn = zoom.Connection ('z3950.loc.gov', 7090)
conn.databaseName = 'VOYAGER'
conn.preferredRecordSyntax = 'USMARC'

query = zoom.Query ('CCL', field + "=" + query)

doc = Document ()
root = doc.createElement ("importedData")
doc.appendChild (root)
collection = doc.createElement ("List")
collection.setAttribute ("name", "Library of Congress Import")
root.appendChild (collection)

res = conn.search (query)

count = 0

for r in res:
	m = MARC (MARC=r.data)

	bookElement = doc.createElement ("Book")

	makeField (doc, bookElement, "Library of Congress Control Number", m, 10, 'a')
	makeField (doc, bookElement, "ISBN", m, 20, 'a')
	makeField (doc, bookElement, "ISSN", m, 22, 'a')
	makeField (doc, bookElement, "Library of Congress Classification Number", m, 50, 'a')
	makeField (doc, bookElement, "title", m, 245)
	makeField (doc, bookElement, "authors", m, 100)
	makeField (doc, bookElement, "edition", m, 250, 'a')
	makeField (doc, bookElement, "publishPlace", m, 260, 'a')
	makeField (doc, bookElement, "publisher", m, 260, 'b')
	makeField (doc, bookElement, "publishDate", m, 260, 'c')
	makeField (doc, bookElement, "Language", m, 456, 'a')
	makeField (doc, bookElement, "genre", m, 655, 'a')

#	t = MARC8_to_Unicode ()
#	
#	fieldElement = doc.createElement ("field")
#	fieldElement.setAttribute ("name", "MARC Record")
#	textElement = doc.createTextNode (t.translate (m.toMARCXML ()))
#	fieldElement.appendChild (textElement)
#	bookElement.appendChild (fieldElement)

	collection.appendChild (bookElement)

	if count > 50:
		break

	count = count + 1
	
conn.close ()

print doc.toprettyxml(encoding="UTF-8", indent=" ")

sys.stdout.flush()

