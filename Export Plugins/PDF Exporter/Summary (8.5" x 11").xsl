<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:fo="http://www.w3.org/1999/XSL/Format" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" version="1.0" >
	<xsl:output method="xml" omit-xml-declaration="yes" />

	<xsl:param name="date">unknown</xsl:param>
	
	<xsl:template match="/exportData">
		<fo:root>
			<fo:layout-master-set>
				<fo:simple-page-master master-name="Letter"
					page-height="11in" page-width="8.5in" margin="0.5in">
					<fo:region-body margin-top="0.25in" margin-bottom="0.25in" />
					<!-- <fo:region-before extent="1.0em" /> -->
					<fo:region-after extent="1.0em" />
				</fo:simple-page-master>
			</fo:layout-master-set>

			<fo:page-sequence master-reference="Letter" font-family="Cyberbit, Arial">
				<!-- <fo:static-content flow-name="xsl-region-before">
					<fo:block text-align="right">Generated on <xsl:value-of select="$date"/></fo:block>
				</fo:static-content> -->
				<fo:static-content flow-name="xsl-region-after">
					<fo:block-container absolute-position="fixed" top="10.5in" left="4.0in" width="4.0in">
						<fo:block text-align="right">
							Page <fo:page-number/> of
							<fo:page-number-citation ref-id="theEnd"/>
						</fo:block>
					</fo:block-container>
					<fo:block-container absolute-position="fixed" top="10.5in" left="0.5in" width="4.0in">
						<fo:block text-align="left">
							Generated on <xsl:value-of select="$date"/>
						</fo:block>
					</fo:block-container>
				</fo:static-content>
				<fo:flow flow-name="xsl-region-body">
					<fo:block-container absolute-position="fixed" top="0.5in" left="0.5in" width="7.5in">
						<fo:block font-size="18pt" >
							My Book Collection
						</fo:block>
					</fo:block-container>
					<fo:block margin-top="0.25in" margin-bottom="0.25in">
						<xsl:value-of select="count(Book)"/> records printed.
					</fo:block>
					<xsl:apply-templates select="Book" />
					<fo:block id="theEnd"/>
				</fo:flow>
			</fo:page-sequence>
		</fo:root>
	</xsl:template>

	<xsl:template match="Book">
		<fo:block margin-top="0.0625in" margin-bottom="0.5in">
			<xsl:apply-templates select="field[@name='title']" />
			<xsl:apply-templates select="field[@name='authors']" />
			<xsl:apply-templates select="field[@name='illustrators']" />
			<xsl:apply-templates select="field[@name='isbn']" />
			<xsl:apply-templates select="field[@name='summary']" />
		</fo:block>
	</xsl:template>

	<xsl:template match="field">
		<xsl:if test="text()!=''">
			<xsl:if test="@name='authors'">
				<fo:block>
					Authors: <xsl:apply-templates select="text()" />
				</fo:block>
			</xsl:if>
			<xsl:if test="@name='illustrators'">
				<fo:block>
					Illustrators: <xsl:apply-templates select="text()" />
				</fo:block>
			</xsl:if>
			<xsl:if test="@name='isbn'">
				<fo:block>
					ISBN: <xsl:apply-templates select="text()" />
				</fo:block>
			</xsl:if>
			<xsl:if test="@name='summary'">
				<fo:block margin-top="1em" text-align="justify">
					Summary: <xsl:apply-templates select="text()" />
				</fo:block>
			</xsl:if>
			<xsl:if test="@name='title'">
				<fo:block font-weight="bold">
					<xsl:apply-templates select="text()" />
				</fo:block>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="text()">
		<xsl:value-of select="." />
	</xsl:template>
</xsl:stylesheet>