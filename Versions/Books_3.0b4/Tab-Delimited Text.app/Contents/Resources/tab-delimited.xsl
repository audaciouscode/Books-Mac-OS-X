<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/">
<xsl:output version="1.0" encoding="UTF-8" indent="no" omit-xml-declaration="yes" method="text" />
<xsl:variable name="newline"><xsl:text>
</xsl:text></xsl:variable>
<xsl:variable name="tab"><xsl:text>&#x09;</xsl:text></xsl:variable>

<xsl:template match="/exportData">Title	Series	Genre	Authors	Editors	Illustrators	Translators	Publisher	Publish Date	ISBN	Keywords	Format	Edition	Publish Place	Length
<xsl:apply-templates select="Book" />
</xsl:template>

<xsl:template match="Book"><xsl:apply-templates select="field[@name='title']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='series']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='genre']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='authors']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='editors']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='illustrators']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='translators']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='publisher']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='publishDate']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='isbn']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='keywords']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='format']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='edition']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='publishPlace']"/><xsl:value-of select="$tab" /><xsl:apply-templates select="field[@name='length']"/><xsl:value-of select="$newline" /></xsl:template>

<xsl:template match="field"><xsl:value-of select="." />
 </xsl:template>

</xsl:stylesheet>