/*
# Copyright (c) 2016 Jeremy Kister
# http://jeremy.kister.net./
# Released under the Artistic License 2.0
*/

#import <Preferences/Preferences.h>
#import <Preferences/PSSpecifier.h>

#define DEBUG 0
#define BITCOIN  @"bitcoin://17nWouHyEueDiRf2vXA17Dpa9kMCXsmNVg"
#define COINBASE @"https://www.coinbase.com/checkouts/56e137721a33709b4d0efceb335f35d9"
#define PAYPAL   @"https://www.paypal.com/myaccount/transfer/send/external?recipient=paypal@kister.net&amount=&currencyCode=USD&payment_type=Gift"

#define TIMEOUT_FILE @"/etc/apt/apt.conf.d/99APTTimeout"

#if DEBUG
#   define debug(fmt, ...) NSLog((@"%s @ %d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define debug(...)
#endif

@interface APTTimeoutListController : PSListController
-(id)readPreferenceValue:(PSSpecifier*)specifier;
-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier;
@end

@interface AuthorListController : PSListController
@end

@implementation AuthorListController
@end

@interface iPopup:NSObject
-(void) title:(NSString *)UITitle message:(NSString *)UIMessage;
@end
 
@implementation iPopup
-(void) title:(NSString *)UITitle message:(NSString *)UIMessage {
    UIAlertView *alert = [
        [UIAlertView alloc]
            initWithTitle:UITitle
            message:UIMessage
            delegate:self
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil
                         ];
    [alert show];
    [alert release];
}
@end

@implementation APTTimeoutListController
- (NSArray *)specifiers {
	if (! _specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"APTTimeout" target:self] retain];
	}
	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    debug(@"path is: %@", path);
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *value = (settings[specifier.properties[@"key"]]) ?:
                       specifier.properties[@"default"] ;
    debug(@"returning: %@", value);
    return value;
}
 
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    debug(@"%@", specifier.properties[@"key"]);
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:path atomically:YES];
    CFStringRef notificationName = (CFStringRef)specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }

#if DEBUG
#   NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
#   debug(@"Settings: %@", settings);
#endif

}

-(void)repo {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://url/https://cydia.saurik.com/api/share#?source=http://kister.net/cydia/"]];
}

-(void)twitter {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://user?screen_name=jkister"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=jkister"]];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/jkister"]];
    }
}

-(void)reddit {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alienblue://r/apttimeout"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"alienblue://r/apttimeout"]];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://reddit.com/r/apttimeout"]];
    }
}

-(void)paypal {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PAYPAL]];
}

-(void)bitcoin {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:BITCOIN]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:BITCOIN]];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:COINBASE]];
   }
}

-(void)apply {

    /* this should eventually be a darwin hook
       https://github.com/angelXwind/PreferenceOrganizer2 */

    NSString *http = nil;
    NSString *ftp = nil;
    NSMutableArray *specifiers = [[NSMutableArray alloc] initWithArray:((PSListController *)self).specifiers];
    for (int i=0; i < [specifiers count]; i++ ){
        PSSpecifier *item = [specifiers objectAtIndex:i];
   
        if ([item.identifier isEqualToString:@"HTTP Timeout"]){
            http = [self readPreferenceValue:item];
        } else if ([item.identifier isEqualToString:@"FTP Timeout"]){
            ftp = [self readPreferenceValue:item];
        }
        
        if ( http != nil && ftp != nil ){
            break;
        }
    
    }

    iPopup *popup = [[iPopup alloc] init];

    debug(@"HTTP: %@ - FTP: %@", http, ftp);
    if( http == nil || ftp == nil ){
        [popup title:@"Error" message:@"Failure getting timeout values."];
        return;
    }

    NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:TIMEOUT_FILE];
    if (fh == nil){
        debug(@"Could not open timeout file");
        [popup title:@"Error" message:@"Couldnt open timeout file"];
        return;
    }

    [fh truncateFileAtOffset: 0];
    NSString *hline = [NSString stringWithFormat:@"Acquire::http::Timeout \"%@\";\n", http];
    NSString *fline = [NSString stringWithFormat:@"Acquire::ftp::Timeout \"%@\";\n",  ftp];

    [fh writeData:[hline dataUsingEncoding:NSASCIIStringEncoding]];
    [fh writeData:[fline dataUsingEncoding:NSASCIIStringEncoding]];
    [fh closeFile];

    debug(@"Success HTTP %@ -- FTP %@", http, ftp);
    [popup title:@"Success" message:@"Timeouts updated."];
}


@end
