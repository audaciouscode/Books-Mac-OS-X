#!/usr/bin/ruby
		
require "rexml/document"
require 'net/http'

mapping = { 	'Title' => 'title', 
				'AuthorsText' => 'authors', 
				'PublisherText' => 'publisher', 
				'Summary' => 'summary'
			}

listxml = REXML::Document.new(File.new("/tmp/books-quickfill.xml"))
#listxml = REXML::Document.new(File.new("books-quickfill.xml"))

listxml.elements().each("//field[@name='isbn']") do |field|
	isbn = field.text

	outputxml = REXML::Document.new
	import = outputxml.add_element("importedData")
	collection = import.add_element("List")
	collection.attributes["name"] = "ISBNdb Import - " + isbn
	
	host = "isbndb.com"
	url = "/api/books.xml?access_key=UUFWT4M3&index1=isbn&value1=" + isbn + "&results=texts"
	xmldata = Net::HTTP.start(host, 80) { |http| http.get(url).response.body }
	
	dbxml = REXML::Document.new(xmldata)

	dbxml.elements().each("/ISBNdb/BookList/BookData") do |book_element|
		book = collection.add_element("Book")

		bookField = book.add_element("field")
		bookField.attributes["name"] = "isbn"
		bookField.add_text(book_element.attributes["isbn"])
		
		book_element.elements().each() do |bookField|
			fieldName = mapping[bookField.name]
			
			if (fieldName == nil)
				fieldName = bookField.name
			end

			if (bookField.text != nil)
				outField = book.add_element("field")
				outField.attributes["name"] = fieldName
				outField.add_text(bookField.text)
			end
		end
	end

 	outputxml.write($stdout,0,false,false)
end

