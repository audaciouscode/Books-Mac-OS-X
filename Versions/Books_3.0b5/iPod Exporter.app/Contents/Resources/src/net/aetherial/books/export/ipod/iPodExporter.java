package net.aetherial.books.export.ipod;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

public class iPodExporter 
{
	@SuppressWarnings("unchecked")
	public static void main (String[] args) throws ParserConfigurationException, SAXException, IOException 
	{
		String[] mdFields = {"title", "publisher", "publisherDate", "illustrators", "authors", "summary", 
							"genre", "listName"};

		DocumentBuilder db = DocumentBuilderFactory.newInstance ().newDocumentBuilder ();
		Document doc = db.parse (args[0]);

		String root = args[1];
		
		NodeList nl = doc.getElementsByTagName ("Book");

		ArrayList books = new ArrayList ();
		
		for (int i = 0; i < nl.getLength (); i++)
			books.add (nl.item (i));

		Collections.sort (books, new TitleComparator ());

		for (int i = 0; i < books.size (); i++)
		{
			Element book = (Element) books.get (i);
			
			NodeList fields = book.getElementsByTagName ("field");
			HashMap bookDef = new HashMap ();
			
			for (int j = 0; j < fields.getLength (); j++)
			{
				Element field = (Element) fields.item (j);
				
				String name = field.getAttribute ("name");
				
				if (name.equals ("coverImage"))
				{
					
				}
				else
				{
					String value = field.getTextContent ();

					bookDef.put (name, value);
				}
			}

			String genre = (String) bookDef.get ("genre");
			
			if (genre == null)
				genre = "Undefined Genre";
			
			File bookFile = new File (root + "/" + bookDef.get ("listName") + "/" + genre + "/" + ((String) bookDef.get ("title")).replaceAll ("/", "-").replaceAll (":", "-"));
			bookFile.getParentFile ().mkdirs ();
			
			String bookString = "<title>" + bookDef.get ("title") + "</title>\n";
			
			for (int j = 0; j < mdFields.length; j++)
			{
				if (bookDef.get (mdFields[j]) != null)
					bookString = bookString + bookDef.get (mdFields[j]) + "\n";
			}

			FileWriter bookWriter = new FileWriter (bookFile);
			bookWriter.write (bookString);
			
			bookWriter.close ();
		}
	}
}
