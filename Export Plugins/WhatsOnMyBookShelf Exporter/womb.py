#!/usr/bin/python

import sys
from SOAPpy import SOAPProxy

user = sys.argv[1]
password = sys.argv[2]

url = 'http://whatsonmybookshelf.com/api/index.php'
namespace = 'urn:womb'  
server = SOAPProxy(url, namespace)      
server.encoding = 'US-ASCII'
auth_result = server.authUser(user, password)

if (auth_result.sessionID == ""):
	sys.exit (-1)
	
file = open("/tmp/books-export/womb.txt")

error_string = ""

for line in file.readlines():
	if (line != ""):
		fields = line.split ("\t")

		isbn = fields[0].split(" ")[0].strip ()
		tags = fields[1].strip ()
		comment = fields[2].strip ()

		if (comment == None or comment == ""):
			comment = "Uploaded by Books. (http://books.aetherial.net/)"

		print (isbn)

		result = server.registerBookByISBN (auth_result['sessionID'], isbn, tags, comment)

		if (result.errorText != ""):
			error_string = error_string + isbn + ": " + result.errorText + "\n"

f = open ("/tmp/books-export/womb.error", "w")
f.write (error_string)
f.close ()

sys.exit (0)
