package net.aetherial.books.me;

import java.util.Vector;

import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.List;
import javax.microedition.lcdui.Screen;

public class SearchResultsScreen extends List implements CommandListener
{
	private static SearchResultsScreen instance;
	
	private Vector matches;
	private Midlet midlet;
	private String query;

	private Screen backScreen;

	private Command back;
	private Command next;
	
	public static void reset ()
	{
		instance = null;
	}

	public static Screen getScreen (String query, Screen previousScreen, Midlet midlet) 
	{
		if (instance == null)
		{
			instance = new SearchResultsScreen (List.IMPLICIT);
			instance.setMidlet (midlet);
		}
		
		instance.setQuery (query);
		instance.setBackScreen (previousScreen);
			
		return instance;
	}

	public void setQuery (String q)
	{
		query = q;

		if (q != null)
			this.setTitle (q);
		else
			this.setTitle ("All Books");

		for (int i = 0; i < this.size (); i++)
		{
			System.out.println ("deleting " + this.getString (0));
			this.delete (0);
		}
		
		BookCollection books = BookCollection.getCollection ();
		
		matches = books.findBooks (query);
		
		for (int i = 0; i < matches.size (); i++)
		{
			Book b = (Book) matches.elementAt (i);
			
			String title = b.getValue ("Title");
			
			if (title != null)
				this.append (title, null);
		}
	}
	
	public void setBackScreen (Screen back)
	{
		backScreen = back;
	}
	
	public SearchResultsScreen(int type) 
	{
		super ("All Books", type);
		
		next = List.SELECT_COMMAND;
		this.addCommand (next);
		
		back = new Command ("Back", Command.BACK, 1);
		this.addCommand (back);
		
		this.setCommandListener (this);
	}
	
	public void commandAction(Command cmd, Displayable sender) 
	{
		if (cmd == next)
		{
			BookCollection books = BookCollection.getCollection ();
			
			int index = books.indexOf ((Book) matches.elementAt (this.getSelectedIndex()));
			
			midlet.setScreen (BookDisplayScreen.getScreen (index, this, midlet));
		}
		else if (cmd == back)
		{
			if (backScreen != null)
				midlet.setScreen (backScreen);
		}
	}
	
	public void setMidlet (Midlet m)
	{
		midlet = m;
	}
}
