<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="text"/>
    
    <xsl:template match="report">
        <xsl:value-of>
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//OECD//NONSGML v1.0//EN
        </xsl:value-of>

        <xsl:apply-templates select="row">
            <xsl:sort select="position()" data-type="number" order="descending"/>
        </xsl:apply-templates>

        <xsl:value-of>
END:VCALENDAR            
        </xsl:value-of>
    </xsl:template>
    
    <xsl:template match="row[@index!='0']">
        <xsl:variable name="summary" select="cell[@name='title']"/>
        <xsl:variable name="description" 
            select="concat($summary, ' ', cell[@name='subtitle'])"/>
BEGIN:VEVENT
UID:no-reply@embargoes.oecd.org
SUMMARY:<xsl:value-of select="$summary"/>
DESCRIPTION:<xsl:value-of select="$description"/>
DTSTAMP:<xsl:value-of 
            select="format-dateTime(
                cell[@name='embargo date'], 
                '[Y0001][M01][D01]T[h01][m01][s01]Z')"/>
BEGIN:VALARM
TRIGGER:-PT48H
REPEAT:1
DURATION:PT15M
ACTION:DISPLAY
DESCRIPTION:Reminder: <xsl:value-of select="$summary"/>
END:VALARM
END:VEVENT
    </xsl:template>
    
    <xsl:template match="cell"/>
</xsl:stylesheet>
