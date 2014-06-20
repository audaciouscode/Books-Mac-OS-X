package net.aetherial.books.me;

import javax.microedition.lcdui.Form;
import javax.microedition.lcdui.Image;

public class LoadingScreen extends Form
{
	private static LoadingScreen instance;
	
	public LoadingScreen ()
	{
		super ("Loading Books Micro Edition");

		try
		{
			Image icon = Image.createImage ("icon-large.png");
			this.append (icon);
		}
		catch (Exception e)
		{
			this.append ("Books Micro Edition\n\n");
		}

		this.append ("Loading data...");
	}
	
	public LoadingScreen (String title) 
	{
		super (title);
	}
	
	public static LoadingScreen getScreen (Midlet m) 
	{
		if (instance == null)
		{
			instance = new LoadingScreen ();
		}
		
		return instance;
	}
}
