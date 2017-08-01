# XML to ICS converter

This XSLT script expects a certain XML format (see `test.xml`) and generates a file that follows the iCalendar standard. Only events for unique dates are generated as frequently embargoes seem to fall on the same day.

Test URL here: https://raw.githubusercontent.com/jfix/testtmp/master/test.ics

## Explanation of iCalendar fields

```
BEGIN:VEVENT
UID:d1e1066@embargoes.oecd.org
SUMMARY:Análisis de políticas fiscales de la OCD
 E: Costa Rica 2017 (es)

DESCRIPTION:"Análisis de políticas fiscales de la OC
 DE: Costa Rica 2017 (es) " and 95 other
 publications

DTSTAMP:20170801T092329Z
DTSTART:20170801T070000Z
DTEND:20170801T071500Z
TRANSP:TRANSPARENT
BEGIN:VALARM
TRIGGER:-PT48H
REPEAT:1
DURATION:PT15M
ACTION:DISPLAY
DESCRIPTION:Reminder: Análisis de políticas fiscales
  de la OCDE: Costa Rica 2017 (es)

END:VALARM
END:VEVENT
```

Each "calendar event" needs to start with a `BEGIN:VEVENT` and end with a `END:VEVENT`.
Each such event should (must?) have the following fields:
* `UID`: event identifier (should not change ideally)
* `SUMMARY`: equivalent of title in an Outlook event
* `DESCRIPTION`: equivalent of the main description field in an Outlook event
* `DTSTAMP`: when the event was created (not the date of the event, that is `DTSTART`)
* `DTSTART`: the start date/time of the event (note format)
* `DTEND`: the end date/time
* `TRANSP:TRANSPARENT`: in our case, the presence of an event should not "block" the time in a person's agenda

Inside the `VEVENT` we have a `VALARM` section that defines a reminder. Each such sections needs to start with a `BEGIN:VALARM` and end with an `END:VALARM`.

The other fields inside the `VEVENT` section that we're using are:
* `TRIGGER`: when to display reminder? Here we hard code it to 2 days before the event (may need to be more specific)
* `REPEAT`: just one reminder (not sure what else this could be)
* `DURATION`: ?
* `ACTION`: `DISPLAY`Show the reminder (I think it could also play a sound)
* `DESCRIPTION`: The reminder needs to have a descriptive field (usually the same as the `SUMMARY` in Outlook)

## Limitations

The iCalendar standard expects `CRLF` line endings, but XSLT seems to be 'clever' about this and only generates `CR`. I haven't found a solution for this yet.

## Sources of wisdom

* Help with the standard: https://icalendar.org/RFC-Specifications/iCalendar-RFC-5545/
* iCalendar validator: https://icalendar.org/validator.html
* backup validator (in case the other one is unavailable, yes, this has happened): http://severinghaus.org/projects/icv/
