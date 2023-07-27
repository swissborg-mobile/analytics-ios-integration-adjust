#import <Foundation/Foundation.h>
#import "Adjust.h" // NOTE: this path will work only with SPM
//#import <Adjust/Adjust.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGAnalytics.h>
#else
#import "SEGAnalytics.h" // NOTE: this path will work only with SPM
//#import <Segment/SEGAnalytics.h>
#endif


@interface SEGAdjustIntegration : NSObject <SEGIntegration, AdjustDelegate>

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) SEGAnalytics *analytics;

- (instancetype)initWithSettings:(NSDictionary *)settings withAnalytics:(SEGAnalytics *)analytics;

@end
