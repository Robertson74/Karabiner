@import Cocoa;

@interface WarpMouseCursorPosition : NSObject

- (int) main;

@end

@implementation WarpMouseCursorPosition

- (void) output:(NSString*)string
{
  NSFileHandle* fh = [NSFileHandle fileHandleWithStandardOutput];
  [fh writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) usage
{
  [self output:@"Usage:\n"];
  [self output:@"  warp-mouse-cursor-position screen NUM VERTICAL X_ADJUSTMENT HORIZONTAL Y_ADJUSTMENT\n"];
  [self output:@"  warp-mouse-cursor-position front_window VERTICAL X_ADJUSTMENT HORIZONTAL Y_ADJUSTMENT\n"];
  [self output:@"  warp-mouse-cursor-position dump_windows\n"];
  [self output:@"\n"];
  [self output:@"Example:\n"];
  [self output:@"  warp-mouse-cursor-position screen 0 top +10 left +20\n"];
  [self output:@"  warp-mouse-cursor-position screen 0 middle +0 center +0\n"];
  [self output:@"  warp-mouse-cursor-position screen 0 bottom -10 right -20\n"];
  [self output:@"  warp-mouse-cursor-position front_window top +10 left +20\n"];
  [self output:@"  warp-mouse-cursor-position front_window middle +0 center +0\n"];
  [self output:@"  warp-mouse-cursor-position front_window bottom -10 right -20\n"];
  [self output:@"\n"];
  [self output:@"VERTICAL:\n"];
  [self output:@"  top middle bottom\n"];
  [self output:@"\n"];
  [self output:@"HORIZONTAL:\n"];
  [self output:@"  left center right\n"];

  [[NSApplication sharedApplication] terminate:nil];
}

- (CGPoint) position:(CGRect)frame vertical:(NSString*)vertical x:(CGFloat)x horizontal:(NSString*)horizontal y:(CGFloat)y
{
  CGPoint position = CGPointZero;

  if ([vertical isEqualToString:@"middle"]) {
    position.y = frame.origin.y + (frame.size.height / 2);
  } else if ([vertical isEqualToString:@"bottom"]) {
    position.y = frame.origin.y + frame.size.height;
  } else {
    position.y = frame.origin.y;
  }
  position.y += y;

  if ([horizontal isEqualToString:@"center"]) {
    position.x = frame.origin.x + (frame.size.width / 2);
  } else if ([horizontal isEqualToString:@"right"]) {
    position.x = frame.origin.x + frame.size.width;
  } else {
    position.x = frame.origin.x;
  }
  position.x += x;

  return position;
}

- (int) main
{
  NSArray* arguments = [[NSProcessInfo processInfo] arguments];

  if ([arguments count] == 1) {
    [self usage];
  } else {
    @try {
      NSString* command = arguments[1];
      if ([command isEqualToString:@"screen"]) {
        if ([arguments count] != 7) {
          [self usage];
        } else {
          NSUInteger number    = [arguments[2] integerValue];
          NSString* vertical   = arguments[3];
          CGFloat x            = [arguments[4] floatValue];
          NSString* horizontal = arguments[5];
          CGFloat y            = [arguments[6] floatValue];

          NSArray* screens = [NSScreen screens];
          if (number <= [screens count] - 1) {
            NSScreen* screen = screens[number];
            CGPoint position = [self position:screen.frame
                                     vertical:vertical
                                            x:x
                                   horizontal:horizontal
                                            y:y];
            CGWarpMouseCursorPosition(position);

          } else {
            [self output:[NSString stringWithFormat:@"screen number should be 0-%ld\n", [screens count] - 1]];
            return 1;
          }
        }

      } else if ([command isEqualToString:@"front_window"]) {
        if ([arguments count] != 6) {
          [self usage];
        } else {
          NSString* vertical   = arguments[2];
          CGFloat x            = [arguments[3] floatValue];
          NSString* horizontal = arguments[4];
          CGFloat y            = [arguments[5] floatValue];

          NSRunningApplication* frontmostApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];

          pid_t pid = [frontmostApplication processIdentifier];
          NSString* bundleIdentifier = [frontmostApplication bundleIdentifier];

          NSArray* windows = (__bridge_transfer NSArray*)(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly |
                                                                                     kCGWindowListExcludeDesktopElements,
                                                                                     kCGNullWindowID));
          for (NSDictionary* window in windows) {
            if ([window[(__bridge NSString*)(kCGWindowOwnerPID)] intValue] == pid) {
              CGFloat windowAlpha   = [window[(__bridge NSString*)(kCGWindowAlpha)] floatValue];
              NSInteger windowLayer = [window[(__bridge NSString*)(kCGWindowLayer)] integerValue];
              CGRect windowBounds;
              CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)(window[(__bridge NSString*)(kCGWindowBounds)]), &windowBounds);

              // Ignore transparent windows.
              CGFloat transparentThreshold = 0.001;
              if (windowAlpha < transparentThreshold) {
                continue;
              }
              // Ignore small windows. (For example, a status bar of Google Chrome.)
              CGFloat windowSizeThreshold = 40;
              if (windowBounds.size.width < windowSizeThreshold ||
                  windowBounds.size.height < windowSizeThreshold) {
                continue;
              }
              // Ignore some app windows.
              if ([bundleIdentifier isEqualToString:@"org.pqrs.KeyRemap4MacBook"]) {
                // There is no reliable public specifications for kCGWindowLayer.
                // So, we use magic number (25) that is confirmed by "dump_windows" option.
                if (windowLayer == 25) {
                  continue;
                }
              }

              // ----------------------------------------
              CGPoint position = [self position:windowBounds
                                       vertical:vertical
                                              x:x
                                     horizontal:horizontal
                                              y:y];
              CGWarpMouseCursorPosition(position);
              break;
            }
          }
        }

      } else if ([command isEqualToString:@"dump_windows"]) {
        NSArray* windows = (__bridge_transfer NSArray*)(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements,
                                                                                   kCGNullWindowID));
        for (NSDictionary* window in windows) {
          pid_t pid = [window[(__bridge NSString*)(kCGWindowOwnerPID)] intValue];
          NSRunningApplication* runningApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
          [self output:[runningApplication bundleIdentifier]];
          [self output:@"\n"];
          [self output:[NSString stringWithFormat:@"%@", window]];
          [self output:@"\n"];
          [self output:@"\n"];
        }
      }

    } @catch (NSException* exception) {
      NSLog(@"%@", exception);
      return 1;
    }
  }
}

@end

int
main(int argc, const char* argv[])
{
  return [[WarpMouseCursorPosition new] main];
}