#!/usr/bin/ruby

require "rexml/document"
require "pathname"

listxmlpath = ARGV[0]

listxml = REXML::Document.new(File.new(listxmlpath))

outputxml = REXML::Document.new

import = outputxml.add_element("importedData")
collection = import.add_element("List")
collection.attributes["name"] = listxmlpath

bookcount = 0

listxml.elements().each("/exportData/Book") do |book_element|
	book = collection.add_element("Book")
	
	book_element.elements().each("field") do |bookfield|
		name = bookfield.attributes["name"]

		field = book.add_element("field")

		field.attributes["name"] = name

		if (name == "coverImage")
			p = Pathname.new(listxmlpath)
			
			field.add_text(p.dirname.to_s + "/" + bookfield.text)		
		else
			field.add_text(bookfield.text)
		end
	end
end

outputxml.write($stdout,0,false,false)