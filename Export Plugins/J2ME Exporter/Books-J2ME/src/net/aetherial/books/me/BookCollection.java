
package net.aetherial.books.me;

import java.util.*;

public class BookCollection 
{
	private static BookCollection collection;
	
	private Vector books;
	
	public BookCollection ()
	{
		books = new Vector ();
	}
	
	public Book getBookAtIndex (int index)
	{
		return (Book) books.elementAt (index);
	}
	
	public int size ()
	{
		return books.size ();
	}
	
	public static BookCollection getCollection ()
	{
		if (collection == null)
		{
			collection = new BookCollection ();
		
			Book b;

		
			b = new Book ();
			
			b.setValue ("title", "The Maxx, Vol. 2");
		
			b.setValue ("authors", "Sam Kieth; William Messner-Loebs");
		
			b.setValue ("isbn", "1401202802");
		
			b.setValue ("publishDate", "2004");
		
			b.setValue ("publisher", "Wildstorm");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Maxx, Vol. 3");
		
			b.setValue ("authors", "Sam Kieth; William Messner-Loebs");
		
			b.setValue ("isbn", "1401202985");
		
			b.setValue ("publishDate", "2004");
		
			b.setValue ("publisher", "Wildstorm");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Maxx, Vol. 4");
		
			b.setValue ("authors", "Sam Kieth");
		
			b.setValue ("isbn", "1401206131");
		
			b.setValue ("publishDate", "2005");
		
			b.setValue ("publisher", "Wildstorm");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Phantom Encounters");
		
			b.setValue ("authors", "Time-Life Books");
		
			b.setValue ("isbn", "0809463288");
		
			b.setValue ("publishDate", "1995");
		
			b.setValue ("publisher", "Time Life Education");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Rand McNally World Atlas");
		
			b.setValue ("authors", "");
		
			b.setValue ("isbn", "0528965808");
		
			b.setValue ("publishDate", "2004");
		
			b.setValue ("publisher", "Rand McNally & Company");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Cosmic Connections");
		
			b.setValue ("authors", "Time-Life Books");
		
			b.setValue ("isbn", "0809463407");
		
			b.setValue ("publishDate", "1988");
		
			b.setValue ("publisher", "Time Life Education");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Mind Over Matter");
		
			b.setValue ("authors", "Time-Life Books");
		
			b.setValue ("isbn", "0809463369");
		
			b.setValue ("publishDate", "1988");
		
			b.setValue ("publisher", "Time Life Education");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Transformations");
		
			b.setValue ("authors", "Time-Life Books");
		
			b.setValue ("isbn", "0809463644");
		
			b.setValue ("publishDate", "1995");
		
			b.setValue ("publisher", "Time Life Education");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The UFO Phenomenon");
		
			b.setValue ("authors", "Time-Life Books");
		
			b.setValue ("isbn", "0809463245");
		
			b.setValue ("publishDate", "1988");
		
			b.setValue ("publisher", "Time-Life Books");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Maxx, Vol. 5");
		
			b.setValue ("authors", "Sam Kieth");
		
			b.setValue ("isbn", "1401206212");
		
			b.setValue ("publishDate", "2005");
		
			b.setValue ("publisher", "Wildstorm");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Psychic Voyagers");
		
			b.setValue ("authors", "Time-Life Books");
		
			b.setValue ("isbn", "0809463164");
		
			b.setValue ("publishDate", "1988");
		
			b.setValue ("publisher", "Time Life Education");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Mystic Places");
		
			b.setValue ("authors", "Time-Life Books");
		
			b.setValue ("isbn", "0809463121");
		
			b.setValue ("publishDate", "1987");
		
			b.setValue ("publisher", "Time Life Education");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "America (The Book): A Citizen's Guide to Democracy Inaction");
		
			b.setValue ("authors", "The Daily Show Writers; Jon Stewart");
		
			b.setValue ("isbn", "0446532681");
		
			b.setValue ("publishDate", "2004");
		
			b.setValue ("publisher", "Warner Books");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Penny Arcade, Vol. 1: Attack of the Bacon Robots");
		
			b.setValue ("authors", "Jerry Holkins");
		
			b.setValue ("isbn", "1593074441");
		
			b.setValue ("publishDate", "2006");
		
			b.setValue ("publisher", "Dark Horse");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Master of Dragons");
		
			b.setValue ("authors", "Margaret Weis");
		
			b.setValue ("isbn", "0765304708");
		
			b.setValue ("publishDate", "2005");
		
			b.setValue ("publisher", "Tor Books");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Marvel 1602");
		
			b.setValue ("authors", "Neil Gaiman");
		
			b.setValue ("isbn", "0785110739");
		
			b.setValue ("publishDate", "2005");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "One Million A.D.");
		
			b.setValue ("authors", "");
		
			b.setValue ("isbn", "0739462733");
		
			b.setValue ("publishDate", "2005");
		
			b.setValue ("publisher", "Science Fiction Book Club");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Batman: Arkham Asylum");
		
			b.setValue ("authors", "Grant Morrison");
		
			b.setValue ("isbn", "1401204252");
		
			b.setValue ("publishDate", "2005");
		
			b.setValue ("publisher", "DC Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Stoker's Dracula");
		
			b.setValue ("authors", "Roy Thomas");
		
			b.setValue ("isbn", "0785114777");
		
			b.setValue ("publishDate", "2005");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #293");
		
			b.setValue ("authors", "Scott Lobdell");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "X-Men #92");
		
			b.setValue ("authors", "Alan Davis; Terry Kavanagh");
		
			b.setValue ("publishDate", "1999");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "X-Force #18");
		
			b.setValue ("authors", "");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #250");
		
			b.setValue ("authors", "Chris Claremont");
		
			b.setValue ("publishDate", "1989");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "X-Men #41");
		
			b.setValue ("authors", "Fabian Nicieza");
		
			b.setValue ("publishDate", "1995");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Mistress of Dragons");
		
			b.setValue ("authors", "Margaret Weis");
		
			b.setValue ("isbn", "0765304686");
		
			b.setValue ("publishDate", "2004");
		
			b.setValue ("publisher", "James Bennett Pty Ltd");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Star Wars: Outbound Flight");
		
			b.setValue ("authors", "Timothy Zahn");
		
			b.setValue ("isbn", "0345456831");
		
			b.setValue ("publishDate", "2006");
		
			b.setValue ("publisher", "Del Rey Books");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #320");
		
			b.setValue ("authors", "Scott Lobdell; Mark Waid");
		
			b.setValue ("publishDate", "1995");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #286");
		
			b.setValue ("authors", "Scott Lobdell; Jim Lee; Wilce Portacio;");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #292");
		
			b.setValue ("authors", "Scott Lobdell");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "X-Men #1 (Colossus Cover)");
		
			b.setValue ("authors", "Chris Claremont");
		
			b.setValue ("publishDate", "1991");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Dragon's Son");
		
			b.setValue ("authors", "Margaret Weis");
		
			b.setValue ("isbn", "0765304694");
		
			b.setValue ("publishDate", "2004");
		
			b.setValue ("publisher", "Saint Martin's Press");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #249");
		
			b.setValue ("authors", "Chris Claremont");
		
			b.setValue ("publishDate", "1989");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #287");
		
			b.setValue ("authors", "Jim Lee; Scott Lobdell");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #371");
		
			b.setValue ("authors", "Alan Davis");
		
			b.setValue ("publishDate", "1999");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "X-Men #1 (Storm Cover)");
		
			b.setValue ("authors", "Chris Claremont");
		
			b.setValue ("publishDate", "1991");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #291");
		
			b.setValue ("authors", "Scott Lobdell");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "X-Men #18");
		
			b.setValue ("authors", "Fabian Nicieza");
		
			b.setValue ("publishDate", "1993");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #289");
		
			b.setValue ("authors", "Scott Lobdell");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #290");
		
			b.setValue ("authors", "Scott Lobdell");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #282");
		
			b.setValue ("authors", "Wilce Portacio; John Byrne");
		
			b.setValue ("publishDate", "1991");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #284");
		
			b.setValue ("authors", "Wilce Portacio");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #285");
		
			b.setValue ("authors", "Wilce Portacio; Jim Lee; John Byrne");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #279");
		
			b.setValue ("authors", "Chris Claremont; Fabian Nicieza");
		
			b.setValue ("publishDate", "1991");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #360");
		
			b.setValue ("authors", "Steve Seagle");
		
			b.setValue ("publishDate", "1998");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #312");
		
			b.setValue ("authors", "Scott Lobdell");
		
			b.setValue ("publishDate", "1994");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #288");
		
			b.setValue ("authors", "Jim Lee; Wilce Portacio; Byrne; Lobdell");
		
			b.setValue ("publishDate", "1992");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "Generation X #7");
		
			b.setValue ("authors", "Scott Lobdell");
		
			b.setValue ("publishDate", "1995");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
	
			b = new Book ();
			
			b.setValue ("title", "The Uncanny X-Men #400");
		
			b.setValue ("authors", "Joe Casey");
		
			b.setValue ("publishDate", "2001");
		
			b.setValue ("publisher", "Marvel Comics");
		
			collection.addBook (b);
				
			collection.sort ();
		}
		
		return collection;
	}
	
	public void sort ()
	{
		books = Utils.sortBooks (books);
	}
	
	public void addBook (Book b)
	{
		books.addElement (b);
	}
	
	public Vector findBooks(String query) 
	{
		System.out.println ("Looking for " + query);
		
		Vector results = new Vector ();
		
		for (int i = 0; i < books.size(); i++)
		{
			Book b = (Book) books.elementAt (i);
			
			String title = b.getValue ("Title");
			
			if (title != null)
			{
				if (query == null || query.equals (""))
					results.addElement (b);
				else if (title.toLowerCase().indexOf (query.toLowerCase()) != -1)
					results.addElement (b);
			}
		}
		
		return results;
	}
	
	public int indexOf (Book b)
	{
		return books.indexOf (b);
	}
}
	