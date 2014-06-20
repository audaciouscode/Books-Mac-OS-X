package net.aetherial.books.me;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import javax.microedition.io.Connector;
import javax.microedition.io.StreamConnection;
import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.Form;

public class AmazonResultsScreen extends Form implements CommandListener
{
	private String isbn;
	private Midlet midlet;
	private Command back;
	
	public static AmazonResultsScreen getScreen (String isbn, Midlet m)
	{
		AmazonResultsScreen results = new AmazonResultsScreen (isbn);
		results.setMidlet (m);
		
		return results;
	}
	
	public AmazonResultsScreen (String isbnNo) 
	{
		super (isbnNo);
		
		isbn = isbnNo;
		
		this.append (AmazonResultsScreen.doISBNLookup (isbn));
		
		back = new Command ("OK", Command.OK, 1);
		this.addCommand (back);
		
		this.setCommandListener (this);
	}
	
	public void commandAction(Command cmd, Displayable sender) 
	{
		if (cmd == back)
		{
			midlet.setScreen (AmazonLookupScreen.getScreen (isbn, midlet));
		}
		
	}
	
	public void setMidlet (Midlet m)
	{
		midlet = m;
	}
	
	public static String doISBNLookup (String isbn)
	{
		StreamConnection c = null;
		InputStream s = null;
		ByteArrayOutputStream baos = new ByteArrayOutputStream ();
		
		try 
		{
			String url = "http://xml-us.amznxslt.com/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=1W087CHNYGBWE51SK6R2"
				+ "&Operation=ItemLookup&IdType=ASIN&ItemId=" + isbn + "&ResponseGroup=Medium&"
				+ "Style=http%3A%2F%2Fhomepage.mac.com%2Fcjkarr%2FBooks%2Ftiny-text.xsl";
			
			c = (StreamConnection) Connector.open (url);
			
			s = c.openInputStream ();
			
			int read;
			byte[] buffer = new byte[4096];
			
			while ((read = s.read (buffer, 0, buffer.length)) != -1) 
			{
				baos.write (buffer, 0, read);
			}
			
			if (s != null) 
				s.close();
			if (c != null)
				c.close();
			
			String data = new String (baos.toByteArray ());
			
			if (data.equals (""))
				data = "Book not found. Please check that the ISBN was entered correctly. \n\n" + url;
			
			return data;
		}
		catch (IOException e)
		{
			return "There was an error downloading data for the book with ISBN '" + isbn + "'.";
		}
	}
}
