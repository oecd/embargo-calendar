<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:functx="http://www.functx.com"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" xmlns:local="local" version="2.0">
    
    <xsl:output method="text" indent="no" encoding="UTF-8" />
    <xsl:variable name="root" select="/"/>
    
    <xsl:template match="report">
        <!-- don't select the first row, don't select chapters, don't select graphs -->
        <xsl:variable name="unique-embargo-dates" 
            select="distinct-values(
            //row[@index != '0'][cell[@name='catalogue type'] != 'Chapter' and cell[@name='catalogue type'] != 'Graph']/cell[@name='embargo date']
            )"/>
        <xsl:message select="concat('TOTAL EMBARGOES: ', count(//row)-1)"/>
        <xsl:message select="concat('UNIQUE EMBARGOES: ', count($unique-embargo-dates))"/>
        <xsl:text disable-output-escaping="yes">BEGIN:VCALENDAR&#xd;&#xa;</xsl:text>
        <xsl:text disable-output-escaping="yes">VERSION:2.0&#xd;&#xa;</xsl:text>
        <xsl:text disable-output-escaping="yes">PRODID:-//OECD Embargo Calendar//NONSGML v1.0//EN&#xd;&#xa;</xsl:text>

        <xsl:for-each select="$unique-embargo-dates">
            <xsl:sort order="ascending"/>
            <xsl:call-template name="tpl-create-event"/>
        </xsl:for-each>
        
        <xsl:text>
END:VCALENDAR
</xsl:text>
    </xsl:template>
    
    <xsl:template match="cell"/>
    
    <xsl:template name="tpl-create-event">
        <xsl:param name="time" select="."/>
        <xsl:variable name="ics-date-picture" select="'[Y0001][M01][D01]T[h01][m01][s01]Z'"/>
        <xsl:variable name="publications" select="$root//row[@index != '0'][cell[@name='catalogue type'] != 'Chapter' and cell[@name='catalogue type'] != 'Graph'][cell[@name='embargo date']/text() eq $time]"/>
        <xsl:variable name="count" select="count($publications)"/>
<!--        <xsl:message select="concat('There are ', $count, ' publications')"/>-->
        <xsl:variable name="first-publication" select="$publications[1]"/>
        <xsl:variable name="summary" select="normalize-space($first-publication/cell[@name='title'])"/>
        <xsl:variable name="description" select="concat(
            '&quot;', $summary, ' - ', normalize-space($first-publication/cell[@name='subtitle']), '&quot; and ', 
            if ($count eq 2) then 'one' else $count - 1, 
            ' other publication',
            if ($count gt 2) then 's.' else '.'
        )"/>
        <xsl:variable name="start-time" select="format-dateTime($time, $ics-date-picture)"/>
        <xsl:variable name="end-time" select="format-dateTime(xs:dateTime($time) + xs:dayTimeDuration('PT15M'),$ics-date-picture)"/>
        <xsl:variable name="trigger-period" select="if (local:is-monday($time)) then '-PT72H' else '-PT48H'"/>
BEGIN:VEVENT
UID:<xsl:value-of select="generate-id($first-publication)"/>@embargoes.oecd.org
SUMMARY:<xsl:value-of select="local:split-by-char($summary)"/>
DESCRIPTION:<xsl:value-of select="local:split-by-char($description)"/>
DTSTAMP:<xsl:value-of select="format-dateTime(current-dateTime(), $ics-date-picture)"/>
DTSTART:<xsl:value-of select="$start-time"/>
DTEND:<xsl:value-of select="$end-time"/>
TRANSP:TRANSPARENT
BEGIN:VALARM
TRIGGER:<xsl:value-of select="$trigger-period"/>
REPEAT:1
DURATION:PT15M
ACTION:DISPLAY
DESCRIPTION:<xsl:value-of select="local:split-by-char(concat('Reminder: ', $summary))"/>
END:VALARM
END:VEVENT
</xsl:template>

    <!-- if embargo falls on a Monday, reminder needs to be earlier than 48 hours -->
    <xsl:function name="local:is-monday" as="xs:boolean">
        <xsl:param name="dateTime" as="xs:dateTime"/>
        <xsl:variable name="date" select="xs:date($dateTime)"/>
        <xsl:value-of select="functx:day-of-week($date) eq 1"/>
    </xsl:function>
    
    <xsl:function name="functx:day-of-week" as="xs:integer?"
        xmlns:functx="http://www.functx.com">
        <xsl:param name="date" as="xs:anyAtomicType?"/>
        
        <xsl:sequence select="
            if (empty($date))
            then ()
            else xs:integer((xs:date($date) - xs:date('1901-01-06'))
            div xs:dayTimeDuration('P1D')) mod 7
            "/>
    </xsl:function>

    <!-- to conform with Section "3.1. Content Lines" https://icalendar.org/iCalendar-RFC-5545/3-1-content-lines.html -->
    <xsl:function name="local:split-by-char">
        <xsl:param name="string"/>
        <xsl:variable name="char" select="40"/>
        <xsl:for-each select="0 to (string-length($string) - 1) idiv $char">
            <xsl:value-of select="concat(substring($string, . * $char + 1, $char), '&#xd;&#xa;&#032;')" disable-output-escaping="yes"/>
        </xsl:for-each>
    </xsl:function>
</xsl:stylesheet>
