#!/usr/bin/ruby

require "rexml/document"

filepath = ARGV[0]

listxml = REXML::Document.new(File.new(filepath))

bookcount = 0

listxml.elements().each("/exportData/Book") do |book_element|
	title = ""
	authors = ""
	publisher = ""
	genre = ""
	publish_date = ""
	format = ""
	edition = ""
	series = ""

	book_element.elements().each("field") do |field_element|
		att_name = field_element.attributes["name"]
		
		value = field_element.text
		
		if (value == nil)
			value = ""
		end
		
		value = value.tr("\"", "'")
		
		if (att_name == "title")
			title = value
		elsif (att_name == "authors")
			authors = value
		elsif (att_name == "publisher")
			publisher = value
		elsif (att_name == "genre")
			genre = value
		elsif (att_name == "publishDate")
			publish_date = value
		elsif (att_name == "format")
			format = value
		elsif (att_name == "edition")
			edition = value
		elsif (att_name == "series")
			series = value
		end
	end

	print("\"" + title + "\",\"" + authors + "\",\"", publisher + "\",\"" + genre + "\",\"" + publish_date + "\",\"" + format + "\",\"" + edition + "\",\"" + series + "\"\n")
	
end