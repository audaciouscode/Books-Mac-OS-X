<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" >
	<xsl:output method="text"/>

	<xsl:template match="/exportData">
package net.aetherial.books.me;

import java.util.*;

public class BookCollection 
{
	private static BookCollection collection;
	
	private Vector books;
	
	public BookCollection ()
	{
		books = new Vector ();
	}
	
	public Book getBookAtIndex (int index)
	{
		return (Book) books.elementAt (index);
	}
	
	public int size ()
	{
		return books.size ();
	}
	
	public static BookCollection getCollection ()
	{
		if (collection == null)
		{
			collection = new BookCollection ();
		
			Book b;

		<xsl:apply-templates select="Book" />			
			collection.sort ();
		}
		
		return collection;
	}
	
	public void sort ()
	{
		books = Utils.sortBooks (books);
	}
	
	public void addBook (Book b)
	{
		books.addElement (b);
	}
	
	public Vector findBooks(String query) 
	{
		System.out.println ("Looking for " + query);
		
		Vector results = new Vector ();
		
		for (int i = 0; i &lt; books.size(); i++)
		{
			Book b = (Book) books.elementAt (i);
			
			String title = b.getValue ("Title");
			
			if (title != null)
			{
				if (query == null || query.equals (""))
					results.addElement (b);
				else if (title.toLowerCase().indexOf (query.toLowerCase()) != -1)
					results.addElement (b);
			}
		}
		
		return results;
	}
	
	public int indexOf (Book b)
	{
		return books.indexOf (b);
	}
}
	</xsl:template>

	<xsl:template match="Book">
			b = new Book ();
			<xsl:apply-templates select="field[@name='title']" />
			<xsl:apply-templates select="field[@name='authors']" />
			<xsl:apply-templates select="field[@name='isbn']" />
			<xsl:apply-templates select="field[@name='publishDate']" />
			<xsl:apply-templates select="field[@name='publisher']" />
			collection.addBook (b);
	</xsl:template>

	<xsl:template match="field">
		<xsl:if test="@name='publishDate'">
			b.setValue ("publishDate", "<xsl:value-of select="substring(.,0,5)" />");
		</xsl:if>
		<xsl:if test="@name!='publishDate'">
			b.setValue ("<xsl:value-of select="@name" />", "<xsl:value-of select="translate (., '&quot;', ' ')" />");
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>