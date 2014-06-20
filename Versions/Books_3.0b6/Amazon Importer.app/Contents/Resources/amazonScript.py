#!/usr/bin/python

from amazon import Bag
from xml.dom.minidom import Document

import amazon
import sys

localeArgs = sys.argv[1]
fieldArgs = sys.argv[2]
query = sys.argv[3]

fieldMap = {
	  "Asin" : "ASIN",
      "Authors" : "Authors",
      "ImageUrlLarge" : "CoverImageURL",
      "ImageUrlMedium" : "ImageUrlMedium",
      "ImageUrlSmall" : "ImageUrlSmall",
      "Isbn" : "ISBN",
      "ListPrice" : "originalValue",
      "Manufacturer" : "publisher",
      "Media" : "format",
      "OurPrice" : "presentValue",
      "UsedPrice" : "UsedPrice",
      "ProductName" : "title",
      "ReleaseDate" : "publishDate",
      "URL" : "url",
      "ProductDescription" : "summary",
	  "Catalog" : "Catalog"
	}

locales = localeArgs.split(",")
fields = fieldArgs.split (",");

doc = Document ()
root = doc.createElement ("importedData")
doc.appendChild (root)

for searchLocale in locales:
	searchMode = "books"
	
	if (searchLocale != "us"):
		searchMode = "books-" + searchLocale
		
	for searchField in fields:

		if (searchLocale != "" and searchField != ""): 
			collection = doc.createElement ("List")
			collection.setAttribute ("name", "Amazon Import")
			root.appendChild (collection)
		
			pythonBooks = None;
	
			if searchField == "authors":
				pythonBooks = amazon.searchByAuthor (query, locale=searchLocale, mode=searchMode)
			elif searchField == "asin":
				pythonBooks = amazon.searchByASIN (query, locale=searchLocale, mode=searchMode)
			elif searchField == "upc":
				pythonBooks = amazon.searchByUPC (query, locale=searchLocale, mode=searchMode)
			else:
				pythonBooks = amazon.searchByKeyword (query, locale=searchLocale, mode=searchMode)

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
										authors += author + ", "
								else:
									authors += value.Author

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

print doc.toprettyxml(encoding="UTF-8", indent=" ")

sys.stdout.flush()



