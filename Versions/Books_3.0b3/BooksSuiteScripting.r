#include <Carbon/Carbon.r>

#define Reserved8   reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved
#define Reserved12  Reserved8, reserved, reserved, reserved, reserved
#define Reserved13  Reserved12, reserved
#define dp_none__   noParams, "", directParamOptional, singleItem, notEnumerated, Reserved13
#define reply_none__   noReply, "", replyOptional, singleItem, notEnumerated, Reserved13
#define synonym_verb__ reply_none__, dp_none__, { }
#define plural__    "", {"", kAESpecialClassProperties, cType, "", reserved, singleItem, notEnumerated, readOnly, Reserved8, noApostrophe, notFeminine, notMasculine, plural}, {}

resource 'aete' (0, "Books Terminology") {
	0x1,  // major version
	0x0,  // minor version
	english,
	roman,
	{
		"Books Suite",
		"The event suite specific to Books",
		'book',
		1,
		1,
		{
			/* Events */

		},
		{
			/* Classes */

			"application", 'capp',
			"The application program",
			{
				"<Inheritance>", pInherits, '****',
				"inherits elements and properties of the item class.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"apptest", 'ApTs', 'TEXT',
				"",
				reserved, singleItem, notEnumerated, readWrite, Reserved12
			},
			{
			},
			"applications", 'capp', plural__
		},
		{
			/* Comparisons */
		},
		{
			/* Enumerations */
		}
	}
};
