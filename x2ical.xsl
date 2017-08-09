<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:functx="http://www.functx.com"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" xmlns:local="local" version="3.0">
    
    <xsl:output method="text" indent="no" encoding="UTF-8" />
    <xsl:variable name="root" select="/"/>
    
    <xsl:template match="report">
        <!-- don't select the first row, only get PDFs, don't select chapters, don't select graphs -->
        <xsl:variable name="relevant-embargoes" select="
            //row[@index != '0']
            [cell[@name='medium'] = 'PDF']
            [cell[@name='catalogue type'] != 'Chapter' and cell[@name='catalogue type'] != 'Graph']
            "/>
        <xsl:message select="concat('TOTAL EMBARGOES: ', count(//row)-1)"/>
        <xsl:message select="concat('RELEVANT EMBARGOES: ', count($relevant-embargoes))"/>
        <xsl:text disable-output-escaping="yes">BEGIN:VCALENDAR&#xd;&#xa;</xsl:text>
        <xsl:text disable-output-escaping="yes">VERSION:2.0&#xd;&#xa;</xsl:text>
        <xsl:text disable-output-escaping="yes">PRODID:-//OECD Embargo Calendar//NONSGML v1.0//EN&#xd;&#xa;</xsl:text>

        <xsl:for-each select="$relevant-embargoes">
            <xsl:sort order="ascending"/>
            <xsl:apply-templates select="."/>
        </xsl:for-each>
        
        <xsl:text>
END:VCALENDAR
</xsl:text>
    </xsl:template>
    
    <!-- create a calendar event -->
    <xsl:template match="row[@index != '0']">
        <xsl:variable name="ics-date-picture" select="'[Y0001][M01][D01]T[h01][m01][s01]Z'"/><!-- ICS date standard -->
        <xsl:variable name="human-date-picture" select="'[D] [MNn] [Y0001], [H]:[m01]'"/><!-- 9 August 2017, 22:08 -->
        
        <xsl:variable name="time" select="cell[@name='embargo date']"/>
        <xsl:variable name="directorate" select="cell[@name='directorate']"/>
        <xsl:variable name="doi" select="cell[@name='doi']"/>
        <xsl:variable name="doi-link" select="'https://doi.org/' || $doi"/>
        <xsl:variable name="language" select="cell[@name='language']"/>
        <xsl:variable name="title" select="cell[@name='title']"/>
        <xsl:variable name="subtitle" select="cell[@name='subtitle']"/>
        <xsl:variable name="publication-type" select="cell[@name='catalogue type']"/>

        <xsl:variable name="start-time" select="format-dateTime($time, $ics-date-picture)"/>
        <xsl:variable name="end-time" select="format-dateTime(xs:dateTime($time) + xs:dayTimeDuration('PT15M'),$ics-date-picture)"/>
        <xsl:variable name="trigger-period" select="if (local:is-monday($time)) then '-PT72H' else if (local:is-tuesday($time)) then '-PT24H' else '-PT48H'"/>
        <xsl:variable name="available-media" select="string-join(//row[cell[@name='doi']=$doi]/cell[@name='medium'], ', ')"/>
        <xsl:variable name="ilibrary-export" select="cell[@name='ilibrary last export date']"/>
        <xsl:variable name="freepreview-export" select="cell[@name='freepreview last export date']"/>
        <xsl:variable name="fti-loaded" select="cell[@name='fti loaded?']"/>
        <xsl:variable name="ics-summary" select="$title || ' on ' || format-dateTime($time, $human-date-picture)"/>
        <xsl:variable name="ics-description">
            <xsl:value-of expand-text="yes">{
                $title
                } {if (string-length($subtitle) > 0) then ' - ' || $subtitle else ''
                } by {$directorate
                } has an embargo date/time of {format-dateTime($time, $human-date-picture)
                }.\n\nDirectorate: {$directorate
                }\nLanguage: {$language
                }\nDOI: {$doi-link
                }\nPublication type: {$publication-type
                }\nReleased as: {$available-media
                }.\n\niLibrary export: {if (string-length($ilibrary-export) > 0) then format-dateTime($ilibrary-export, $human-date-picture) else 'never'
                }\nFreepreview export: {if (string-length($freepreview-export) > 0) then format-dateTime($freepreview-export, $human-date-picture) else 'never'
                }\nFTI loaded: {if (string-length($fti-loaded) > 0) then $fti-loaded else 'no'}.</xsl:value-of>
        </xsl:variable>

BEGIN:VEVENT
UID:<xsl:value-of select="$doi"/><!-- using the doi as a unique, unmutable id -->
SUMMARY:<xsl:value-of select="local:split-by-char($ics-summary)"/>
DESCRIPTION:<xsl:value-of select="local:split-by-char($ics-description)"/>
DTSTAMP:<xsl:value-of select="format-dateTime(current-dateTime(), $ics-date-picture)"/>
DTSTART:<xsl:value-of select="$start-time"/>
DTEND:<xsl:value-of select="$end-time"/>
TRANSP:TRANSPARENT
BEGIN:VALARM
TRIGGER:<xsl:value-of select="$trigger-period"/>
REPEAT:1
DURATION:PT15M
ACTION:DISPLAY
DESCRIPTION:<xsl:value-of select="local:split-by-char(concat('Reminder: ', $ics-summary))"/>
END:VALARM
END:VEVENT</xsl:template>

    <xsl:template match="cell"/>

    <!-- if embargo falls on a Monday, reminder needs to be earlier than 48 hours -->
    <xsl:function name="local:is-monday" as="xs:boolean">
        <xsl:param name="dateTime" as="xs:dateTime"/>
        <xsl:variable name="date" select="xs:date($dateTime)"/>
        <xsl:value-of select="functx:day-of-week($date) eq 1"/>
    </xsl:function>

    <xsl:function name="local:is-tuesday" as="xs:boolean">
        <xsl:param name="dateTime" as="xs:dateTime"/>
        <xsl:variable name="date" select="xs:date($dateTime)"/>
        <xsl:value-of select="functx:day-of-week($date) eq 2"/>
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
            <xsl:value-of select="concat(
                substring($string, . * $char + 1, $char), 
                if (position() ne last()) then '&#xd;&#xa;&#032;' else '')" 
            disable-output-escaping="yes"/>
        </xsl:for-each>
    </xsl:function>
</xsl:stylesheet>
