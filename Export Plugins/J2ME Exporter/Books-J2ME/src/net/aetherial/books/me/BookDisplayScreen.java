package net.aetherial.books.me;

import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.Form;
import javax.microedition.lcdui.Screen;

public class BookDisplayScreen extends Form implements CommandListener 
{
	private Midlet midlet;
	
	private Command ok;
	
	private Screen backScreen;
	
	public static BookDisplayScreen getScreen (int index, Screen backScreen, Midlet m) 
	{
		BookDisplayScreen screen = new BookDisplayScreen (index);
		screen.setMidlet (m);
		
		screen.setBackScreen (backScreen);
		
		return screen;
	}
	
	public BookDisplayScreen (int index)
	{
		super ("New Book");
		
		Book book = BookCollection.getCollection ().getBookAtIndex (index);
		
		this.setTitle (book.getValue ("title"));
		
		String[] keys = book.getKeys ();
		String desc = book.getValue ("Title") + "\n\n";
		
		for (int i = 0; i < keys.length; i++)
		{
			if (!(keys[i].equals ("Title")))
				desc = desc + keys[i] + ": " + book.getValue (keys[i]) + "\n";
		}
		
		this.append (desc);
		
		ok = new Command ("OK", Command.BACK, 1);
		this.addCommand (ok);
		
		this.setCommandListener (this);
	}
	
	public void setMidlet (Midlet m)
	{
		midlet = m;
	}
	
	public BookDisplayScreen (String arg0) 
	{
		super(arg0);

		ok = new Command ("Back", Command.BACK, 1);
		this.addCommand (ok);
	}
	
	public void setBackScreen (Screen b)
	{
		backScreen = b;
	}
	
	
	public void commandAction(Command cmd, Displayable sender) 
	{
		if (cmd == ok)
		{
			if (backScreen != null)
				midlet.setScreen (backScreen);
		}
	}
}
