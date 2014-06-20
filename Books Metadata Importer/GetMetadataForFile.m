#import <Foundation/Foundation.h>

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile (void * thisInterface, CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
	NSLog (@"Books Spotlight MD Importer %@", pathToFile);

	NSString * error = nil;
	 
	NSData * data = [NSData dataWithContentsOfFile:(NSString *) pathToFile];

	NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;

	NSDictionary * metadata = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable 
									format:&format errorDescription:&error];
    
	if (metadata != nil) 
	{
		[(NSMutableDictionary *)attributes addEntriesFromDictionary:metadata];
		
		NSString * authors = [metadata valueForKey:@"authors"];
		if (authors != nil)
			[(NSMutableDictionary *)attributes setValue:[authors componentsSeparatedByString:@","] forKey:(NSString *) kMDItemAuthors];
			
		NSString * publishPlace = [metadata valueForKey:@"publishPlace"];
		if (publishPlace != nil)
			[(NSMutableDictionary *)attributes setValue:publishPlace forKey:(NSString *) kMDItemCity];

		NSString * publisher = [metadata valueForKey:@"publisher"];
		if (publisher != nil)
			[(NSMutableDictionary *)attributes setValue:[NSArray arrayWithObject:publisher] forKey:(NSString *) kMDItemPublishers];

		NSString * title = [metadata valueForKey:@"title"];
		if (title != nil)
		{
			[(NSMutableDictionary *)attributes setValue:title forKey:(NSString *) kMDItemDisplayName];
			[(NSMutableDictionary *)attributes setValue:title forKey:(NSString *) kMDItemTitle];
		}
		
		[(NSMutableDictionary *)attributes setValue:@"Books" forKey:(NSString *) kMDItemCreator];
		
		return TRUE;
	}
	
	NSLog (@"Error importing Books metadata: %@", error);
	
    return FALSE;
}
