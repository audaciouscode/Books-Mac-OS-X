#!/usr/bin/ruby

require "rexml/document"

mapping = { 	'Title' => 'title', 
				'Authors' => 'authors', 
				'Format' => 'format', 
				'Genre' => 'genre', 
				'Series' => 'series', 
				'No. of Pages' => 'length', 
				'Publication Date' => 'publishDate', 
				'Publisher' => 'publisher', 
				'Place Published' => 'publishPlace', 
				'Editors' => 'editors', 
				'Edition' => 'edition', 
				'Illustrators' => 'illustrators', 
				'Translators' => 'translators', 
				'Keywords' => 'keywords', 
				'Description' => 'summary' }

filepath = ARGV[0]

listxmlpath = filepath + "/Contents/Resources/list.xml"

listxml = nil

begin
	listxml = REXML::Document.new(File.new(listxmlpath))
rescue
	listxmlpath = filepath + "/Contents/Resources/Books"

	listxml = REXML::Document.new

	list = listxml.add_element("list")
	
	Dir.foreach(listxmlpath) do |file|
		if (file =~ /book$/)
			book = list.add_element("book")
			book.attributes["file"] = file
		end
	end
end

outputxml = REXML::Document.new

import = outputxml.add_element("importedData")
collection = import.add_element("List")
collection.attributes["name"] = filepath

bookcount = 0

listxml.elements().each("/list/book") do |book_element|

	if (bookcount >= 512)
		collection = import.add_element("List")
		collection.attributes["name"] = filepath
	end
	
	book = collection.add_element("Book")
	
	bookpath = filepath + "/Contents/Resources/Books/" + book_element.attributes["file"]
	
	bookxmlpath = bookpath + "/Contents/Resources/definition.xml"

	begin
		bookxml = REXML::Document.new(File.new(bookxmlpath))

		bookxml.elements().each("/definition/property") do |bookproperty|
			name = bookproperty.attributes["name"]
			type = bookproperty.attributes["type"]

			field = book.add_element("field")

			if (name.to_s() == "Cover Image")
				field.attributes["name"] = "CoverImageURL"

				field.add_text("file://" + bookpath + "/" + bookproperty.text)
			else
				newname = mapping[name]
			
				if (newname == nil)
					newname = name
				end
			
				if (newname == "title")
					book.attributes["title"] = bookproperty.text
				end
			
				field.attributes["name"] = newname

				field.add_text(bookproperty.text)
			end
		end
	rescue
	
	end
end

outputxml.write($stdout,0,false,false)