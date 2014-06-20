package net.aetherial.books.me;

import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Screen;
import javax.microedition.midlet.MIDlet;

public class Midlet extends MIDlet 
{
	private static Display display;
	
	public Midlet() 
	{
		display = Display.getDisplay (this);
	}
	
	public void startApp() 
	{
		setScreen (LoadingScreen.getScreen (this));
		
		BookCollection.getCollection ();
		
		setScreen (MainMenuScreen.getScreen (this));
	}
	
	public void pauseApp() 
	{
		
	}
	
	public void destroyApp (boolean unconditional) 
	{
		this.notifyDestroyed ();
	}
	
	public void setScreen (Screen s)
	{
		display.setCurrent (s);
	}
}
