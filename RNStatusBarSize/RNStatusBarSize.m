#import "RNStatusBarSize.h"

#import "RCTAssert.h"
#import "RCTEventDispatcher.h"

static float RNCurrentStatusBarSize()
{
  CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
  float height1 = MIN(statusBarSize.width, statusBarSize.height);
  float height2 = [[UIApplication sharedApplication] statusBarFrame].size.height;
  return height2;
}

@implementation RNStatusBarSize
{
  float _lastKnownHeight;
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"statusBarSizeWillChange",
           @"statusBarSizeDidChange"];
}

- (void)startObserving
{
  _lastKnownHeight = RNCurrentStatusBarSize();
    
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleStatusBarDidChange)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleStatusBarWillChange:)
                                               name:UIApplicationWillChangeStatusBarFrameNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleStatusBarDidChange)
                                               name:UIApplicationDidChangeStatusBarFrameNotification
                                             object:nil];
}

- (void)stopObserving
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([[UIDevice currentDevice] isGeneratingDeviceOrientationNotifications]) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
}


- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

#pragma mark - App Notification Methods

- (void)handleStatusBarWillChange:(NSNotification *)notification
{
  NSValue *rectValue = [[notification userInfo] valueForKey:UIApplicationStatusBarFrameUserInfoKey];
  
  CGRect newFrame;
  [rectValue getValue:&newFrame];
  
  float newHeight = newFrame.size.height;
  if (newHeight != _lastKnownHeight) {
    [self sendEventWithName:@"statusBarFrameWillChange"
                             body:@{@"height": [NSNumber numberWithFloat:newHeight]}];
  }
}

- (void)handleStatusBarDidChange
{
  float newHeight = RNCurrentStatusBarSize();
  if (newHeight != _lastKnownHeight) {
    _lastKnownHeight = newHeight;
    [self sendEventWithName:@"statusBarFrameDidChange"
                             body:@{@"height": [NSNumber numberWithFloat:_lastKnownHeight]}];
  }
}



#pragma mark - Public API

/**
* Get the current height of the status bar
*/
RCT_EXPORT_METHOD(getCurrentStatusBarHeight:(RCTResponseSenderBlock)callback
                  error:(__unused RCTResponseSenderBlock)error)
{
  if (_lastKnownHeight == 0) {
    _lastKnownHeight = RNCurrentStatusBarSize();
  }
  callback(@[@{@"height": [NSNumber numberWithFloat:_lastKnownHeight]}]);
}

@end
