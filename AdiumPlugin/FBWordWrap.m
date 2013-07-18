//
//  FBWordWrap.m
//  InGameOverlay
//
//  Created by Florian Bethke on 08.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import "FBWordWrap.h"


@implementation FBWordWrap

/*	word-wraps the text "inString" with the attributes "stringAttrib" to a new string
	with the maximum line length "maxLength" in pixels */

+ (NSString *)wordWrap:(NSString *)inString attributes:(NSDictionary *)stringAttrib withLineLength:(float)maxLength
{	
	NSArray *lines = [inString componentsSeparatedByString:@"\n"];
	
	NSMutableString *newString = [[NSMutableString alloc] init];
	
	for(unsigned int j=0;j<[lines count];j++){
		NSArray *words = [[lines objectAtIndex:j] componentsSeparatedByString:@" "];
		float length = 0;

		for(unsigned int i=0;i<[words count];i++){
			NSString *word = [words objectAtIndex:i];
			float wordlength = [word sizeWithAttributes:stringAttrib].width;
			length += wordlength;
			if(length > maxLength){
				[newString appendString:@"\n"];
				length = wordlength;
			}
			[newString appendString:word];
			[newString appendString:@" "];
		}
		if(j<[lines count]-1)
			[newString appendString:@"\n"];
	}
	
	NSString *string = [NSString stringWithString:newString];
	[newString release];
	
	return string;
}

@end
