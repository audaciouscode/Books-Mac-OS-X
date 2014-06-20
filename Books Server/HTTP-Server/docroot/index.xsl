<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no" media-type="text/xml" />

	<xsl:template match="/index">
		<html>
			<head>
				<title><xsl:value-of select="@title" /></title>
				<link rel="stylesheet" href="/style/style.css" type="text/css" />
				<link rel="alternate" type="application/rss+xml" title="RSS Feed" href="/list/title/?format=xml" />
				<meta http-equiv="pragma" content="nocache" />
				<meta http-equiv="expires" content="Sun, 4 Oct 1998 15:00:00 GMT" />
			</head>
			<body>
				<div class="content">
					<div class="header">
						<div class="title"><xsl:value-of select="@title" /></div>
						<div class="subtitle">Powered by <a href="http://books.aetherial.net">Books</a>.</div>
					</div>
					<div class="middle">
						<div class="left">
							<div class="module-typelist module">
								<h2 class="module-header">Random Books</h2>
								<div class="module-content">
									<ul class="module-list">
										<xsl:apply-templates select="book" />
									</ul>
								</div>
							</div>

							<div class="module-typelist module">
								<h2 class="module-header">Browse Lists</h2>
								<div class="module-content">
									<ul class="module-list">
										<xsl:apply-templates select="link" />
									</ul>
								</div>
							</div>

							<div class="module-typelist module">
								<h2 class="module-header">Watch This Page</h2>
								<div class="module-content">
									<ul class="module-list">
										<li class="module-list-item"><a href="/list/title/?format=xml">All Books (RSS)</a></li>
										<li class="module-list-item"><a href="/list/title/?format=photocast">All Books (Photocast)</a></li>
									</ul>
								</div>
							</div>

						</div>
						<div class="right">
							<div class="search">
								<form method="get" action="/search/">
									Search: <input type="hidden" name="field" value="title" />
									<input type="hidden" name="operation" value="contains" />
									<input name="query" type="search" placeholder="Find a book."/>
								</form>
							</div>

							<p>This site is a web-enabled copy of a <a href="http://books.aetherial.net">Books</a> collection. The collection's owner has put this online for your searching and browsing.</p>
							
							<p>A few quick tips to help you get started using this site:</p>
							
							<p>1. If you'd like to find a particular book, use the search field located in the upper-right of each page. This field will search for books with titles containing the text you type.</p>

							<p>2. To quickly skim a list of books, check out the "Browse Lists" section of the toolbar to the left.</p>

							<p>3. On individual book pages, you can discover other books that share a particular property by clicking on the field in question. If you'd like to find books that share the samme author, click the author's name.</p>
							
							<p>4. To view a larger version of the cover image for a particular book, click the image in the toolbar.</p>

							<p>5. If you'd like to keep an eye on a list of books for additions or modifications, use the RSS links in the toolbar in the left. These links allow your RSS client to "watch" the contents of the list in question.</p>

							<p>6. The photocast link is similar to the RSS link in that it allows iPhoto to view a list of books by cover image.</p>

							<p>If you have any questions about the content of the this site, contact its owner. If you have question about the software (or would like to use it yourself), <a href="http://books.aetherial.net">visit the Books website</a>.</p>
						</div>
					</div>
					<div class="footer"><a href="http://books.aetherial.net">Books</a> © 2003-2006 Chris J. Karr. Site design inspired by <a href="http://www.karelia.com/">Karelia's Sandvox</a>.</div>
				</div>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="link">
		<li class="module-list-item">
			<a>
				<xsl:attribute name="href"><xsl:value-of select="@href" /></xsl:attribute>
				<xsl:value-of select="@title" />
			</a>
		</li>
	</xsl:template>

	<xsl:template match="book">
		<li class="module-list-item">
			<a>
				<xsl:attribute name="href"><xsl:value-of select="@link" /></xsl:attribute>
				<xsl:value-of select="@title" />
			</a>
		</li>
	</xsl:template>

</xsl:stylesheet>