package net.aetherial.books.webexporter;

import java.util.Comparator;
import java.util.HashMap;

@SuppressWarnings("unchecked")
public class TitleComparator implements Comparator 
{
	private static TitleComparator instance;
	
	public static TitleComparator getInstance ()
	{
		if (instance == null)
			instance = new TitleComparator ();
		
		return instance;
	}

	public int compare (Object o1, Object o2) 
	{
		try
		{
			HashMap h1 = (HashMap) o1;
			HashMap h2 = (HashMap) o2;

			String t1 = (String) h1.get ("title");
			String t2 = (String) h2.get ("title");

			if (t1 != null && t2 != null)
			{
				if (t1.toLowerCase ().startsWith ("the "))
					t1 = t1.substring (4);

				if (t2.toLowerCase ().startsWith ("the "))
					t2 = t2.substring (4);
			

				if (t1.toLowerCase ().startsWith ("an "))
					t1 = t1.substring (3);

				if (t2.toLowerCase ().startsWith ("an "))
					t2 = t2.substring (3);


				if (t1.toLowerCase ().startsWith ("a "))
					t1 = t1.substring (2);

				if (t2.toLowerCase ().startsWith ("a "))
					t2 = t2.substring (2);

				return t1.compareTo (t2);
			}
				
			return 0;
		}
		catch (Exception e)
		{
			return 0;
		}
	}
}
