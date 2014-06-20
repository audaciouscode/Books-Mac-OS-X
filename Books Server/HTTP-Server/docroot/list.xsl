<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
	<xsl:output version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no" media-type="text/xml" />

	<xsl:template match="RDF">
		<html>
			<head>
				<title><xsl:value-of select="channel/title" /></title>
				<link rel="stylesheet" href="/style/style.css" type="text/css" />
				<link rel="alternate" type="application/rss+xml" title="RSS Feed">
					<xsl:attribute name="href"><xsl:value-of select="channel/@about" />?format=xml</xsl:attribute>
				</link>
			</head>
			<body>
				<div class="content">
					<div class="page-header">
						<div class="page-title"><xsl:value-of select="channel/title" /></div>
						<div class="subtitle">Powered by <a href="http://books.aetherial.net">Books</a>.</div>
					</div>
					<div class="middle">
						<div class="left">
							<div class="module-typelist module">
								<h2 class="module-header">Navigation</h2>
								<div class="module-content">
									<ul class="module-list">
										<li class="module-list-item"><a href="/">Home</a></li>
										<xsl:apply-templates select="channel/description"/>
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
							<div class="module-typelist module">
								<h2 class="module-header">Watch This Page</h2>
								<div class="module-content">
									<ul class="module-list">
										<li class="module-list-item">
											<a>
												<xsl:attribute name="href"><xsl:value-of select="channel/@about" />?format=xml</xsl:attribute>
												This List (RSS)
											</a>
										</li>
										<li class="module-list-item">
											<a>
												<xsl:attribute name="href"><xsl:value-of select="channel/@about" />?format=photocast</xsl:attribute>
												This List (Photocast)
											</a>
										</li>
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
							<xsl:apply-templates select="item"/>
						</div>
					</div>
					<div class="footer"><a href="http://books.aetherial.net">Books</a> © 2003-2006 Chris J. Karr. Site design inspired by <a href="http://www.karelia.com/">Karelia's Sandvox</a>.</div>
				</div>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="description">
		<xsl:if test="@previousPage">
			<li class="module-list-item">
				<a>
					<xsl:attribute name="href"><xsl:value-of select="@previousPage" /></xsl:attribute>
					Previous Page
				</a>
			</li>
		</xsl:if>
		<xsl:if test="@nextPage">
			<li class="module-list-item">
				<a>
					<xsl:attribute name="href"><xsl:value-of select="@nextPage" /></xsl:attribute>
					Next Page
				</a>
			</li>
		</xsl:if>
	</xsl:template>

	<xsl:template match="item">
		<p>
			<a>
				<xsl:attribute name="href"><xsl:value-of select="link" /></xsl:attribute>
				<xsl:value-of select="title" />
			</a>
		</p>
	</xsl:template>

	<xsl:template match="image">
		<img border="1" width="200">
			<xsl:attribute name="src">/export/<xsl:value-of select="." /></xsl:attribute>
		</img><br />
	</xsl:template>

</xsl:stylesheet>