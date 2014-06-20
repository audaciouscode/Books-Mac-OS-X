package net.aetherial.books.me;

import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.List;

public class BrowseBooksScreen extends List implements CommandListener
{
	private static BookCollection books;
	
	public static int PAGE_SIZE = 5;
	
	private Midlet midlet;
	private int currentPage;
	
	private Command nextPage;
	private Command previousPage;
	
	private Command select;
	private Command home;
	
	public static BrowseBooksScreen getScreen (int pageNo, Midlet midlet) 
	{
		BrowseBooksScreen browseScreen = new BrowseBooksScreen (pageNo);
		browseScreen.setMidlet (midlet);
		
		return browseScreen;
	}
	
	private void setMidlet(Midlet m) 
	{
		midlet = m;
	}
	
	public BrowseBooksScreen (int page)
	{
		super ("Collection: Page " + (page + 1), List.IMPLICIT);
		
		currentPage = page;
		
		if (books == null)
		{
			books = BookCollection.getCollection ();
		}
		
		for (int i = (currentPage * PAGE_SIZE); i < books.size () && i < ((currentPage + 1) * PAGE_SIZE); i++)
		{
			Book b = books.getBookAtIndex (i);
			
			if (b.getValue ("Title") != null)
				this.append (b.getValue ("Title"), null);
		}
		
		if (((currentPage + 1) * PAGE_SIZE) < books.size ())
		{
			nextPage = new Command ("Next", Command.OK, 1);
			this.addCommand (nextPage);
		}
		else
		{
			home = new Command ("Home", Command.OK, 2);
			this.addCommand (home);
		}
		
		if (currentPage > 0)
		{
			previousPage = new Command ("Previous", Command.BACK, 1);
			this.addCommand (previousPage);
		}
		else
		{
			home = new Command ("Home", Command.BACK, 2);
			this.addCommand (home);
		}
		
		select = List.SELECT_COMMAND;
		this.addCommand (select);
		
		this.setCommandListener (this);
	}
	
	public BrowseBooksScreen (String arg0, int arg1) 
	{
		super (arg0, arg1);
	}
	
	public void commandAction(Command cmd, Displayable sender) 
	{
		if (cmd == home)
			midlet.setScreen (MainMenuScreen.getScreen (midlet));
		else if (cmd == select)
			midlet.setScreen (BookDisplayScreen.getScreen ((currentPage * PAGE_SIZE) + this.getSelectedIndex(), null, midlet));
		else if (cmd == nextPage)
			midlet.setScreen (BrowseBooksScreen.getScreen (currentPage + 1, midlet));
		else if (cmd ==previousPage)
		{
			if (currentPage > 0)
				midlet.setScreen (BrowseBooksScreen.getScreen (currentPage - 1, midlet));
		}
	}
}
