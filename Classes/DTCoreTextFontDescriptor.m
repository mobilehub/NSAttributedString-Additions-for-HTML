//
//  DTCoreTextFontDescriptor.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/26/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFontDescriptor.h"

static NSCache *_fontCache = nil;

@implementation DTCoreTextFontDescriptor



+ (NSCache *)fontCache
{
	if (!_fontCache)
	{
		_fontCache = [[NSCache alloc] init];
	}
	
	return _fontCache;
}

+ (DTCoreTextFontDescriptor *)fontDescriptorWithFontAttributes:(NSDictionary *)attributes
{
	return [[[DTCoreTextFontDescriptor alloc] initWithFontAttributes:attributes] autorelease];
}

+ (DTCoreTextFontDescriptor *)fontDescriptorForCTFont:(CTFontRef)ctFont
{
	return [[[DTCoreTextFontDescriptor alloc] initWithCTFont:ctFont] autorelease];
}

- (id)initWithFontAttributes:(NSDictionary *)attributes
{
    self = [super init];
	if (self)
	{
		[self setFontAttributes:attributes];
	}
	
	return self;
}

- (id)initWithCTFontDescriptor:(CTFontDescriptorRef)ctFontDescriptor
{
	self = [super init];
	if (self)
	{
        CFDictionaryRef dict = CTFontDescriptorCopyAttributes(ctFontDescriptor);
        
        CFDictionaryRef traitsDict = CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontTraitsAttribute);
        CTFontSymbolicTraits traitsValue = [[(NSDictionary *)traitsDict objectForKey:(id)kCTFontSymbolicTrait] unsignedIntValue];
        
        self.symbolicTraits = traitsValue;
        
        [self setFontAttributes:(id)dict];
		
        CFRelease(dict);
        CFRelease(traitsDict);
		
		// also get family name
		
		CFStringRef familyName = CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontFamilyNameAttribute);
		self.fontFamily = (id)familyName;
		CFRelease(familyName);
	}
	
	return self;
}

- (id)initWithCTFont:(CTFontRef)ctFont
{
    self = [super init];
    if (self)
    {
        CTFontDescriptorRef fd = CTFontCopyFontDescriptor(ctFont);
        CFDictionaryRef dict = CTFontDescriptorCopyAttributes(fd);
        
        CFDictionaryRef traitsDict = CTFontDescriptorCopyAttribute(fd, kCTFontTraitsAttribute);
        CTFontSymbolicTraits traitsValue = [[(NSDictionary *)traitsDict objectForKey:(id)kCTFontSymbolicTrait] unsignedIntValue];
        
        self.symbolicTraits = traitsValue;
        
        [self setFontAttributes:(id)dict];
        
        CFRelease(dict);
        CFRelease(traitsDict);
        CFRelease(fd);
    }
    
    return self;
}


- (void)dealloc
{
	[fontFamily release];
	[fontName release];
	
	[super dealloc];
}

- (NSString *)description
{
	NSMutableString *string = [NSMutableString string];
	
	[string appendFormat:@"<%@ ", [self class]];
	
	
	if (fontName)
	{
		[string appendFormat:@"name:\'%@\' ", fontName];
	}
	
	if (fontFamily)
	{
		[string appendFormat:@"family:\'%@\' ", fontFamily];
	}
	
	NSMutableArray *tmpTraits = [NSMutableArray array];
	
	if (boldTrait)
	{
		[tmpTraits addObject:@"bold"];
	}
	
	if (italicTrait)
	{
		[tmpTraits addObject:@"italic"];
	}

	if (monospaceTrait)
	{
		[tmpTraits addObject:@"monospace"];
	}

	if (condensedTrait)
	{
		[tmpTraits addObject:@"condensed"];
	}

	if (expandedTrait)
	{
		[tmpTraits addObject:@"expanded"];
	}
	
	if (verticalTrait)
	{
		[tmpTraits addObject:@"vertical"];
	}

	if (UIoptimizedTrait)
	{
		[tmpTraits addObject:@"UI optimized"];
	}


	if ([tmpTraits count])
	{
		[string appendString:@"attributes:"];
		[string appendString:[tmpTraits componentsJoinedByString:@", "]];
	}
	
	
	[string appendString:@">"];

	return string;
}

- (CTFontSymbolicTraits)symbolicTraits
{
	CTFontSymbolicTraits retValue = 0;
	
	
	if (boldTrait)
	{
		retValue |= kCTFontBoldTrait;
	}
	
	if (italicTrait)
	{
		retValue |= kCTFontItalicTrait;
	}
	
	if (expandedTrait)
	{
		retValue |= kCTFontExpandedTrait;
	}
	
	if (condensedTrait)
	{
		retValue |= kCTFontCondensedTrait;
	}
	
	if (monospaceTrait)
	{
		retValue |= kCTFontMonoSpaceTrait;
	}
	
	if (verticalTrait)
	{
		retValue |= kCTFontVerticalTrait;
	}
	
	if (UIoptimizedTrait)
	{
		retValue |= kCTFontUIOptimizedTrait;
	}
	
	// bundle in class
	retValue |= stylisticClass;
	
	return retValue;
}

- (NSDictionary *)fontAttributes
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *traitsDict = [NSMutableDictionary dictionary];
	
	CTFontSymbolicTraits symbolicTraits = [self symbolicTraits];
	
	if (symbolicTraits)
	{
		[traitsDict setObject:[NSNumber numberWithUnsignedInt:symbolicTraits] forKey:(id)kCTFontSymbolicTrait];
	}
	
	if ([traitsDict count])
	{
		[tmpDict setObject:traitsDict forKey:(id)kCTFontTraitsAttribute];
	}
	
	if (fontFamily)
	{
		[tmpDict setObject:fontFamily forKey:(id)kCTFontFamilyNameAttribute];
	}
	
	if (fontName)
	{
		[tmpDict setObject:fontName forKey:(id)kCTFontNameAttribute];
	}
	
	[tmpDict setObject:[NSNumber numberWithFloat:pointSize] forKey:(id)kCTFontSizeAttribute];
	
	//return [NSDictionary dictionaryWithDictionary:tmpDict];
    
    // converting to non-mutable costs 42% of entire method
    return tmpDict;
}

#pragma mark Finding Font

- (CTFontRef)newMatchingFont
{
	NSCache *fontCache = [DTCoreTextFontDescriptor fontCache];
	NSNumber *cacheKey = [NSNumber numberWithInteger:[self hash]];
	
	CTFontRef cachedFont = (CTFontRef)[fontCache objectForKey:cacheKey];
	
	if (cachedFont)
	{
		CFRetain(cachedFont);
		return cachedFont;
	}
	
	// we have a a name already
	if (fontName)
	{
		CTFontRef font = CTFontCreateWithName((CFStringRef)fontName, pointSize, NULL);
		
		// cache it
		[fontCache setObject:(id)font forKey:cacheKey];
		
		return font;
	}
	
//	// try cached font match
//	DTCoreTextFontCollection *availableFonts = [DTCoreTextFontCollection availableFontsCollection];
//	DTCoreTextFontDescriptor *matching = [availableFonts matchingFontDescriptorForFontDescriptor:self];
//	
//	if (matching)
//	{
//		return [matching newMatchingFont];
//	}
	
	
    NSDictionary *attributes = [self fontAttributes];
    
    CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)attributes);
    
    CTFontRef matchingFont;
    
    if (fontFamily)
    {
        // fast font creation
        matchingFont = CTFontCreateWithFontDescriptor(fontDesc, pointSize, NULL);
    }
    else
    {
        // without font name or family we need to do expensive search
        // otherwise we always get Helvetica
        
        NSSet *set;
        
        if (fontFamily)
        {
            set = [NSSet setWithObjects:(id)kCTFontTraitsAttribute, (id)kCTFontFamilyNameAttribute, nil];
        }
        else 
        {
            set = [NSSet setWithObjects:(id)kCTFontTraitsAttribute, nil];
        }
        
        CTFontDescriptorRef matchingDesc = CTFontDescriptorCreateMatchingFontDescriptor(fontDesc, (CFSetRef)set);
        
        if (matchingDesc)
        {
            matchingFont = CTFontCreateWithFontDescriptor(matchingDesc, pointSize, NULL);
            CFRelease(matchingDesc);
        }
        else 
        {
            NSLog(@"No matches for %@", (id)fontDesc);
            matchingFont = nil;
        }
    }
    
    CFRelease(fontDesc);
	
	if (matchingFont)
	{
		// cache it
		[fontCache setObject:(id)matchingFont forKey:cacheKey];	
	}

    return matchingFont;
}

- (void)normalizeSlow
{
    NSLog(@"looking for %@", [self fontAttributes]);
    
    NSDictionary *attributes = [self fontAttributes];
    
    CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)attributes);
    
    if (fontDesc)
    {
        NSSet *set;
        
        if (self.fontFamily)
        {
            set = [NSSet setWithObjects:(id)kCTFontTraitsAttribute, (id)kCTFontFamilyNameAttribute, nil];
        }
        else 
        {
            set = [NSSet setWithObjects:(id)kCTFontTraitsAttribute, nil];
        }
        
        CTFontDescriptorRef matchingDesc = CTFontDescriptorCreateMatchingFontDescriptor(fontDesc, (CFSetRef)set);
        
        if (matchingDesc)
        {
            //		CFArrayRef matches = CTFontDescriptorCreateMatchingFontDescriptors(fontDesc, (CFSetRef)set);
            //		
            //		if (matches)
            //		{
            //			if (CFArrayGetCount(matches))
            //			{
            //				CTFontDescriptorRef matchingDesc = CFArrayGetValueAtIndex(matches, 0);
            
            CFDictionaryRef attributes = CTFontDescriptorCopyAttributes(matchingDesc);
            
            NSLog(@"found %@", attributes);
            
            CFStringRef family = CTFontDescriptorCopyAttribute(matchingDesc, kCTFontFamilyNameAttribute);
            if (family)
            {
                self.fontFamily = (id)family;
                CFRelease(family);
            }
            
            if (attributes)
            {
                [self setFontAttributes:(id)attributes];
                CFRelease(attributes);
            }
            //			}
            //			else 
            //			{
            //				NSLog(@"No matches for %@", (id)fontDesc);
            //			}
            //			
            //			
            //			CFRelease(matches);
        }
        else 
        {
            NSLog(@"No matches for %@", (id)fontDesc);
        }
        
        CFRelease(fontDesc);
    }
    else 
    {
        NSLog(@"No matches for %@", [self fontAttributes]);
    }
    
    
}


- (CTFontRef)newMatchingFontSlow
{
    NSDictionary *fontAttributes = [self fontAttributes];
    
    CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
    CTFontRef font = CTFontCreateWithFontDescriptor(fontDesc, self.pointSize, NULL);
    CFRelease(fontDesc);
    
    return font;
}

- (NSUInteger)hash
{
    // two font descriptors are equal if their attribute dictionary are the same
    NSString *attributesDesc = [[self fontAttributes] description];
    
    return [attributesDesc hash];
}

- (BOOL)isEqual:(id)object
{
    return ([self hash] == [object hash]);
}


#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:self.fontName forKey:@"FontName"];
	[encoder encodeObject:self.fontFamily forKey:@"FontFamily"];
	[encoder encodeBool:boldTrait forKey:@"BoldTrait"];
	[encoder encodeBool:italicTrait forKey:@"ItalicTrait"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	
	if (self)
	{
		self.fontName = [decoder decodeObjectForKey:@"FontName"];
		self.fontFamily = [decoder decodeObjectForKey:@"FontFamily"];
		boldTrait = [decoder decodeBoolForKey:@"BoldTrait"];
		italicTrait = [decoder decodeBoolForKey:@"ItalicTrait"];
	}
	
	return self;
}


#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    DTCoreTextFontDescriptor *newDesc = [[DTCoreTextFontDescriptor allocWithZone:zone] initWithFontAttributes:[self fontAttributes]];
    newDesc.pointSize = self.pointSize;
    if (stylisticClass)
    {
        newDesc.stylisticClass = self.stylisticClass;
    }
    
    return newDesc;
}


#pragma mark Properties
- (void)setStylisticClass:(CTFontStylisticClass)newClass
{
    self.fontFamily = nil;
    
    stylisticClass = newClass;
}


- (void)setFontAttributes:(NSDictionary *)attributes
{
    if (!attributes) 
    {
        self.fontFamily = nil;
        self.pointSize = 12;
        
        boldTrait = NO;
        italicTrait = NO;
        expandedTrait = NO;
        condensedTrait = NO;
        monospaceTrait = NO;
        verticalTrait = NO;
        UIoptimizedTrait = NO;
    }
    
    NSDictionary *traitsDict = [attributes objectForKey:(id)kCTFontTraitsAttribute];
    
    if (traitsDict)
    {
        CTFontSymbolicTraits traitsValue = [[traitsDict objectForKey:(id)kCTFontSymbolicTrait ] unsignedIntValue];
        self.symbolicTraits = traitsValue;
    }
    
    
    NSNumber *pointNum = [attributes objectForKey:(id)kCTFontSizeAttribute];
    if (pointNum)
    {
        pointSize = [pointNum floatValue];
    }
    
    NSString *family = [attributes objectForKey:(id)kCTFontFamilyNameAttribute];
    
    if (family)
    {
        self.fontFamily = family;
    }
    
    NSString *name = [attributes objectForKey:(id)kCTFontNameAttribute];
    
    if (name)
    {
        self.fontName = name;
    }
    
}

- (void)setSymbolicTraits:(CTFontSymbolicTraits)symbolicTraits
{
    if (symbolicTraits & kCTFontBoldTrait)
    {
        boldTrait = YES;
    }
    
    if (symbolicTraits & kCTFontItalicTrait)
    {
        italicTrait = YES;
    }
    
    if (symbolicTraits & kCTFontExpandedTrait)
    {
        expandedTrait = YES;
    }
    
    if (symbolicTraits & kCTFontCondensedTrait)
    {
        condensedTrait = YES;
    }
    
    if (symbolicTraits & kCTFontMonoSpaceTrait)
    {
        monospaceTrait = YES;
    }
    
    if (symbolicTraits & kCTFontVerticalTrait)
    {
        verticalTrait = YES;
    }
    
    if (symbolicTraits & kCTFontUIOptimizedTrait)
    {
        UIoptimizedTrait = YES;
    }
    
    // stylistic class is bundled in the traits
    stylisticClass = symbolicTraits & kCTFontClassMaskTrait;   
}

@synthesize fontFamily;
@synthesize fontName;

@synthesize pointSize;
@synthesize boldTrait;
@synthesize italicTrait;
@synthesize expandedTrait;
@synthesize condensedTrait;
@synthesize monospaceTrait;
@synthesize verticalTrait;
@synthesize UIoptimizedTrait;

@synthesize symbolicTraits;

@synthesize stylisticClass;

@end

