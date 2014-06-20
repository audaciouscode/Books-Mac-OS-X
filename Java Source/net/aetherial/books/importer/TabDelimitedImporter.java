package net.aetherial.books.importer;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.StringTokenizer;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Text;

public class TabDelimitedImporter
{
	public static void main (String[] args) throws Exception 
	{
		BufferedReader in = new BufferedReader (new FileReader (args[0]));

		HashMap fieldMap = new HashMap ();
		
		fieldMap.put ("Title", "title");
		fieldMap.put ("Series", "series");
		fieldMap.put ("Genre", "genre");
		fieldMap.put ("Authors", "authors");
		fieldMap.put ("Editors", "editors");
		fieldMap.put ("Illustrators", "illustrators");
		fieldMap.put ("Translators", "translators");
		fieldMap.put ("Publisher", "publisher");
		fieldMap.put ("Publish Date", "publishDate");
		fieldMap.put ("ISBN", "isbn");
		fieldMap.put ("Keywords", "keywords");
		fieldMap.put ("Format", "format");
		fieldMap.put ("Edition", "isbn");
		fieldMap.put ("Publish Place", "publishPlace");
		fieldMap.put ("Length", "length");

		ArrayList fields = new ArrayList ();
		
		String line = in.readLine ();
		
		if (line != null)
		{
			StringTokenizer st = new StringTokenizer (line, "\t");
			
			for (int i = 0; st.hasMoreTokens (); i++)
			{
				String field = st.nextToken ();
				
				fields.add (field);
			}

			Document d = DocumentBuilderFactory.newInstance ().newDocumentBuilder ().newDocument ();
			
			Element importData = d.createElement ("importedData");
			d.appendChild (importData);
			
			Element list = d.createElement ("List");
			list.setAttribute ("name", args[0]);
			
			importData.appendChild (list);
			
			while ((line = in.readLine ()) != null)
			{
				st = new StringTokenizer (line.replaceAll ("\t", " \t"), "\t");

				Element book = d.createElement ("Book");
				
				for (int i = 0; st.hasMoreTokens (); i++)
				{
					Element field = d.createElement ("field");
					
					field.setAttribute ("name", (String) fieldMap.get (fields.get (i)));
					
					String value = st.nextToken ();
					
					Text t = d.createTextNode (value);
					
					field.appendChild (t);
					
					book.appendChild (field);
				}
				
				list.appendChild (book);
			}

			TransformerFactory tf = TransformerFactory.newInstance ();
			
			Transformer transformer = tf.newTransformer ();
			transformer.setOutputProperty (OutputKeys.INDENT, "yes");
			transformer.setOutputProperty (OutputKeys.OMIT_XML_DECLARATION, "yes");
			
			StreamResult result = new StreamResult ();
			
			result.setWriter (new PrintWriter (System.out));
			
			DOMSource source = new DOMSource ();
			source.setNode (d);
			
			transformer.transform (source, result);
		}
	}
}
