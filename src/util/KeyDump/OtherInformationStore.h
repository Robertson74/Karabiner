/* -*- Mode: objc; Coding: utf-8; indent-tabs-mode: nil; -*- */
#import <Cocoa/Cocoa.h>
#import "KeyRemap4MacBookClient.h"

@interface OtherInformationStore : NSObject
{
  @private
  NSString* version_;
  NSString* applicationname_;
  NSString* inputsourcename_;
  NSString* inputmodename_;

  IBOutlet id label_version_;
  IBOutlet id label_applicationname_;
  IBOutlet id label_inputsourcename_;
  IBOutlet id label_inputmodename_;
  IBOutlet org_pqrs_KeyRemap4MacBook_Client* client_;
}

- (void) setVersion;
- (void) setApplicationName:(NSString*)name;
- (void) setInputSourceName:(NSString*)name;
- (void) setInputModeName:(NSString*)name;
- (void) setDeviceInformation;

- (IBAction) copy:(id)sender;

@end
