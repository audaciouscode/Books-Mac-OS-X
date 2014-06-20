//
//  Search.m
//  AmazonSearch
//
//  Created by Chris Karr on 2/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Search.h"
#import "NSDataAdditions.h"

#define ASSOCIATES_KEY @"1W087CHNYGBWE51SK6R2"
#define ASSOCIATES_TAG @"aetherialnu0-20"
#define ASSOCIATES_SECRET @"F291jPIc8tHSQdtM8lq995iPfG3zuGOIOetX9Rwr"

#define SHA256_DIGEST_SIZE 32

@implementation Search

// Fetched from http://infinite-sushi.com/2009/08/minimal-amazon-api-authentication-with-cocoa/

+ (NSString *) signedString:(NSString*) strToSign 
{
	unsigned char * strBytes = (unsigned char *) [strToSign UTF8String];
	
	unsigned char hmac_buffer[SHA256_DIGEST_SIZE];
	bzero(hmac_buffer, SHA256_DIGEST_SIZE);
	
	unsigned char * keyBytes = (unsigned char *) [ASSOCIATES_SECRET UTF8String];
	hmac_sha256(keyBytes, [ASSOCIATES_SECRET length], strBytes, [strToSign length], hmac_buffer, SHA256_DIGEST_SIZE);
	NSData * signedData = [NSData dataWithBytes:hmac_buffer length:SHA256_DIGEST_SIZE];
	
	NSString * base = [signedData base64EncodingWithLineLength:0];
	// escape plus and equal characters since this will be in a URL
	NSMutableString * str = [NSMutableString stringWithString:base];
	[str replaceOccurrencesOfString:@"+"
						 withString:@"%2B"
							options:0
							  range:NSMakeRange(0,[str length])];
	
	[str replaceOccurrencesOfString:@"="
						 withString:@"%3D"
							options:0
							  range:NSMakeRange(0,[str length])];
	return str;
}

+ (NSArray *) descendantsForName:(NSString *) name element:(NSXMLElement *) element
{
	NSMutableArray * ds = [NSMutableArray array];

	NSArray * children = [element elementsForName:name];
	
	if ([children count] > 0)
		[ds addObjectsFromArray:children];
	else
	{
		children = [element children];
		NSEnumerator * iter = [children objectEnumerator];
		NSXMLNode * node = nil;
		
		while (node = [iter nextObject])
		{
			if ([node kind] ==  NSXMLElementKind)
				[ds addObjectsFromArray:[Search descendantsForName:name element:(NSXMLElement *) node]];
		}
	}
	
	return ds;
}

+ (void) searchForXml:(NSString *) xml locale:(NSString *) locale
{
	if (locale == nil)
		locale = @"us";
	
	NSMutableDictionary * parameters = [NSMutableDictionary dictionary];

	[parameters setValue:@"AWSECommerceService" forKey:@"Service"];
	[parameters setValue:@"Large" forKey:@"ResponseGroup"];
	[parameters setValue:ASSOCIATES_KEY forKey:@"AWSAccessKeyId"];
	[parameters setValue:ASSOCIATES_TAG forKey:@"t"];
	
	NSCalendarDate * newDate = [NSCalendarDate calendarDate];
	newDate = [newDate addTimeInterval:(0 - [[NSTimeZone localTimeZone] secondsFromGMT])];
	NSString * timestamp = [newDate	descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ" timeZone:nil locale:nil];
	
	[parameters setValue:timestamp forKey:@"Timestamp"];
	
	NSDictionary * endpoints = [NSDictionary dictionaryWithObjectsAndKeys:
								@"ecs.amazonaws.ca", @"ca", 
								@"ecs.amazonaws.de", @"de", 
								@"ecs.amazonaws.fr", @"fr", 
								@"ecs.amazonaws.jp", @"jp", 
								@"ecs.amazonaws.co.uk", @"uk", 
								@"webservices.amazon.com", @"us", nil];
								
	NSMutableDictionary * book = [NSMutableDictionary dictionary];
	
	NSXMLDocument * doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[xml stringByExpandingTildeInPath]] 
															   options:NSXMLDocumentTidyXML error:nil];
	
	NSXMLElement * root = [doc rootElement];
	
	NSEnumerator * e = [[root elementsForName:@"field"] objectEnumerator];
	NSXMLElement * field = nil;
	
	while (field = [e nextObject])
	{
		NSString * name = [[field attributeForName:@"name"] stringValue];
		NSString * value = [field stringValue];
		
		if (name != nil && value != nil)
			[book setValue:value forKey:name];
	}
	
	NSString * isbn = [book valueForKey:@"isbn"];
	
	if (isbn != nil && ![isbn isEqual:@""])
	{
		NSMutableString * newIsbn = [NSMutableString stringWithString:isbn];
		
		[newIsbn replaceOccurrencesOfString:@"-" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newIsbn length])];
		[newIsbn replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newIsbn length])];
		
		[parameters setValue:@"ItemLookup" forKey:@"Operation"];
		[parameters setValue:@"ASIN" forKey:@"IdType"];
		[parameters setValue:newIsbn forKey:@"ItemId"];
	}
	else
	{
		NSMutableString * power = [NSMutableString stringWithFormat:@"title:\"%@\"", [book valueForKey:@"title"]];

		NSString * authors = [book valueForKey:@"authors"];
		
		if (authors != nil && ![authors isEqual:@""])
			[power appendFormat:@" and author:\"%@\"", authors, nil];

		[parameters setValue:@"ItemSearch" forKey:@"Operation"];
		[parameters setValue:@"Books" forKey:@"SearchIndex"];
		[parameters setValue:power forKey:@"Power"];
	}
	
	NSMutableString * canonical = [NSMutableString string];
	
	NSEnumerator * keys = [[[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
	NSString * key = nil;
	while (key = [keys nextObject])
	{
		if ([canonical length] > 0)
			[canonical appendString:@"&"];

		[canonical appendFormat:@"%@=%@", key, [parameters valueForKey:key]];
	}
	
	NSString *escStr = (NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) canonical, NULL, 
																			(CFStringRef) @"+\"',:", kCFStringEncodingUTF8);

	NSString * toSign = [NSString stringWithFormat:@"GET\n%@\n/onca/xml\n%@", [endpoints valueForKey:locale], escStr];
	
	NSMutableArray * books = [NSMutableArray array];

	NSString * amazonString = [NSString stringWithFormat:@"http://%@/onca/xml?%@&Signature=%@",
							   [endpoints valueForKey:locale],
							   escStr,
							   [Search signedString:toSign]];
	
	NSLog (@"<!-- %@ -->", amazonString);
	
	NSXMLDocument * search = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:amazonString] 
																  options:NSXMLDocumentTidyXML 
																	error:nil];

	NSXMLElement * response = [search rootElement];
	NSXMLElement * items = [[response elementsForName:@"Items"] lastObject];

	NSArray * ignore = [NSArray arrayWithObjects:@"NumberOfItems", @"PackageDimensions", @"ProductGroup", @"Label", @"Studio", @"Manufacturer", nil];
	
	if (items != nil)
	{
		NSArray * itemList = [items elementsForName:@"Item"];
	
		NSEnumerator * itemIter = [itemList objectEnumerator];
		NSXMLElement * itemElement = nil;
		
		while (itemElement = [itemIter nextObject])
		{
			NSMutableDictionary * book = [NSMutableDictionary dictionary];
		
			// Get cover image
			
			NSMutableArray * imageElements = [NSMutableArray array];
			[imageElements addObjectsFromArray:[Search descendantsForName:@"LargeImage" element:itemElement]];
			[imageElements addObjectsFromArray:[Search descendantsForName:@"MediumImage" element:itemElement]];
			[imageElements addObjectsFromArray:[Search descendantsForName:@"SmallImage" element:itemElement]];

			if ([imageElements count] > 0)
			{
				NSXMLElement * imageElement = [[[imageElements objectAtIndex:0] elementsForName:@"URL"] lastObject];
				
				[book setValue:[imageElement stringValue] forKey:@"CoverImageURL"];
			}
			
			// Get the rest

			NSMutableString * authors = [NSMutableString string];
			NSMutableString * illustrators = [NSMutableString string];
			
			NSArray * atts = [Search descendantsForName:@"ItemAttributes" element:itemElement];
			
			NSEnumerator * attIter = [[[atts lastObject] children] objectEnumerator];
			NSXMLElement * element = nil;
			while (element = [attIter nextObject])
			{
				if ([ignore containsObject:[element name]])
				{
				
				}
				else if ([[element name] isEqual:@"Title"])
					[book setValue:[element stringValue] forKey:@"title"];
				else if ([[element name] isEqual:@"Binding"])
					[book setValue:[element stringValue] forKey:@"format"];
				else if ([[element name] isEqual:@"Publisher"])
					[book setValue:[element stringValue] forKey:@"publisher"];
				else if ([[element name] isEqual:@"NumberOfPages"])
					[book setValue:[element stringValue] forKey:@"length"];
				else if ([[element name] isEqual:@"ISBN"])
					[book setValue:[element stringValue] forKey:@"isbn"];
				else if ([[element name] isEqual:@"PublicationDate"])
					[book setValue:[element stringValue] forKey:@"publishDate"];
				else if ([[element name] isEqual:@"Edition"])
					[book setValue:[element stringValue] forKey:@"edition"];
				else if ([[element name] isEqual:@"EAN"])
					[book setValue:[element stringValue] forKey:@"isbn13"];
				else if ([[element name] isEqual:@"DeweyDecimalNumber"])
					[book setValue:[element stringValue] forKey:@"Dewey Decimal"];
				else if ([[element name] isEqual:@"Author"])
				{
					if ([authors length] > 0)
						[authors appendString:@";"];

					[authors appendString:[element stringValue]];
				}
				else if ([[element name] isEqual:@"Creator"])
				{
					if ([[[element attributeForName:@"Role"] stringValue] isEqual:@"Illustrator"])
					{
						if ([illustrators length] > 0)
							[illustrators appendString:@";"];

						[illustrators appendString:[element stringValue]];
					}
				}
				else if ([[element name] isEqual:@"ListPrice"])
				{
					NSMutableString * price = [NSMutableString string];
					
					NSString * formattedPrice = [[[element elementsForName:@"FormattedPrice"] lastObject] stringValue];
					
					if (formattedPrice != nil)
					{
						[price appendString:formattedPrice];
					
						NSString * currency = [[[element elementsForName:@"CurrencyCode"] lastObject] stringValue];
						
						if (currency != nil)
						{
							[price appendString:@" "];
							[price appendString:currency];
						}

						[book setValue:price forKey:NSLocalizedString (@"List Price", nil)];
					}
				}
				else
					[book setValue:[element stringValue] forKey:[element name]];
			}

			atts = [Search descendantsForName:@"EditorialReviews" element:itemElement];
			
			if ([atts count] > 0)
			{
				element = [[[atts objectAtIndex:0] children] objectAtIndex:0];
				if (element != nil)
				{
					NSMutableString * description = [NSMutableString stringWithString:@""];
					[description appendFormat:@"%@: %@", [[[element children] objectAtIndex:0] stringValue], [[[element children] objectAtIndex:1] stringValue]];
					[book setValue:description forKey:@"summary"];
				}
			}

			atts = [Search descendantsForName:@"LowestNewPrice" element:itemElement];
			if ([atts count] > 0)
			{
				element = [atts lastObject];
				
				NSMutableString * price = [NSMutableString string];
					
				NSString * formattedPrice = [[[element elementsForName:@"FormattedPrice"] lastObject] stringValue];
					
				if (formattedPrice != nil)
				{
					[price appendString:formattedPrice];
					
					NSString * currency = [[[element elementsForName:@"CurrencyCode"] lastObject] stringValue];
						
					if (currency != nil)
					{
						[price appendString:@" "];
						[price appendString:currency];
					}

					[book setValue:price forKey:NSLocalizedString (@"Current Value", nil)];
				}
			}
			
			NSMutableString * keywords = [NSMutableString string];
			
			atts = [Search descendantsForName:@"BrowseNodes" element:itemElement];
			if ([atts count] > 0)
			{
				attIter = [[[atts lastObject] children] objectEnumerator];
				element = nil;
				while (element = [attIter nextObject])
				{
					NSXMLElement * name = [[element elementsForName:@"Name"] lastObject];
				
					if ([keywords length] > 0)
						[keywords appendString:@";"];
				
					[keywords appendString:[name stringValue]];
				}
				
				if ([keywords length] > 0)
					[book setValue:keywords forKey:@"keywords"];
			}
			
			atts = [Search descendantsForName:@"DetailPageURL" element:itemElement];
			
			if ([atts count] > 0)
				[book setValue:[[[atts lastObject] stringValue] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
						forKey:NSLocalizedString (@"URL", nil)];
			
			if ([authors length] > 0)
				[book setValue:authors forKey:@"authors"];
			if ([illustrators length] > 0)
				[book setValue:illustrators forKey:@"illustrators"];
			
			NSString * summary = [book valueForKey:@"summary"];
			if (summary == nil)
				summary = @"";
			
			summary = [NSString stringWithFormat:@"%@<br /><br /><a href=\"%@\">Amazon</a>", summary, [book valueForKey:NSLocalizedString (@"URL", nil)]];
			[book setValue:summary forKey:@"summary"];
	
			[books addObject:book];
		}
	}
	
	
	
	// print out books
	
	NSXMLDocument * found = [[NSXMLDocument alloc] initWithXMLString:
								@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><importedData><List name=\"Amazon Import\" /></importedData>"
								 options:NSXMLDocumentTidyXML error:nil];
								 
	NSXMLElement * foundList = (NSXMLElement *) [[found rootElement] childAtIndex:0];
	
	NSEnumerator * bookIter = [books objectEnumerator];
	NSDictionary * dict = nil;
	while (dict = [bookIter nextObject])
	{
		NSXMLElement * bookElement = [[NSXMLElement alloc] initWithName:@"Book"];
		
		NSEnumerator * keyIter = [[dict allKeys] objectEnumerator];
		NSString * key = nil;
		while (key = [keyIter nextObject])
		{
			NSXMLElement * field = [[NSXMLElement alloc] initWithName:@"field"];
			
			[field addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:key]];
			
			[field setStringValue:[dict valueForKey:key]];
			
			[bookElement addChild:field];
		}
		
		[foundList addChild:bookElement];
	}
	
	fprintf (stdout, [[found XMLStringWithOptions:(NSXMLNodeCompactEmptyElement | NSXMLNodePrettyPrint)] cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
