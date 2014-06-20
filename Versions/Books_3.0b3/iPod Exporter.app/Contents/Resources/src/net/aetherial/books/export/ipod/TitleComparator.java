package net.aetherial.books.export.ipod;

import java.util.Comparator;

import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

public class TitleComparator implements Comparator 
{
	public int compare (Object a, Object b) 
	{
		Element first = (Element) a;
		Element second = (Element) b;
		
		String firstTitle = this.getTitle (first);
		String secondTitle = this.getTitle (second);

		return firstTitle.compareTo (secondTitle);
	}
	
	private String getTitle (Element e)
	{
		NodeList fields = e.getElementsByTagName ("field");
		
		for (int i = 0; i < fields.getLength (); i++)
		{
			Element field = (Element) fields.item (i);
			
			if (field.getAttribute ("name").equals ("title"))
				return field.getTextContent ();
		}
		
		return "";
	}
}
