package net.aetherial.books.webexporter;

import java.awt.*;
import java.awt.image.renderable.*;
import java.io.*;
import java.text.*;
import java.util.*;

import javax.media.jai.*;
import javax.media.jai.operator.*;
import javax.xml.parsers.*;

import org.w3c.dom.*;
import org.xml.sax.*;

import com.sun.media.jai.codec.*;

public class WebExporter 
{
	private static File source;
	private static File destination;

	private static Document xmlDocument;
	private static ArrayList<String> keyList;
	private static HashMap<String, String> keyTitles;

	@SuppressWarnings("unchecked")
	private static HashMap<String, ArrayList> authors;
	@SuppressWarnings("unchecked")
	private static HashMap<String, ArrayList> genres;
	@SuppressWarnings("unchecked")
	private static HashMap<String, ArrayList> lists;

	@SuppressWarnings("unchecked")
	private static ArrayList<HashMap> allBooks;

	private static ArrayList<String> stringCodes;

	private static SimpleDateFormat sdfIn;
	private static SimpleDateFormat sdfOut;

	@SuppressWarnings("unchecked")
	public static void main (String[] args) throws ParserConfigurationException, SAXException, IOException, ParseException 
	{
		source = new File (args[0]);
		destination = new File (args[1]);

		authors = new HashMap<String, ArrayList> ();
		genres = new HashMap<String, ArrayList> ();
		lists = new HashMap<String, ArrayList> ();

		allBooks = new ArrayList<HashMap> ();

		DocumentBuilder db = DocumentBuilderFactory.newInstance ().newDocumentBuilder ();

		xmlDocument = db.parse (source);

		createDestination ();

		buildBooks ();
		buildLists ();
		buildIndices ();

		finishDestination ();
	}

	private static void finishDestination() 
	{

	}

	private static void buildLists () throws IOException 
	{
		buildGenreList ();
		buildAuthorsList ();
		buildListsList ();
		buildTitlesList ();
	}

	private static void buildIndices () throws IOException 
	{
		System.out.print ("Outputting indices... ");

		String htmlString = 	"<html>\n" +
		"	<head>\n" +
		"		<title>Redirecting...</title>\n" +
		"		<meta http-equiv=\"refresh\" content=\"0; URL=lists/titles/index.html\" />\n" +
		"		<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n" +
		"	</head>\n" + 
		"	<body>\n" +
		"		<p class=\"index-link\"><a href=\"flash.html\">Flash Version</a></p>\n" +
		"		<p class=\"index-link\"><a href=\"lists/titles/index.html\">HTML Version</a></p>\n" +
		"	</body>\n" +
		"</html>\n";

		OutputStreamWriter out = new OutputStreamWriter (new FileOutputStream (destination.getAbsolutePath () + "/index.html"), "UTF-8");

		out.write (htmlString);

		out.close ();

		System.out.println ("done.");
	}

	@SuppressWarnings("unchecked")
	private static void buildListsList () throws IOException 
	{
		System.out.print ("Outputting lists lists... ");
		String filePath = destination.getAbsolutePath () + "/lists/lists";

		File listIndex = new File (filePath);
		listIndex.mkdirs ();

		Object[] listList = lists.keySet().toArray ();

		Arrays.sort (listList);

		String htmlString = getHeader (2, "All Lists");

		htmlString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a></div>";

		htmlString += getListSidebar (2);

		htmlString += "<div class=\"metadata\">";

		for (int i = 0; i < listList.length; i++)
		{
			htmlString += "<p class=\"list-item\"><a href=\"" + getFilename ((String) listList[i]) + ".html\">" + listList[i] + "</a></p>";

			String listPath = destination.getAbsolutePath () + "/lists/lists/" + getFilename ((String) listList[i]) + ".html";

			File listPage = new File (listPath);
			listPage.createNewFile ();

			ArrayList listBooks = (ArrayList) lists.get (listList[i]);

			Collections.sort (listBooks, TitleComparator.getInstance ());

			String listString = getHeader (2, (String) listList[i]);

			listString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a></div>";

			listString += getListSidebar (2);

			listString += "<div class=\"metadata\">";

			for (int j = 0; j < listBooks.size (); j++)
			{
				HashMap fields = (HashMap) listBooks.get (j);

				listString += "<p class=\"list-item\"><a href=\"../../books/" + fields.get ("id") + "/index.html\">"+  fields.get ("title") + "</a></p>";
			}

			listString += "</div>";

			listString += getFooter ();

			OutputStreamWriter lout = new OutputStreamWriter (new FileOutputStream (listPage), "UTF-8");

			lout.write (listString);

			lout.close ();
		}

		htmlString += "</div>";
		htmlString += getFooter ();

		OutputStreamWriter out = new OutputStreamWriter (new FileOutputStream (listIndex.getAbsolutePath() + "/index.html"), "UTF-8");

		out.write (htmlString);

		out.close ();

		System.out.println ("done.");
	}

	@SuppressWarnings("unchecked")
	private static void buildTitlesList () throws IOException 
	{
		System.out.print ("Outputting title lists... ");
		String filePath = destination.getAbsolutePath () + "/lists/titles/";

		String rssPath = destination.getAbsolutePath () + "/index.rss";

		File listIndex = new File (filePath);
		listIndex.mkdirs ();

		String htmlString = getHeader (2, "All Books");

		htmlString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a></div>";

		htmlString += getListSidebar (2);

		htmlString += "<div class=\"metadata\">";

		Collections.sort (allBooks, TitleComparator.getInstance ());

		String rssString = 	"<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" " + 
		"xmlns:sy=\"http://purl.org/rss/1.0/modules/syndication/\"  xmlns:admin=\"http://webns.net/mvcb/\" " +
		"xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" xmlns:cc=\"http://web.resource.org/cc/\" " +
		"xmlns=\"http://purl.org/rss/1.0/\">\n" +
		"	<channel rdf:about=\"index.rdf\">\n" +
		"		<title>My Books</title>\n" +
		"		<link>.</link>\n" +
		"		<items>\n";

		String rssItemsString = "";

		for (int i = 0; i < allBooks.size (); i++)
		{
			HashMap <String, String> bookDef = allBooks.get (i);

			String bookPath = "books/" + bookDef.get ("id") + "/index.html";

			rssString += "			<rdf:li rdf:resource=\"" + bookPath + "\" />\n";

			htmlString += "<p class=\"list-item\"><a href=\"../../" + bookPath + "\">" + escape (bookDef.get ("title")) + "</a></p>";

			rssItemsString += 	"	<item rdf:about=\"" + bookPath + "\">\n" +
			"	<title>" + escape (bookDef.get ("title")) + "</title>\n" +
			"	<link>" + bookPath + "</link>\n";

			if (bookDef.get ("summary") != null)
				rssItemsString += "	<description><content:encoded><![CDATA[" + bookDef.get ("summary") + "]]></content:encoded></description>\n";

			rssItemsString += "</item>\n";
		}

		htmlString += "</div>";
		htmlString += getFooter ();

		OutputStreamWriter out = new OutputStreamWriter (new FileOutputStream (listIndex.getAbsolutePath() + "/index.html"), "UTF-8");

		out.write (htmlString);

		out.close ();

		rssString += 	"		</items>\n" +
		"	</channel>\n" +
		rssItemsString +
		"</rdf:RDF>";

		OutputStreamWriter rssOut = new OutputStreamWriter (new FileOutputStream (rssPath), "UTF-8");
		rssOut.write (rssString);
		rssOut.close ();

		System.out.println ("done.");
	}

	private static String getListSidebar (int levels) 
	{
		String lvlString = "";

		for (int i = 0; i < levels; i++)
		{
			lvlString += "../";
		}

		return "<div class=\"left\">" +
		"<p class=\"item-header\"><a href=\"" + lvlString + "index.html\">Home</a></p>" +
		"<p class=\"item-header\">Lists</p>" +
		"<p class=\"item\"><a href=\"" + lvlString +"lists/genre/index.html\">All Genres</a></p>" +
		"<p class=\"item\"><a href=\"" + lvlString +"lists/authors/index.html\">All Authors</a></p>" +
		"<p class=\"item\"><a href=\"" + lvlString +"lists/lists/index.html\">All Lists</a></p>" +
		"<p class=\"item\"><a href=\"" + lvlString +"lists/titles/index.html\">All Books</a></p>" +
		"</div>";
	}

	@SuppressWarnings("unchecked")
	private static void buildAuthorsList() throws IOException 
	{
		System.out.print ("Outputting authors lists... ");
		String filePath = destination.getAbsolutePath () + "/lists/authors";

		File authorsIndex = new File (filePath);
		authorsIndex.mkdirs ();

		Object[] authorList = authors.keySet().toArray ();

		// Check for author list sorting and sort appropriately

		/* String[] commands = {"/usr/bin/defaults", "read", "net.aetherial.books.Books", "Sort People Names"};

		Process p = Runtime.getRuntime().exec (commands);

		BufferedReader in = new BufferedReader (new InputStreamReader (p.getInputStream ()));

		boolean authorSort = true;

		try 
		{
			p.waitFor();

			String results = in.readLine ().trim ();

			System.out.println ("Author sort: "+ results);

			if (results.equalsIgnoreCase ("Yes"))
				authorSort = true;
		}
		catch (Exception e) 
		{

		}

		if (authorSort)
		{
			Arrays.sort (authorList, new AuthorComparator ());
		}
		else
			Arrays.sort (authorList);
		*/

		Arrays.sort (authorList, new AuthorComparator ());
		// Arrays.sort (authorList);

		String htmlString = getHeader (2, "All Authors");

		htmlString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a></div>";

		htmlString += getListSidebar (2);

		htmlString += "<div class=\"metadata\">";

		for (int i = 0; i < authorList.length; i++)
		{
			htmlString += "<p class=\"list-item\"><a href=\"" + getFilename ((String) authorList[i]) + ".html\">" + authorList[i] + "</a></p>";

			String authorPath = destination.getAbsolutePath () + "/lists/authors/" + getFilename ((String) authorList[i]) + ".html";

			File authorPage = new File (authorPath);
			authorPage.createNewFile ();

			ArrayList authorBooks = (ArrayList) authors.get (authorList[i]);

			Collections.sort (authorBooks, TitleComparator.getInstance ());

			String authorString = getHeader (2, (String) authorList[i]);

			authorString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a></div>";

			authorString += getListSidebar (2);

			authorString += "<div class=\"metadata\">";

			for (int j = 0; j < authorBooks.size (); j++)
			{
				HashMap fields = (HashMap) authorBooks.get (j);

				authorString += "<p class=\"list-item\"><a href=\"../../books/" + fields.get ("id") + "/index.html\">"+  fields.get ("title") + "</a></p>";
			}

			authorString += "</div>";

			authorString += getFooter ();

			OutputStreamWriter aout = new OutputStreamWriter (new FileOutputStream (authorPage), "UTF-8");

			aout.write (authorString);

			aout.close ();
		}

		htmlString += "</div>";

		htmlString += getFooter ();

		OutputStreamWriter out = new OutputStreamWriter (new FileOutputStream (authorsIndex.getAbsolutePath() + "/index.html"), "UTF-8");

		out.write (htmlString);

		out.close ();

		System.out.println ("done.");
	}

	@SuppressWarnings("unchecked")
	private static void buildGenreList() throws IOException 
	{
		System.out.print ("Outputting genre lists... ");
		String filePath = destination.getAbsolutePath () + "/lists/genre";

		File genreIndex = new File (filePath);
		genreIndex.mkdirs ();

		Object[] genreList = genres.keySet().toArray ();

		Arrays.sort (genreList);

		String htmlString = getHeader (2, "All Genres");

		htmlString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a></div>";

		htmlString += getListSidebar (2);

		htmlString += "<div class=\"metadata\">";

		for (int i = 0; i < genreList.length; i++)
		{
			htmlString += "<p class=\"list-item\"><a href=\"" + getFilename ((String) genreList[i]) + ".html\">" + genreList[i] + "</a></p>";

			String genrePath = destination.getAbsolutePath () + "/lists/genre/" + getFilename ((String) genreList[i]) + ".html";

			File genrePage = new File (genrePath);
			genrePage.createNewFile ();

			ArrayList genreBooks = (ArrayList) genres.get (genreList[i]);

			Collections.sort (genreBooks, TitleComparator.getInstance ());

			String genreString = getHeader (2, (String) genreList[i]);

			genreString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a></div>";

			genreString += getListSidebar (2);

			genreString += "<div class=\"metadata\">";

			for (int j = 0; j < genreBooks.size (); j++)
			{
				HashMap fields = (HashMap) genreBooks.get (j);

				genreString += "<p class=\"list-item\"><a href=\"../../books/" + fields.get ("id") + "/index.html\">"+  fields.get ("title") + "</a></p>";
			}

			genreString += "</div>";

			genreString += getFooter ();

			OutputStreamWriter gout = new OutputStreamWriter (new FileOutputStream (genrePage), "UTF-8");

			gout.write (genreString);

			gout.close ();
		}

		htmlString += "</div>";

		htmlString += getFooter ();

		OutputStreamWriter out = new OutputStreamWriter (new FileOutputStream (genreIndex.getAbsolutePath() + "/index.html"), "UTF-8");

		out.write (htmlString);

		out.close ();

		System.out.println ("done.");
	}

	private static String getFilename (String string) 
	{
		if (stringCodes == null)
			stringCodes = new ArrayList<String> ();

		for (int i = 0; i < stringCodes.size (); i++)
		{
			if (string.equals (stringCodes.get (i)))
				return "" + i;
		}

		stringCodes.add (string);

		return "" + (stringCodes.size () - 1);

		// return string.replaceAll ("<", "").replaceAll (">", "").replaceAll ("&", "").replaceAll (" ", "").replaceAll ("/", "").replaceAll (";", "");
	}

	private static void createDestination() 
	{
		if (destination.exists ())
		{
			String destPath = destination.getAbsolutePath ();
			destination.renameTo (new File (destination.getAbsolutePath () + " - Old"));

			destination = new File (destPath);
		}

		destination.mkdirs ();

	}

	private static void buildBooks () throws IOException, ParseException 
	{
		System.out.print ("Outputting books... ");

		Element exportData = xmlDocument.getDocumentElement ();

		NodeList nl = exportData.getElementsByTagName ("Book");

		for (int i = 0; i < nl.getLength (); i++)
		{
			Element book = (Element) nl.item (i);

			if (!(book.getAttribute ("id").equals ("")))
			{
				HashMap<String, String> fields = new HashMap<String, String> ();

				NodeList fieldElements = book.getChildNodes ();

				for (int j = 0; j < fieldElements.getLength (); j++)
				{
					Element field = (Element) fieldElements.item (j);

					String key = field.getAttribute ("name");
					String value = field.getTextContent ().trim ();

					fields.put (key, value);
				}

				fields.put ("id", "" + i);

				if (fields.get ("genre") == null)
					fields.put ("genre", "Uncategorized");

				allBooks.add (fields);

				writeHTMLPage (fields);
			}
		}

		System.out.println ("done.");
	}

	@SuppressWarnings("unchecked")
	private static void writeHTMLPage(HashMap<String, String> fields) throws IOException, ParseException 
	{
		String filePath = destination.getAbsolutePath () + "/books/" + fields.get ("id");

		File bookDir = new File (filePath);

		bookDir.mkdirs ();

		String htmlString = getHeader (2, fields.get ("title"));

		// htmlString += "<div class=\"navigation\"><a href=\"../../index.html\">My Books</a>: <a href=\"../../lists/genre/index.html\">Genres</a>: " + 
		// "<a href=\"../../lists/genre/" + getFilename (fields.get ("genre")) + ".html\">" + fields.get ("genre") + "</a></div>";

		String isbn = fields.get ("isbn");

		if (isbn != null && !isbn.equals (""))
		{
			isbn = isbn.replaceAll ("-", "").replaceAll (" ", "");

			htmlString += "<div class=\"buy\">Buy online: <a href=\"http://www.amazon.com/exec/obidos/ASIN/" + isbn + "/aetherialnu-20a\">Amazon</a></div>";
		}

		if (fields.get ("coverImage") != null)
		{
			String coverPath = source.getParent () + "/" + fields.get ("coverImage");

			try
			{
				File srcCover = new File (coverPath);
				File destCover = new File (filePath + "/cover.png");

				BufferedInputStream fin = new BufferedInputStream (new FileInputStream (srcCover));
				BufferedOutputStream fout = new BufferedOutputStream (new FileOutputStream (destCover));

				ByteArrayOutputStream bout = new ByteArrayOutputStream ();

				byte[] buf = new byte[4096];
				int read = 0;

				while ((read = fin.read (buf, 0, buf.length)) != -1)
				{
					bout.write (buf, 0, read);
				}

				fin.close ();

				fout.write (bout.toByteArray ());
				fout.close ();

				ByteArrayInputStream bin = new ByteArrayInputStream (bout.toByteArray ());

				SeekableStream s = SeekableStream.wrapInputStream (bin, true);
				RenderedOp objImage = JAI.create ("stream", s);
				((OpImage) objImage.getRendering ()).setTileCache (null);

				float width = 100;
				float height = 150;

				float xScale = width/objImage.getWidth ();
				float yScale = height/objImage.getHeight ();

				float scale = xScale;

				if (xScale > yScale)
					scale = yScale;

				ParameterBlock pb = new ParameterBlock ();
				pb.addSource (objImage); // The source image
				pb.add (scale);         // The xScale
				pb.add (scale);         // The yScale
				pb.add (0.0F);           // The x translation
				pb.add (0.0F);           // The y translation
				pb.add (new InterpolationNearest()); // The interpolation 

				objImage = JAI.create ("scale", pb, null);

				FileOutputStream out = new FileOutputStream (filePath + "/thumbnail.png");

				EncodeDescriptor.create (objImage, out, "PNG", null, new RenderingHints (null));

				out.flush ();
				out.close ();

				htmlString += "<a href=\"cover.png\"><img src=\"cover.png\" class=\"cover\" /></a>";
			}
			catch (Exception e)
			{
				htmlString += getListSidebar (2);
			}
		}
		else
		{
			htmlString += getListSidebar (2);
		}

		htmlString += "<div class=\"metadata\"><table class=\"book-def\">";

		ArrayList keys = getKeys ();

		for (int i = 0; i < keys.size (); i++)
		{
			String key = (String) keys.get (i);

			String value = fields.get (key);

			if (value != null && ! value.equals (""))
			{
				value = value.trim ();
				
				String collector = "";
				
				for (String v : value.split (";"))
				{
					v = v.trim ();
					
					if (v.startsWith ("Ê"))
						v = v.substring (1);
					
					if (key.equals ("authors"))
					{
						ArrayList<HashMap> list = (ArrayList) authors.get (v);

						if (list == null)
						{
							list = new ArrayList<HashMap> ();

							authors.put (v, list);
						}

						list.add (fields);

						v = "<a href=\"../../lists/authors/" + getFilename (v) + ".html\">" + v + "</a>";
					}
					else if (key.equals ("genre"))
					{
						ArrayList<HashMap> list = (ArrayList) genres.get (v);

						if (list == null)
						{
							list = new ArrayList<HashMap> ();

							genres.put (v, list);
						}

						list.add (fields);

						v = "<a href=\"../../lists/genre/" + getFilename (v) + ".html\">" + v + "</a>";
					}
					else if (key.equals ("listName"))
					{
						ArrayList<HashMap> list = (ArrayList) lists.get (v);

						if (list == null)
						{
							list = new ArrayList<HashMap> ();

							lists.put (v, list);
						}

						list.add (fields);

						v = "<a href=\"../../lists/lists/" + getFilename (v) + ".html\">" + v + "</a>";
					}
					else if (key.equals ("publishDate"))
					{
						if (sdfIn == null)
						{
							sdfIn = new SimpleDateFormat ("yyyy-MM-dd");

							sdfOut = new SimpleDateFormat ("MMMM yyyy");
						}

						v = sdfOut.format (sdfIn.parse (v));
					}
					
					if (collector.length () > 0)
						collector += ", ";
				
					collector += v;
				}

				htmlString += "<tr><td class=\"key\">" + getFieldName (key) + ":</td><td class=\"value\">" + collector + "</td></tr>";
			}
		}

		htmlString += "</table></div>";

		htmlString += getFooter ();

		OutputStreamWriter out = new OutputStreamWriter (new FileOutputStream (bookDir.getAbsolutePath () + "/index.html"), "UTF-8");

		out.write (htmlString);

		out.close ();
	}

	private static String getFieldName (String key) 
	{
		if (keyTitles == null)
		{
			keyTitles = new HashMap<String, String> ();

			keyTitles.put ("title", "Title");
			keyTitles.put ("authors", "Author(s)");
			keyTitles.put ("illustrators", "Illustrator(s)");
			keyTitles.put ("editors", "Editor(s)");
			keyTitles.put ("publisher", "Publisher");
			keyTitles.put ("publishDate", "Publication Date");
			keyTitles.put ("summary", "Summary");
			keyTitles.put ("genre", "Genre");
			keyTitles.put ("listName", "List Name");
			keyTitles.put ("isbn", "ISBN");
		}

		String s = (String) keyTitles.get (key);

		if (s == null)
			s = key;

		return s;
	}

	@SuppressWarnings("unchecked")
	private static ArrayList getKeys() 
	{
		if (keyList == null)
		{
			keyList = new ArrayList<String> ();

			keyList.add ("title");
			keyList.add ("authors"); 
			keyList.add ("illustrators"); 
			keyList.add ("editors");
			keyList.add ("publisher"); 
			keyList.add ("publishDate"); 
			keyList.add ("genre");
			keyList.add ("summary");
			keyList.add ("listName");
			keyList.add ("isbn");
		}

		return keyList;
	}

	private static String escape (String string)
	{
		if (string == null)
			string = "Unknown";

		return string.replaceAll ("<", "&lt;").replaceAll (">", "&gt;").replaceAll ("&amp;", "&").replaceAll ("&", "&amp;");
	}

	private static String getHeader (int levelCount, String title)
	{
		String levels = "";

		for (int i = 0; i < levelCount; i++)
		{
			levels += "../";
		}

		String htmlString = 	"<html>\n" +
		"	<head>\n" + 
		"		<link rel=\"stylesheet\" type=\"text/css\" href=\"" + levels + "style/style.css\" />\n" +
		"		<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"" + levels + "index.rss\" />" +
		"		<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n" +
		"		<title>" + escape  (title) + "</title>\n" +
		"	</head>\n" + 
		"	<body>\n" +
		"	<table cellpadding=\"0\" cellspacing=\"0\">\n" + 
		"		<tr><td class=\"top-left\"> </td><td class=\"top-center\"> </td><td class=\"top-right\"> </td></tr>\n" +
		"		<tr><td class=\"left-center\"> </td><td class=\"center\"><div class=\"contents\">\n" +
		"			<div class=\"page-title\">" + escape  (title) + "</div>\n";

		return htmlString;
	}

	private static String getFooter () 
	{
		return 	"			</td><td class=\"right-center\"> </td></tr>\n" +
		"			<tr><td class=\"bottom-left\"> </td><td class=\"bottom-center\"> </td><td class=\"bottom-right\"> </td></tr>\n" +
		"		</table>\n" +
		"		<div class=\"footer\">\n" + 
		"			Site generated by <a href=\"http://books.aetherial.net\">Books</a>.\n" + 
		"			Aesthetics by <a href=\"http://www.filament21.com\">Jon Fernandez</a>.\n" +
		"		</div>\n" + 
		"	</body>\n" + 
		"</html>";
	}
}
