package net.aetherial.books.me;

import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.Form;
import javax.microedition.lcdui.StringItem;
import javax.microedition.lcdui.TextField;

public class SearchScreen extends Form implements CommandListener
{
	private static SearchScreen instance;
	
	private TextField query;
	private Midlet midlet;
	
	private Command next;
	private Command back;
	
	public static SearchScreen getScreen (String query, Midlet m)
	{
		if (instance == null)
		{
			instance = new SearchScreen ();
			instance.setMidlet (m);
		}
		
		instance.setQuery (query);
		
		return instance;
	}
	
	public void setMidlet (Midlet m)
	{
		midlet = m;
	}
	
	public SearchScreen () 
	{
		super("Find a Book");
		
		this.append (new StringItem ("Enter a portion of the title of a book to find.", null));
		query = new TextField ("Title:", "", 10, TextField.ANY);
		
		this.append (query);
		
		back = new Command ("Back", Command.BACK, 1);
		this.addCommand (back);
		
		next = new Command ("Go", Command.OK, 1);
		this.addCommand (next);
		
		this.setCommandListener (this);
	}
	
	public void setQuery (String q)
	{
		query.setString (q);
	}
	
	public void commandAction (Command cmd, Displayable sender) 
	{
		if (cmd == next)
		{
			SearchResultsScreen.reset ();
			midlet.setScreen (SearchResultsScreen.getScreen (query.getString(), this, midlet));
		}
		else if (cmd == back)
		{
			midlet.setScreen (MainMenuScreen.getScreen (midlet));
		}
	}
}
