package net.aetherial.books.me;

import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.List;

public class MainMenuScreen extends List implements CommandListener
{
	private static MainMenuScreen instance;
	
	private Midlet midlet;
	private Command next;
	private Command quit;
	
	public static MainMenuScreen getScreen (Midlet m)
	{
		if (instance == null)
		{
			instance = new MainMenuScreen ();
			
			instance.setMidlet (m);
		}
		
		return instance;
	}
	
	public MainMenuScreen ()
	{
		super ("Books Micro Edition", List.IMPLICIT);
		
		String[] mainMenuItems = {"Browse Collection", "Find Book Locally", "Find Book Online", "About Books ME"};

		for (int i = 0; i < mainMenuItems.length; i++)
		{
			this.append (mainMenuItems[i], null);
		}
		
		next = List.SELECT_COMMAND;
		this.addCommand (next);
		
		quit = new Command ("Quit", Command.BACK, 1);
		this.addCommand (quit);
		
		this.setCommandListener (this);
	}
	
	public MainMenuScreen (String arg0, int arg1) 
	{
		super (arg0, arg1);
	}
	
	public void setMidlet (Midlet m)
	{
		midlet = m;
	}
	
	public void commandAction (Command cmd, Displayable sender) 
	{
		if (cmd == next)
		{
			String selection = this.getString (this.getSelectedIndex ());

			if (selection.equals ("Browse Collection"))
			{
				SearchResultsScreen.reset ();
				midlet.setScreen (SearchResultsScreen.getScreen (null, this, midlet));
			}
			else if (selection.equals ("Find Book Locally"))
			{
				midlet.setScreen (SearchScreen.getScreen ("", midlet));
			}
			else if (selection.equals ("Find Book Online"))
			{
				midlet.setScreen (AmazonLookupScreen.getScreen ("", midlet));
			}
			else if (selection.equals ("About Books ME"))
			{
				midlet.setScreen (AboutScreen.getScreen (midlet));
			}
		}
		if (cmd == quit)
		{
			midlet.destroyApp (true);
		}
	}
}
