package net.aetherial.books.me;

import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.Form;

public class AboutScreen extends Form implements CommandListener
{
	private static AboutScreen instance;
	private Midlet midlet;
	private Command back;
	
	public AboutScreen ()
	{
		super ("About Books Micro Edition");
		
		String aboutString = 	"Books Micro Edition is a J2ME companion to Books.\n\n" +
		"Books is an application for managing personal libraries and can be downloaded at\n\n" +
		"http://books.aetherial.net/\n\n" +
		"For questions, comments, and feedback, e-mail the developer at\n\n" +
		"books@aetherial.net\n\n" +
		"This application is licensed under the GNU GPL.\n\n" +
		"Copyright 2004-2006, Chris Karr";
		
		this.append (aboutString);
		
		back = new Command ("OK", Command.OK, 1);
		this.addCommand (back);
		
		this.setCommandListener (this);
	}
	
	public AboutScreen (String title) 
	{
		super (title);
	}
	
	public static AboutScreen getScreen (Midlet m) 
	{
		if (instance == null)
		{
			instance = new AboutScreen ();
			instance.setMidlet (m);
		}
		
		return instance;
	}
	
	public void setMidlet (Midlet m)
	{
		midlet = m;
	}
	
	public void commandAction(Command cmd, Displayable sender) 
	{
		if (cmd == back)
		{
			midlet.setScreen (MainMenuScreen.getScreen (midlet));
		}
	}
}
