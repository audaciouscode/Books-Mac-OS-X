#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""A custom importer for Books that scrapes ComicBookDB
<http://www.comicbookdb.com/> to download and quickfill comic book data.

VERSION HISTORY:

1.1 -- 2007-10-14 -- Changed editor field (custom) to editors (standard).
                     Now uses the thumbnail for the cover image when no
                     full-size image is present. Fixed an issue where Unicode
                     characters in the title would prevent the title from
                     being found. Now searches for non-numeric issue numbers
                     (e.g., Dark Tower: The Gunslinger Born Guidebook). If no
                     octothorp is present in the title, uses the last word
                     (for non-numeric issues; e.g., Guidebook, Sketchbook).
                     Updated version numbers to match Books version style.

0.4.1 -- 2007-10-13 -- Really removed empty issue details when a title does
                       not have an issue. Addressed an issue where titles
                       containing an ampersand would not be found.

                       Released as 1.0.

0.4 -- 2007-09-30 -- Now returns multiple covers when an issue has alternate
                     covers. Removed empty issue details when a title does not
                     have an issue. Now merges roles when multiple role
                     entries are found. Addressed yet another Unicode issue.
                     Added version to output.

0.3 -- 2007-09-21 -- First beta release. Now finds all matches. Adds proper
                     Unicode support. Most aspects of the program documented
                     and tested with doctests (to run, python -> import
                     comicBookDB -> comicBookDB.test())

0.2 -- 2007-09-18 -- First alpha release. Returns complete details for a single
                     issue.

0.1 -- 2007-09-16 -- First pre-alpha release. Only returns images (not issue
                     details).

LICENSE:

This work is licensed under the Creative Commons Attribution-Share Alike 3.0
Unported License. To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/3.0/ or send a letter to Creative
Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.

"""


__author__ = 'Jeff Cousens <books@aetherial.net>'
__version__ = '1.1'
__revision__ = '$LastChangedRevision$'
__date__ = '$LastChangedDate$'
__copyright__ = 'Copyright (c) 2007 Jeff Cousens'
__license__ = 'Creative Commons Attribution-Share Alike'


import re
import sys
import urllib
import urllib2
from xml.dom.minidom import Document, parse


INVALID = ['(Story is monochromatic)', '(Typeset)']


TITLE = re.compile(
        '<a href="title.php\?ID=(\d+)">([^(]+) \((\d+)\)</a> \(([^)]+)\)')
ISSUE = re.compile('<a href="issue.php\?ID=(\d+)">(\w+)</a><br>')
ALT_ISSUES = re.compile('<a\ href="issue.php\?ID=(\d+)">')
PUBLISHER = re.compile(
    '<a\ href="publisher.php\?ID=\d+">(?P<publisher>[^<]*)</a><br>')
IMAGES = re.compile(
    '<a\ href="(?P<cover>[^"]+)"\ target="_blank"><img\ src="(?P<thumb>[^"]+)"\ alt=""\ width="100"\ border="1"></a><br>')
THUMB = re.compile(
    '<img\ src="(?P<thumb>[^"]+)"\ alt=""\ width="100"\ border="1"><br>')
ROLES = re.compile(
    '<strong>(?P<role>[^<]+)\(s\):</strong><br>(?P<value>.*?)(?:<br><br>|<br>\ \ \ \ </td>)')
PUBDATE = re.compile(
    '<a\ href="coverdate.php\?month=\d+&amp;year=\d+">\ (?P<month>\w*)\ (?P<year>\d*)</a>')
PERSON = re.compile('<a href="\w+.php\?ID=\d+">([^<]+)</a>')


def add_field(doc, parent, name, value):
    """Adds a field element to parent.

    Uses doc to create a new "field" element with a name attribute with a
    value of name and a child text node with the contents of value and
    attaches it as a child of parent.
    """
    field = doc.createElement('field')
    field.setAttribute('name', name)
    try:
        text = doc.createTextNode(value.decode('utf-8'))
    except UnicodeDecodeError:
        text = doc.createTextNode(value.decode('iso-8859-1'))
    except AttributeError:
        text = doc.createTextNode(value)
    field.appendChild(text)
    parent.appendChild(field)


def get_issue_details(title_id, issue_number):
    """Searches the text of an issue's details to find the values to quickfill.

    Returns a Match Object.

        >>> match = get_issue_details(593, '100')
        >>> match[0]['publisher']
        'Marvel Comics'
        >>> match[0]['cover']
        'graphics/comic_graphics/1/56/4223_20060327032452_large.jpg'
        >>> match[0]['thumb']
        'graphics/comic_graphics/1/56/4223_20060327032452_thumb.jpg'
        >>> match[0]['writer']
        '<a href="creator.php?ID=249">Chris Claremont</a>'
        >>> match[0]['penciller']
        '<a href="creator.php?ID=1274">Leinil Francis Yu</a>'
        >>> match[0]['inker']
        '<a href="creator.php?ID=494">Mark Morales</a>'
        >>> match[0]['colorist']
        '<a href="creator.php?ID=1828">Liquid!</a>'
        >>> match[0]['letterer']
        '<a href="creator.php?ID=342">Comicraft</a><br><a href="creator.php?ID=74">Richard Starkings</a>'
        >>> match[0]['editors']
        '<a href="creator.php?ID=232">Robert Harras - \\'Bob\\'</a><br><a href="creator.php?ID=90">Mark Powers</a>'
        >>> match[0]['artist']
        '<a href="creator.php?ID=407">Arthur Adams - \\'Art\\'</a>'
        >>> match[0]['year']
        '2000'
        >>> match[0]['month']
        'May'
        >>> match = get_issue_details(84, '3')
        >>> match[0]['artist']
        '<a href="creator.php?ID=212">Sergio Aragon\\xe9s</a>'
        >>> 
    """
    issue_list = get_issue_id(title_id, issue_number)

    if not issue_list:
        return [{'issue_id': '0'}]

    match_list = []

    for issue_id in issue_list:
        issue_details = get_page(
                'http://www.comicbookdb.com/issue.php?ID=%s' % issue_id)

        match = {'issue_id': issue_id}
        mo = PUBLISHER.search(issue_details)
        if mo:
            mod = mo.groupdict()
            match['publisher'] = mod['publisher']
        mo = IMAGES.search(issue_details)
        if mo:
            mod = mo.groupdict()
            match['cover'] = mod['cover']
            match['thumb'] = mod['thumb']
        else:
            mo = THUMB.search(issue_details)
            if mo:
                mod = mo.groupdict()
                match['cover'] = mod['thumb']
                match['thumb'] = mod['thumb']
        matches = ROLES.findall(issue_details)
        for m in matches:
            # match looks like ('role', 'value')
            if m[0] == 'Cover Artist':
                if not match.has_key('artist'):
                    match['artist'] = m[1]
                else:
                    match['artist'] += m[1]
            elif m[0] == 'Editor':
                if not match.has_key('editors'):
                    match['editors'] = m[1]
                else:
                    match['editors'] += m[1]
            else:
                if not match.has_key(m[0].lower()):
                    match[m[0].lower()] = m[1]
                else:
                    match[m[0].lower()] += m[1]
        mo = PUBDATE.search(issue_details)
        if mo:
            mod = mo.groupdict()
            match['month'] = mod['month']
            match['year'] = mod['year']

        match_list.append(match)

    return match_list


def get_issue_id(title_id, issue_number):
    """Searches the list of issues for a title to find an issue's id.

        >>> get_issue_id(84, '3')
        ['15903']
        >>> get_issue_id(593, '100')
        ['4223', '75579', '75586', '75584', '75578', '75581', '75577', '75583', '75582']
        >>> 
    """
    issue_id = '0'

    issue_page = get_page(
            'http://www.comicbookdb.com/title.php?ID=%s' % title_id)

    matches = ISSUE.findall(issue_page)

    for match in matches:
        # match looks like ('issue_id', 'issue_number')
        if match[1] == issue_number:
            issue_id = match[0]
            break

    issue_list = [issue_id]

    alternate_covers = re.search(
        '<tbody id="issue_%s" style="display: none;">(.*?)</tbody>' % issue_id,
        issue_page,
        re.S)

    if alternate_covers:
        matches = ALT_ISSUES.findall(alternate_covers.groups()[0])
        issue_list += matches

    return issue_list


def get_page(url):
    """Wraps a urllib2 HTTP request.

    Returns the text content of the page.
    """
    req = urllib2.Request(url)
    resp = urllib2.urlopen(req)
    return resp.read()


def get_people(text):
    """Searches the text contained in a role block to extract the people and
    build a semi-colon separated list of names.

    get_people should be called with the groupdict values obtained by matching
    the issue page against the ROLES regexp.

        >>> writer = '<a href="creator.php?ID=249">Chris Claremont</a>'
        >>> penciller = '<a href="creator.php?ID=1274">Leinil Francis Yu</a>'
        >>> letterer = '<a href="creator.php?ID=342">Comicraft</a><br><a href="creator.php?ID=74">Richard Starkings</a>'
        >>> editors = '<a href="creator.php?ID=232">Robert Harras - \\'Bob\\'</a><br><a href="creator.php?ID=90">Mark Powers</a>'
        >>> get_people(writer)
        'Chris Claremont'
        >>> get_people(penciller)
        'Leinil Francis Yu'
        >>> get_people(letterer)
        'Comicraft; Richard Starkings'
        >>> get_people(editors)
        "Robert Harras - 'Bob'; Mark Powers"
        >>> 
    """
    people = ''
    matches = PERSON.findall(text)
    for match in matches:
        if match not in INVALID:
            people = '%s%s; ' % (people, match)
    return people.rstrip().rstrip(';')


def merge_people(plist):
    """Merges the results of get_people into a single list.

    This is needed for fields where multiple ComicBookDB fields relate to a
    single Books field.

    merge_people should be called with a list containing the return value of
    get_people.

        >>> writer = '<a href="creator.php?ID=249">Chris Claremont</a>'
        >>> penciller = '<a href="creator.php?ID=1274">Leinil Francis Yu</a>'
        >>> inker = '<a href="creator.php?ID=494">Mark Morales</a>'
        >>> letterer = '<a href="creator.php?ID=342">Comicraft</a><br><a href="creator.php?ID=74">Richard Starkings</a>'
        >>> editors = '<a href="creator.php?ID=232">Robert Harras - \\'Bob\\'</a><br><a href="creator.php?ID=90">Mark Powers</a>'
        >>> merge_people([get_people(writer)])
        'Chris Claremont'
        >>> merge_people([get_people(penciller), get_people(inker)])
        'Leinil Francis Yu; Mark Morales'
        >>> merge_people([get_people(writer), get_people(penciller),
        ...               get_people(inker)])
        'Chris Claremont; Leinil Francis Yu; Mark Morales'
        >>> merge_people([get_people(letterer), get_people(editors)])
        "Comicraft; Richard Starkings; Robert Harras - 'Bob'; Mark Powers"
        >>> 
    """
    merged = ''
    mlist = []
    for people in plist:
        for person in people.split('; '):
            if person not in mlist:
                merged = '%s%s; ' % (merged, person)
                mlist.append(person)
    return merged.rstrip().rstrip(';')


def parse_books_quickfill():
    """Parses the books-quickfill XML file to read values about the book to
    find.

    The title will be split on the octothorp (#) to find the title and issue
    number; e.g., "X-Men #100" will be split into a title of "X-Men" and an
    issue number of 100. A sample books-quickfill.xml file is:

        <Book>
          <field name="listName">My Books</field>
          <field name="publisher">This is the publisher</field>
          <field name="publishDate">1984-09-16</field>
          <field name="translators">This is the translator</field>
          <field name="illustrators">This is the ill ustrator</field>
          <field name="isbn">1234567890</field>
          <field name="editors">These are the editors</field>
          <field name="id">0A9EB127-B801-4B86-83D0-5DB895E2B4BF</field>
          <field name="series">This is the series</field>
          <field name="authors">This is the author</field>
          <field name="title">This is the title</field>
          <field name="summary">Summary goes here</field>
          <field name="genre">This is the genre</field>
        </Book>

    Currently this only searches for title and publisher.

        >>> MAD = '''<Book>
        ...   <field name="title">MAD #177</field>
        ... </Book>'''
        >>> GROO = '''<Book>
        ...   <field name="title">Groo the Wanderer #3</field>
        ...   <field name="publisher">Pacific Comics</field>
        ... </Book>'''
        >>> XMEN = '''<Book>
        ...   <field name="title">X-Men #100</field>
        ...   <field name="publisher">Marvel Comics</field>
        ... </Book>'''
        >>> GUIDE = '''<Book>
        ...   <field name="title">Dark Tower: The Gunslinger Born Guidebook</field>
        ...   <field name="publisher">Marvel Comics</field>
        ... </Book>'''
        >>> file = open('/tmp/books-quickfill.xml', 'w')
        >>> file.write(MAD)
        >>> file.close()
        >>> parse_books_quickfill()
        ('MAD', '177', '', True)
        >>> file = open('/tmp/books-quickfill.xml', 'w')
        >>> file.write(GROO)
        >>> file.close()
        >>> parse_books_quickfill()
        ('Groo the Wanderer', '3', 'Pacific Comics', True)
        >>> file = open('/tmp/books-quickfill.xml', 'w')
        >>> file.write(XMEN)
        >>> file.close()
        >>> parse_books_quickfill()
        ('X-Men', '100', 'Marvel Comics', True)
        >>> file = open('/tmp/books-quickfill.xml', 'w')
        >>> file.write(GUIDE)
        >>> file.close()
        >>> parse_books_quickfill()
        ('Dark Tower: The Gunslinger Born', 'Guidebook', 'Marvel Comics', False)
        >>> import os
        >>> os.unlink('/tmp/books-quickfill.xml')
        >>> 
    """
    title = ''
    issue_number = ''
    publisher = ''
    octothorp = True

    tree = parse('/tmp/books-quickfill.xml')
    fields = tree.getElementsByTagName('field')

    for field in fields:
        field.normalize()

        if field.firstChild != None:
            try:
                data = str(field.firstChild.data)
            except UnicodeEncodeError:
                data = field.firstChild.data
            if field.getAttribute('name') == 'title':
                if data.find('#') == -1:
                    # No issue number; use last word as "issue number"
                    title = data[:data.rfind(' ')]
                    issue_number = data[data.rfind(' '):].lstrip()
                    octothorp = False
                else:
                    # Issue number, split on octothorp
                    (title, issue_number) = data.split('#')
                    title = title.rstrip()
            elif field.getAttribute('name') == 'publisher':
                publisher = data
            # elif field.getAttribute('name') == 'publishDate':
            #     (year, month, day) = data.split('-')
    return (title, issue_number, publisher, octothorp)


def print_output(title='', title_ids=[], issue_number='', octothorp=True):
    """Walks a list of title IDs, gets issue details and prints a Books XML
    import file.

    Books plugins operate by parsing /tmp/books-quickfill.xml and printing
    Books import XML to stdout.

    If called with no arguments, will print an empty file.
    """
    doc = Document()
    root = doc.createElement('importedData')
    doc.appendChild (root)

    if (title_ids):
        collection = doc.createElement('List')
        collection.setAttribute('name', 'ComicBookDB Import')
        collection.setAttribute('version', __version__)
        root.appendChild(collection)

        for title_id in title_ids:

            matches = get_issue_details(title_id, issue_number)

            if matches[0]['issue_id'] == '0':
                continue

            for match in matches:

                book = doc.createElement('Book')
                book.setAttribute('title', title)

                if octothorp:
                    add_field(doc, book, 'title', '%s #%s' % (title, issue_number))
                else:
                    add_field(doc, book, 'title', '%s %s' % (title, issue_number))
                add_field(doc, book, 'series', title)
                if match.has_key('writer') and match['writer']:
                    add_field(doc, book, 'authors',
                              merge_people([get_people(match['writer'])]))
                if (match.has_key('penciller') and match['penciller'] and
                    match.has_key('inker') and match['inker']):
                    add_field(doc, book, 'illustrators',
                              merge_people([get_people(match['penciller']),
                                            get_people(match['inker'])]))
                elif match.has_key('penciller') and match['penciller']:
                    add_field(doc, book, 'illustrators',
                              merge_people([get_people(match['penciller'])]))
                elif match.has_key('inker') and match['inker']:
                    add_field(doc, book, 'illustrators',
                              merge_people([get_people(match['inker'])]))
                if match.has_key('editors') and match['editors']:
                    add_field(doc, book, 'editors',
                              merge_people([get_people(match['editors'])]))
                if match.has_key('publisher') and match['publisher']:
                    add_field(doc, book, 'publisher', match['publisher'])
                if (match.has_key('year') and match['year'] and
                    match.has_key('month') and match['month']):
                    add_field(doc, book, 'publishDate',
                              '%s 1, %s' % (match['month'], match['year']))
                elif match.has_key('year') and match['year']:
                    add_field(doc, book,
                              'publishDate', 'January 1, %s' % match['year'])
                if match.has_key('cover') and match['cover']:
                    add_field(doc, book, 'CoverImageURL',
                              'http://www.comicbookdb.com/%s' % match['cover'])
                add_field(doc, book, 'link',
                          'http://www.comicbookdb.com/issue.php?ID=%s' % (
                          match['issue_id']))

                collection.appendChild(book)

    print doc.toprettyxml(encoding='UTF-8', indent='  ').rstrip()

    sys.stdout.flush()


def query():
    """Queries ComicBookDB to get issue details.

    This doctest is broken :(  It needs to dynamically replace the version
    string.

        >>> GROO = '''<Book>
        ...   <field name="title">Groo the Wanderer #3</field>
        ...   <field name="publisher">Pacific Comics</field>
        ... </Book>'''
        >>> XMEN = '''<Book>
        ...   <field name="title">X-Men #188</field>
        ...   <field name="publisher">Marvel Comics</field>
        ... </Book>'''
        >>> CABLE = '''<Book>
        ...   <field name="title">Cable &amp; Deadpool #45</field>
        ...   <field name="publisher">Marvel Comics</field>
        ... </Book>'''
        >>> file = open('/tmp/books-quickfill.xml', 'w')
        >>> file.write(GROO)
        >>> file.close()
        >>> query()
        <?xml version="1.0" encoding="UTF-8"?>
        <importedData>
          <List name="ComicBookDB Import" version="1.1">
            <Book title="Groo the Wanderer">
              <field name="title">
                Groo the Wanderer #3
              </field>
              <field name="series">
                Groo the Wanderer
              </field>
              <field name="publisher">
                Pacific Comics
              </field>
              <field name="publishDate">
                April 1, 1983
              </field>
              <field name="CoverImageURL">
                http://www.comicbookdb.com/graphics/comic_graphics/1/24/15903_20051209094425_large.jpg
              </field>
              <field name="link">
                http://www.comicbookdb.com/issue.php?ID=15903
              </field>
            </Book>
            <Book title="Groo the Wanderer">
              <field name="title">
                Groo the Wanderer #3
              </field>
              <field name="series">
                Groo the Wanderer
              </field>
              <field name="authors">
                Mark Evanier
              </field>
              <field name="illustrators">
                Sergio Aragonés
              </field>
              <field name="publishDate">
                May 1, 1985
              </field>
              <field name="CoverImageURL">
                http://www.comicbookdb.com/graphics/comic_graphics/1/4/287_20050924142121_large.jpg
              </field>
              <field name="link">
                http://www.comicbookdb.com/issue.php?ID=287
              </field>
            </Book>
          </List>
        </importedData>
        >>> file = open('/tmp/books-quickfill.xml', 'w')
        >>> file.write(XMEN)
        >>> file.close()
        >>> query()
        <?xml version="1.0" encoding="UTF-8"?>
        <importedData>
          <List name="ComicBookDB Import" version="1.1">
            <Book title="X-Men">
              <field name="title">
                X-Men #188
              </field>
              <field name="series">
                X-Men
              </field>
              <field name="authors">
                Mike Carey
              </field>
              <field name="illustrators">
                Chris Bachalo; Jaime Mendoza; Tim Townsend
              </field>
              <field name="editors">
                Mike Marts
              </field>
              <field name="publisher">
                Marvel Comics
              </field>
              <field name="publishDate">
                September 1, 2006
              </field>
              <field name="CoverImageURL">
                http://www.comicbookdb.com/graphics/comic_graphics/1/95/51001_20060713214406_large.jpg
              </field>
              <field name="link">
                http://www.comicbookdb.com/issue.php?ID=51001
              </field>
            </Book>
            <Book title="X-Men">
              <field name="title">
                X-Men #188
              </field>
              <field name="series">
                X-Men
              </field>
              <field name="authors">
                Mike Carey
              </field>
              <field name="illustrators">
                Chris Bachalo; Jaime Mendoza; Tim Townsend
              </field>
              <field name="editors">
                Mike Marts
              </field>
              <field name="publisher">
                Marvel Comics
              </field>
              <field name="publishDate">
                September 1, 2006
              </field>
              <field name="CoverImageURL">
                http://www.comicbookdb.com/graphics/comic_graphics/1/154/77478_20061231044347_large.jpg
              </field>
              <field name="link">
                http://www.comicbookdb.com/issue.php?ID=77478
              </field>
            </Book>
          </List>
        </importedData>
        >>> file = open('/tmp/books-quickfill.xml', 'w')
        >>> file.write(CABLE)
        >>> file.close()
        >>> query()
        <?xml version="1.0" encoding="UTF-8"?>
        <importedData>
          <List name="ComicBookDB Import" version="1.1">
            <Book title="Cable &amp; Deadpool">
              <field name="title">
                Cable &amp; Deadpool #45
              </field>
              <field name="series">
                Cable &amp; Deadpool
              </field>
              <field name="authors">
                Fabian Nicieza
              </field>
              <field name="illustrators">
                Reilly Brown; Jeremy Freeman
              </field>
              <field name="editors">
                Nicole Boose
              </field>
              <field name="publisher">
                Marvel Comics
              </field>
              <field name="publishDate">
                November 1, 2007
              </field>
              <field name="CoverImageURL">
                http://www.comicbookdb.com/graphics/comic_graphics/1/213/106331_20070929112004_large.jpg
              </field>
              <field name="link">
                http://www.comicbookdb.com/issue.php?ID=106331
              </field>
            </Book>
          </List>
        </importedData>
        >>> 
    """
    title_ids = []

    (title, issue_number, publisher, octothorp) = parse_books_quickfill()

    title_list = get_page('http://www.comicbookdb.com/search.php?'
            'form_search=%s&form_searchtype=Title' % urllib.quote(title))

    title_list = title_list.replace('&amp;', '&')

    matches = TITLE.findall(title_list)

    for match in matches:
        # match looks like ('title_id', 'title', 'year', 'publisher')
        t = match[1]
        try:
            t = t.decode('utf-8')
        except UnicodeDecodeError:
            t = t.decode('iso-8859-1')
        if t == title:
            title_ids.append(match[0])

    if not title_ids:
        print_output()
    else:
        print_output(title, title_ids, issue_number, octothorp)


def test():
    """Executes doctests for comicBookDB module.
    """
    import doctest
    doctest.testmod()


if __name__ == '__main__':
    query()

