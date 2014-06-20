<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" >
	<xsl:output method="xml" omit-xml-declaration="yes" />

	<xsl:template match="/exportData">
		<exportData>
			<xsl:apply-templates select="Book" />			
		</exportData>
	</xsl:template>

	<xsl:template match="Book">
			<Book>
				<xsl:apply-templates select="field[@name='title']" />
				<xsl:apply-templates select="field[@name='authors']" />
				<xsl:apply-templates select="field[@name='illustrators']" />
				<xsl:apply-templates select="field[@name='editors']" />
				<xsl:apply-templates select="field[@name='genre']" />
				<xsl:apply-templates select="field[@name='isbn']" />
				<xsl:apply-templates select="field[@name='publishDate']" />
				<xsl:apply-templates select="field[@name='publisher']" />
				<xsl:apply-templates select="field[@name='listName']" />
				<xsl:apply-templates select="field[@name='summary']" />
				<xsl:apply-templates select="field[@name='coverImage']" />
				<!-- <xsl:apply-templates select="field[@name='id']" /> -->
				<field name="id">
					<xsl:value-of select="position() - 1" />
				</field>
			</Book>
	</xsl:template>

	<xsl:template match="field">
		<xsl:if test="text()">
			<xsl:copy-of select="." />
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>