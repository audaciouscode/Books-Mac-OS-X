#!/usr/bin/python

from xml.dom.minidom import Document
from xml.parsers.expat import *

from ecs import *
import ecs

import sys

localeArgs = sys.argv[1]
fieldArgs = sys.argv[2]
query = sys.argv[3]

fieldMap = {
	  "ASIN" : "ISBN",
      "Author" : "authors",
      "Manufacturer" : "publisher",
      "Title" : "title",
      "DetailPageURL" : "url",
	}

locales = localeArgs.split(",")
fields = fieldArgs.split (",");

ecs.setLicenseKey('1M21AJ49MF6Y0DJ4D1G2')

doc = Document ()
root = doc.createElement ("importedData")
doc.appendChild (root)

for searchLocale in locales:
	searchMode = "Books"
	
	if (searchLocale != "us"):
		searchMode = "Books-" + searchLocale
		
	for searchField in fields:

		if (searchLocale != "" and searchField != ""): 
			collection = doc.createElement ("List")
			collection.setAttribute ("name", "Amazon Import")
			root.appendChild (collection)
		
			pythonBooks = None;
	
			if searchField == "authors":
				pythonBooks = ecs.ItemSearch('', Author=query, SearchIndex=searchMode)
			elif searchField == "asin":
				pythonBooks = ecs.ItemLookup(query)
			else:
				pythonBooks = ecs.ItemSearch('', Title=query, SearchIndex=searchMode)

			for book in pythonBooks:
				try:
					bookElement = doc.createElement ("Book")
					# book = ecs.ItemLookup(book.ASIN)[0]
		
					bookElement.setAttribute ("title", book.Title)
					
					print (book.Title + ": " + str(dir(book)))
				
					for key in fieldMap.keys():
						name = fieldMap[key]
					
						if name == None:
							name = key

						value = None
					
						try:
							value = getattr(book, key)
						except AttributeError:
							pass
						
						if (value != None):
							if (key == "Author"):
								authors = ""
								
								if (isinstance (value, list)):
									for author in value:
										authors += author + ", "
								else:
									authors += value

								fieldElement = doc.createElement ("field")
								fieldElement.setAttribute ("name", "authors");

								textElement = doc.createTextNode (authors)
						
								fieldElement.appendChild (textElement)
								bookElement.appendChild (fieldElement)
							else:
								fieldElement = doc.createElement ("field")
								fieldElement.setAttribute ("name", name);
	
								textElement = doc.createTextNode (value)
							
								fieldElement.appendChild (textElement)
								bookElement.appendChild (fieldElement)
				
					collection.appendChild (bookElement)
				except ExpatError:
					pass
				

print doc.toprettyxml(encoding="UTF-8", indent=" ")

sys.stdout.flush()



