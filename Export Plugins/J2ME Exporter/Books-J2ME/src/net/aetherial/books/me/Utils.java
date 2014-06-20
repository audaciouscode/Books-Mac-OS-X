package net.aetherial.books.me;

import java.util.Vector;

public class Utils 
{
	public static String[] sortStrings (String[] list)
	{
		for (int j = 0;  j < list.length - 1;  j++)
		{
			int min = j;
			
			for (int k = j + 1; k < list.length; k++)
			{
				if (list[k].compareTo (list[min]) < 0)
					min = k;
			}
			
			String minString = list[min];
			
			list[min] = list[j];
			list[j] = minString;
		}
		
		return list;
	}

	public static Vector sortBooks (Vector list)
	{
		Vector newVector = new Vector ();
		
		while (list.size () > 0)
		{
			int min = 0;
			
			for (int k = 0; k < list.size (); k++)
			{
				String titleK = ((Book) list.elementAt (k)).getValue ("Title");
				String titleMin = ((Book) list.elementAt (min)).getValue ("Title");

				if (titleK.compareTo (titleMin) < 0)
					min = k;
			}
			
			newVector.addElement (list.elementAt (min));
			list.removeElementAt (min);
		}
		
		return newVector;
	}
}
