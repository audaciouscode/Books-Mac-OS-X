#!/usr/bin/ruby

require "rexml/document"

mapping = { 	'pages' => 'length', 
				'year' => 'publishDate', 
				'editionNumber' => 'edition', 
				'placePublished' => 'publishPlace', 
				'owned' => 'owner', 
				'price' => 'presentValue', 
				'obtainedFrom' => 'source', 
				'dateAdded' => 'dateAcquired', 
				'signed' => 'inscription', 
				'read' => 'progress', 
				'description' => 'summary' 
		  }

filepath = ARGV[0]

listxml = REXML::Document.new(File.new(filepath))

outputxml = REXML::Document.new

import = outputxml.add_element("importedData")
collection = import.add_element("List")
collection.attributes["name"] = filepath

bookcount = 0

listxml.elements().each("/books/book") do |book_element|

	book = collection.add_element("Book")

	copy = nil;
	feedback = nil;
	
	book_element.elements().each() do |element|
		name = element.name

		if (name == "authors")
			authors = ""
			translators = ""
			editors = ""
			illustrators = ""
			
			element.elements().each("author") do |author|
				if (author.attributes["type"] == "translator")
					if (translators != "")
						translators += "; "
					end
					translators += author.text
				elsif (author.attributes["type"] == "illustrator")
					if (illustrators != "")
						illustrators += "; "
					end
					illustrators += author.text
				elsif (author.attributes["type"] == "editor")
					if (editors != "")
						editors += "; "
					end
					editors += author.text
				else									
					if (authors != "")
						authors += "; "
					end
					
					authors += author.text
				end
			end

			if (authors != "")
				field = book.add_element("field")
				field.attributes["name"] = "authors"
				field.text = authors
			end

			if (translators != "")
				field = book.add_element("field")
				field.attributes["name"] = "translators"
				field.text = translators
			end

			if (editors != "")
				field = book.add_element("field")
				field.attributes["name"] = "editors"
				field.text = editors
			end

			if (illustrators != "")
				field = book.add_element("field")
				field.attributes["name"] = "illustrators"
				field.text = illustrators
			end
		elsif (name == "locSubjects")
			subjects = ""
			
			element.elements().each("locSubject") do |subject|
				if (subjects != "")
					subjects += "; "
				end
					
				subjects += subject.text
			end

			field = book.add_element("field")
			field.attributes["name"] = "keywords"
			field.text = subjects
		elsif (name == "condition" || name == "location" || name == "owned" ||
				name == "price" || name == "obtainedFrom" || name == "dateAdded" ||
				name == "signed")
				
			if (copy == nil)
				copy = book.add_element("copy")
			end
				
			newname = mapping[name]
			
			if (newname == nil)
				newname = name
			end
			
			if (newname != "inscription")
				copy.attributes[newname] = element.text
			else
				copy.text = element.text
			end
		elsif (name == "read" || name == "rating")
			if (feedback == nil)
				feedback = book.add_element("feedback")
				feedback.attributes["submitter"] = "Myself"
			end
				
			newname = mapping[name]
			
			if (newname == nil)
				newname = name
			end
			
			if (newname != "read")
				feedback.attributes[newname] = element.text
			else
				if (element.text != "false")
					feedback.attributes[newname] = "Finished"
				end
			end
		else
			field = book.add_element("field")

			newname = mapping[name]
			
			if (newname == nil)
				newname = name
			end
			
			field.attributes["name"] = newname
			field.text = element.text
		end
	end
end

outputxml.write($stdout,0,false,false)