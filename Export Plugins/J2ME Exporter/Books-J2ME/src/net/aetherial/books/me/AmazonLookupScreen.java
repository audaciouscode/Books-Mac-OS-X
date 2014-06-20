package net.aetherial.books.me;

import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.Form;
import javax.microedition.lcdui.StringItem;
import javax.microedition.lcdui.TextField;

public class AmazonLookupScreen extends Form implements CommandListener 
{
	private static AmazonLookupScreen instance;
	
	private Midlet midlet;
	private TextField isbn;
	
	private Command next;
	private Command back;
	
	public static AmazonLookupScreen getScreen (String isbn, Midlet m)
	{
		if (instance == null)
		{
			instance = new AmazonLookupScreen ();
			instance.setMidlet (m);
		}
		
		instance.setIsbn (isbn);
		
		return instance;
	}
	
	
	public AmazonLookupScreen ()
	{
		super ("Find Book Online");

		this.append (new StringItem ("Enter the ISBN number of a book to lookup online.", null));
		isbn = new TextField ("ISBN:", "", 10, TextField.ANY);
		this.append (isbn);
		this.append (new StringItem ("Powered by Amazon", null));
		
		back = new Command ("Back", Command.BACK, 1);
		this.addCommand (back);
		
		next = new Command ("Go", Command.OK, 1);
		this.addCommand (next);
		
		this.setCommandListener (this);

	}
	
	public void setIsbn (String isbnNo)
	{
		isbn.setString (isbnNo);
	}
	
	public void commandAction(Command cmd, Displayable sender) 
	{
		if (cmd == next)
		{
			midlet.setScreen (AmazonResultsScreen.getScreen (isbn.getString (), midlet));
		}
		else if (cmd == back)
		{
			midlet.setScreen (MainMenuScreen.getScreen (midlet));
		}
	}
	
	public void setMidlet (Midlet m)
	{
		midlet = m;
	}
}
