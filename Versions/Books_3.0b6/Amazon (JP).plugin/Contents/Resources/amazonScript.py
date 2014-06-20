#!/usr/bin/python

from amazon import Bag
from xml.dom.minidom import Document, parse
from difflib import SequenceMatcher
from string import replace

import amazon
import sys

searchLocale = "jp"

fieldMap = {
	 "Asin" : "ASIN",
	 "BrowseList" : "Genres",
 "Authors" : "Authors",
 "ImageUrlLarge" : "CoverImageURL",
 "ImageUrlMedium" : "ImageUrlMedium",
 "ImageUrlSmall" : "ImageUrlSmall",
 "Isbn" : "isbn",
 "ListPrice" : "originalValue",
 "Manufacturer" : "publisher",
 "Media" : "format",
 "OurPrice" : "presentValue",
 "UsedPrice" : "UsedPrice",
 "ProductName" : "title",
 "ReleaseDate" : "publishDate",
 "URL" : "url",
	 "Reviews" : "reviews",
 "ProductDescription" : "summary",
	 "Catalog" : "Catalog"
	}

book = None

dom = parse ("/tmp/books-quickfill.xml")

fields = dom.getElementsByTagName ("field")

title = ""
authors = ""
publisher = ""
upc = None
isbn = None

for field in fields:
	field.normalize ()

	fieldData = None
	
	if (field.firstChild != None):
		fieldData = replace (replace (replace (field.firstChild.data, "&", ""), "(", ""), ")", "");
 
	if (fieldData != None):
		if (field.getAttribute ("name") == "title"):
			title = fieldData
		elif (field.getAttribute ("name") == "authors"):
			authors = fieldData
		elif (field.getAttribute ("name") == "isbn"):
			isbn = fieldData
		elif (field.getAttribute ("name") == "upc"):
			upc = fieldData
		elif (field.getAttribute ("name") == "publisher"):
			publisher = fieldData

pythonBooks = None

if (isbn != None):
	isbn = replace (replace (isbn, "-", ""), " ", "");
	
	pythonBooks = amazon.searchByASIN (isbn, locale=searchLocale)

	if (pythonBooks[0] != None):
		book = pythonBooks[0]

# if (book == None and upc != None):
#	pythonBooks = amazon.searchByUPC (upc, locale=searchLocale)
#
#	if (pythonBooks[0] != None):
#		book = pythonBooks[0]

if (book == None and title != ""):
	query = "title:" + title
 
 	if (authors != ""):
 		query = query + " and author:" + authors

 	if (publisher != ""):
 		query = query + " and publisher:" + publisher

	pythonBooks = amazon.searchByPower (query, locale=searchLocale)
	
	if (pythonBooks[0] != None):
		book = pythonBooks[0]

doc = Document ()
root = doc.createElement ("importedData")
doc.appendChild (root)

searchMode = "books"
	
if (searchLocale != "us"):
	searchMode = "books-" + searchLocale
		
if (book != None): 
	collection = doc.createElement ("List")
	collection.setAttribute ("name", "Amazon Import")
	root.appendChild (collection)
	
	for book in pythonBooks:
		bookElement = doc.createElement ("Book")
		bookElement.setAttribute ("title", book.ProductName)
			
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
				if (isinstance (value, Bag)):
					if (key == "Authors"):
						authors = ""
						
						if (isinstance (value.Author, list)):
							for author in value.Author:
								authors += author + "; "
						else:
							authors += value.Author

						fieldElement = doc.createElement ("field")
						fieldElement.setAttribute ("name", "authors");

						textElement = doc.createTextNode (authors)
						
						fieldElement.appendChild (textElement)
						bookElement.appendChild (fieldElement)

					elif (key == "Reviews"):
						fieldElement = doc.createElement ("field")
						fieldElement.setAttribute ("name", "hasreviews");
						textElement = doc.createTextNode ("true")
						fieldElement.appendChild (textElement)
						bookElement.appendChild (fieldElement)

						if (isinstance (value.CustomerReview, list)):
							for review in value.CustomerReview:
								fieldElement = doc.createElement ("field")
								fieldElement.setAttribute ("name", "Review");

								textElement = doc.createTextNode (review.Summary + ": " + review.Comment)
						
								fieldElement.appendChild (textElement)
								bookElement.appendChild (fieldElement)

					elif (key == "BrowseList"):
						genre = ""

						if (isinstance (value.BrowseNode, list)):
							for browseNode in value.BrowseNode:
								genre = genre + browseNode.BrowseName + "; "
						else:
							genre = value.BrowseNode.BrowseName

						fieldElement = doc.createElement ("field")
						fieldElement.setAttribute ("name", "genre");

						textElement = doc.createTextNode (genre)

						fieldElement.appendChild (textElement)
						bookElement.appendChild (fieldElement)								


				else:
					fieldElement = doc.createElement ("field")
					fieldElement.setAttribute ("name", name);

					textElement = doc.createTextNode (value)
						
					fieldElement.appendChild (textElement)
					bookElement.appendChild (fieldElement)
				
		collection.appendChild (bookElement)

print doc.toprettyxml(encoding="UTF-8", indent=" ")

sys.stdout.flush()
