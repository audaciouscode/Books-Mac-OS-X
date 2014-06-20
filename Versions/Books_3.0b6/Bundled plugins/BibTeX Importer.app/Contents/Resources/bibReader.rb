#!/usr/bin/ruby

require "rexml/document"

mapping = {		'bibtex:author' => 'authors', 
				'bibtex:title' => 'title', 
				'bibtex:publisher' => 'publisher', 
				'bibtex:address' => 'publishPlace', 
				'bibtex:pages' => 'length', 
				'bibtex:keywords' => 'keywords', 
				'bibtex:title' => 'title', 
				'bibtex:abstract' => 'summary', 
				'bibtex:edition' => 'edition', 
				'bibtex:editor' => 'editors', 
				'bibtex:series' => 'series', 
				'bibtex:bibdate' => 'publishDate', 
				'bibtex:year' => 'publishDate', 
				'bibtex:isbn' => 'isbn' }

filepath = ARGV[0]

bibxml = REXML::Document.new(File.new(filepath))

outputxml = REXML::Document.new

import = outputxml.add_element("importedData")
collection = import.add_element("List")
collection.attributes["name"] = filepath

bookcount = 0

bibxml.elements().each("/bibtex:file/bibtex:entry/bibtex:book") do |book_element|

	book = collection.add_element("Book")

	book_element.each_element() do |element|
		name = element.fully_expanded_name
		value = element.text

		field = book.add_element("field")

		newname = mapping[name]
			
		if (newname == nil)
			newname = name
		end
		
		if (name == "bibtex:bibdate" || name == "bibtex:year")

		elsif (name == "bibtex:author")
			value = value.tr_s("\n", "").tr_s("\t", "")

			if (value == "")
				value = ""

				element.elements().each("bibtex:person") do |author|
					value = value + author.text + "; "
				end
			end

		else

		end
				
		field.attributes["name"] = newname
		field.add_text(value)
	end

end

outputxml.write($stdout,0,false,false)