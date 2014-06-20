package net.aetherial.books.me;

import java.util.*;

public class Book 
{
	private Hashtable properties;
	
	public Book ()
	{
		properties = new Hashtable ();
	}
	public String[] getKeys ()
	{
		String[] keys = new String [properties.size ()];
		
		int i = 0;
		for (Enumeration e = properties.keys (); e.hasMoreElements() ; i++) 
		{
			keys[i] = (String) e.nextElement();
		}
		
		return Utils.sortStrings (keys);
	}
	
	public void setValue (String key, String value)
	{
		key = key.toLowerCase ();
		
		if (key.equals ("title"))
			key = "Title";
		else if (key.equals ("authors"))
			key = "Authors";
		else if (key.equals ("isbn"))
			key = "ISBN";
		else if (key.equals ("publishdate"))
		{
			key = "Date Published";
		}
		else if (key.equals ("publisher"))
			key = "Publisher";

		properties.put (key, value);
	}
	
	public String getValue (String key)
	{
		return (String) properties.get (key);
	}
}
