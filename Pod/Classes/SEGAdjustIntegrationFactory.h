#import <Foundation/Foundation.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGIntegrationFactory.h>
#else
#import "SEGIntegrationFactory.h" // NOTE: this path will work only with SPM
//#import <Segment/SEGIntegrationFactory.h>
#endif

@interface SEGAdjustIntegrationFactory : NSObject <SEGIntegrationFactory>

+ (instancetype)instance;

@end
