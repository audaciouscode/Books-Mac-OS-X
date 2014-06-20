<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/">
	<xsl:output version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no" media-type="text/html" />
	<xsl:template match="Book">
		<html>
			<head>
				<title><xsl:value-of select="field[@name='title']"/></title>
				<link rel="stylesheet" href="/style/style.css" type="text/css" />
			</head>
			<body>
				<div class="content">
					<div class="page-header">
						<div class="page-title"><xsl:apply-templates select="field[@name='title']"/></div>
						<div class="subtitle">Powered by <a href="http://books.aetherial.net">Books</a>.</div>
					</div>
					<div class="middle">
						<div class="left">
							<xsl:apply-templates select="field[@name='coverImage']"/>

							<div class="module-typelist module">
								<h2 class="module-header">Navigation</h2>
								<div class="module-content">
									<ul class="module-list">
										<li class="module-list-item"><a href="/">Home</a></li>
									</ul>
								</div>
							</div>
						
							<div class="module-typelist module">
								<h2 class="module-header">Browse Lists</h2>
								<div class="module-content">
									<ul class="module-list">
										<li class="module-list-item"><a href="/list/genre">Browse by genre</a></li>
										<li class="module-list-item"><a href="/list/listName">Browse by list</a></li>
										<li class="module-list-item"><a href="/list/authors">Browse by authors</a></li>
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
							<xsl:apply-templates select="field[@name='authors']"/>
							<xsl:apply-templates select="field[@name='illustrators']"/>
							<xsl:apply-templates select="field[@name='publisher']"/>
							<xsl:apply-templates select="field[@name='publishDate']"/>
							<xsl:apply-templates select="field[@name='listName']"/>
							<xsl:apply-templates select="field[@name='summary']"/>
						</div>
					</div>
					<div class="footer"><a href="http://books.aetherial.net">Books</a> © 2003-2006 Chris J. Karr. Site design inspired by <a href="http://www.karelia.com/">Karelia's Sandvox</a>.</div>
				</div>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="field">
		<xsl:choose>
			<xsl:when test="@name='coverImage'">
				<div class="module-typelist module">
					<h2 class="module-header">Cover Image</h2>
					<div class="module-content">
						<a>
						<xsl:attribute name="href">
							/export/<xsl:value-of select="." />
						</xsl:attribute>
						<center><img width="150" border="1">
							<xsl:attribute name="src">
								/export/<xsl:value-of select="." />
							</xsl:attribute>
						</img></center>
						</a>
					</div>
				</div>		
			</xsl:when>
			<xsl:when test="@name='title'">
				<xsl:value-of select="." />
			</xsl:when>
			<xsl:when test="@name='summary'">
				<p>Summary: <xsl:copy-of select="." /></p>
			</xsl:when>
			<xsl:when test="@name='authors'">
				<p>Authors:
					<a>
						<xsl:attribute name="href">
							/list/<xsl:value-of select="@name" />/<xsl:value-of select="."/>
						</xsl:attribute>
						<xsl:value-of select="." />
					</a>
				</p>
			</xsl:when>
			<xsl:when test="@name='illustrators'">
				<p>Illustrators:
					<a>
						<xsl:attribute name="href">
							/list/<xsl:value-of select="@name" />/<xsl:value-of select="."/>
						</xsl:attribute>
						<xsl:value-of select="." />
					</a>
				</p>
			</xsl:when>
			<xsl:when test="@name='publisher'">
				<p>Publisher:
					<a>
						<xsl:attribute name="href">
							/list/<xsl:value-of select="@name" />/<xsl:value-of select="."/>
						</xsl:attribute>
						<xsl:value-of select="." />
					</a>
				</p>
			</xsl:when>
			<xsl:when test="@name='listName'">
				<p>Books List:
					<a>
						<xsl:attribute name="href">
							/list/<xsl:value-of select="@name" />/<xsl:value-of select="."/>
						</xsl:attribute>
						<xsl:value-of select="." />
					</a>
				</p>
			</xsl:when>
			<xsl:when test="@name='publishDate'">
				<p>Publication Date: <xsl:value-of select="@formatted-date" /></p>
			</xsl:when>
			<xsl:otherwise>
				<p><xsl:value-of select="@name" />: 
					<a>
						<xsl:attribute name="href">
							/list/<xsl:value-of select="@name" />/<xsl:value-of select="."/>
						</xsl:attribute>
						<xsl:value-of select="." />
					</a>
				</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>