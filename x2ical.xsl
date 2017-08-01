<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY space "&#032;">
<!ENTITY crlf "&#xd;&#xa;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xmlns:local="local"
    version="2.0">
    
    <xsl:output method="text" indent="no" encoding="UTF-8" />
    
    <xsl:variable name="root" select="/"/>
    
    <xsl:template match="report">
        <xsl:variable name="unique-embargo-dates" select="distinct-values(//row[@index != '0']/cell[@name='embargo date'])"/>
        <xsl:message select="concat('TOTAL: ', count(//row)-1)"/>
        <xsl:message select="concat('UNIQUE: ', count($unique-embargo-dates))"/>
        <xsl:text disable-output-escaping="yes">BEGIN:VCALENDAR&#xd;&#xa;</xsl:text>
        <xsl:text disable-output-escaping="yes">VERSION:2.0&#xd;&#xa;</xsl:text>
        <xsl:text disable-output-escaping="yes">PRODID:-//OECD Embargo Calendar//NONSGML v1.0//EN&#xd;&#xa;</xsl:text>

        <xsl:for-each select="$unique-embargo-dates">
            <xsl:sort order="ascending"/>
            <xsl:call-template name="tpl-create-event"/>
        </xsl:for-each>
        
        <xsl:text>
END:VCALENDAR</xsl:text>
    </xsl:template>
    
    <xsl:template match="cell"/>
    
    <xsl:template name="tpl-create-event">
        <xsl:param name="time" select="."/>
        <xsl:variable name="publications" select="$root//row[cell[@name='embargo date']/text() eq $time]"/>
        <xsl:variable name="count" select="count($publications)"/>
        <xsl:variable name="first-publication" select="$publications[1]"/>
        <xsl:variable name="summary" select="normalize-space($first-publication/cell[@name='title'])"/>
        <xsl:variable name="description" select="concat(
            '&quot;', $summary, ' - ', normalize-space($first-publication/cell[@name='subtitle']), '&quot; and ', 
            if ($count eq 2) then 'one' else $count - 1, 
            ' other publication',
            if ($count gt 2) then 's.' else '.'
        )"/>
        <xsl:variable name="start-time" select="format-dateTime(
            $time, 
            '[Y0001][M01][D01]T[h01][m01][s01]Z'
        )"/>
        <xsl:variable name="end-time" select="format-dateTime(
            xs:dateTime($time) + xs:dayTimeDuration('PT15M'),
            '[Y0001][M01][D01]T[h01][m01][s01]Z'
        )"/>
BEGIN:VEVENT
UID:<xsl:value-of select="generate-id($first-publication)"/>@embargoes.oecd.org
SUMMARY:<xsl:value-of select="local:split-by-char($summary)"/>
DESCRIPTION:<xsl:value-of select="local:split-by-char($description)"/>
DTSTAMP:<xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001][M01][D01]T[h01][m01][s01]Z')"/>
DTSTART:<xsl:value-of select="$start-time"/>
DTEND:<xsl:value-of select="$end-time"/>
TRANSP:TRANSPARENT
BEGIN:VALARM
TRIGGER:-PT48H
REPEAT:1
DURATION:PT15M
ACTION:DISPLAY
DESCRIPTION:<xsl:value-of select="local:split-by-char(concat('Reminder: ', $summary))"/>
END:VALARM
END:VEVENT
</xsl:template>

    <xsl:function name="local:split-by-char">
        <xsl:param name="string"/>
        <xsl:variable name="char" select="40"/>
        <xsl:for-each select="0 to (string-length($string) - 1) idiv $char">
            <xsl:value-of select="concat(substring($string, . * $char + 1, $char), '&#xd;&#xa;&#032;')" disable-output-escaping="yes"/>
        </xsl:for-each>
    </xsl:function>
</xsl:stylesheet>
