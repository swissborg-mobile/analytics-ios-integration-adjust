#import "SEGAdjustIntegration.h"

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGAnalyticsUtils.h>
#else
#import "SEGAnalyticsUtils.h" // NOTE: this path will work only with SPM
//#import <Segment/SEGAnalyticsUtils.h>
#endif


@implementation SEGAdjustIntegration

#pragma mark - Initialization

- (instancetype)initWithSettings:(NSDictionary *)settings withAnalytics:(SEGAnalytics *)analytics
{
    if (self = [super init]) {
        self.settings = settings;
        self.analytics = analytics;

        NSString *appToken = [settings objectForKey:@"appToken"];

        NSString *environment = ADJEnvironmentSandbox;
        if ([self setEnvironmentProduction]) {
            environment = ADJEnvironmentProduction;
        }

        ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken
                                                    environment:environment];

        if ([self setEventBufferingEnabled]) {
            [adjustConfig setEventBufferingEnabled:YES];
        }

        if ([self trackAttributionData]) {
            [adjustConfig setDelegate:self];
        }

        if ([self setDelay]) {
            double delayTime = [settings[@"delayTime"] doubleValue];
            [adjustConfig setDelayStart:delayTime];
        }

        [Adjust appDidLaunch:adjustConfig];
    }
    return self;
}

+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)revenueKey
{
    id revenueProperty = nil;

    for (NSString *key in dictionary.allKeys) {
        if ([key caseInsensitiveCompare:revenueKey] == NSOrderedSame) {
            revenueProperty = dictionary[key];
            break;
        }
    }

    if (revenueProperty) {
        if ([revenueProperty isKindOfClass:[NSString class]]) {
            // Format the revenue.
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [formatter setGroupingSeparator:@","];
            [formatter setDecimalSeparator:@"."];
            return [formatter numberFromString:revenueProperty];
        } else if ([revenueProperty isKindOfClass:[NSNumber class]]) {
            return revenueProperty;
        }
    }
    return nil;
}

+ (NSString *)extractCurrency:(NSDictionary *)dictionary withKey:(NSString *)currencyKey
{
    id currencyProperty = nil;

    for (NSString *key in dictionary.allKeys) {
        if ([key caseInsensitiveCompare:currencyKey] == NSOrderedSame) {
            currencyProperty = dictionary[key];
            return currencyProperty;
        }
    }

    // default to USD
    return @"USD";
}

+ (NSString *)extractOrderId:(NSDictionary *)dictionary withKey:(NSString *)orderIdKey
{
    id orderIdProperty = nil;

    for (NSString *key in dictionary.allKeys) {
        if ([key caseInsensitiveCompare:orderIdKey] == NSOrderedSame) {
            orderIdProperty = dictionary[key];
            return orderIdProperty;
        }
    }

    return nil;
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    if (payload.userId != nil && [payload.userId length] != 0) {
        [Adjust addSessionPartnerParameter:@"user_id" value:payload.userId];
    }

    if (payload.anonymousId != nil && [payload.anonymousId length] != 0) {
        [Adjust addSessionPartnerParameter:@"anonymous_id" value:payload.anonymousId];
    }
}

- (void)track:(SEGTrackPayload *)payload
{
    NSString *segmentAnonymousId = [[SEGAnalytics sharedAnalytics] getAnonymousId];
    if (segmentAnonymousId != nil && [segmentAnonymousId length] != 0) {
        [Adjust addSessionPartnerParameter:@"anonymous_id" value:segmentAnonymousId];
        SEGLog(@"[Adjust addSessionPartnerParameter:%@]", segmentAnonymousId);
    }

    NSString *token = [self getMappedCustomEventToken:payload.event];
    if (token) {
        ADJEvent *event = [ADJEvent eventWithEventToken:token];

        // Iterate over all the properties and set them.
        for (NSString *key in payload.properties) {
            NSString *value = [NSString stringWithFormat:@"%@", [payload.properties objectForKey:key]];
            [event addCallbackParameter:key value:value];
        }

        // Track revenue specifically
        NSNumber *revenue = [SEGAdjustIntegration extractRevenue:payload.properties withKey:@"revenue"];
        NSString *currency = [SEGAdjustIntegration extractCurrency:payload.properties withKey:@"currency"];
        if (revenue) {
            [event setRevenue:[revenue doubleValue] currency:currency];
        }

        // Deduplicate transactions with the orderId
        //    from https://segment.com/docs/spec/ecommerce/#completing-an-order
        NSString *orderId = [SEGAdjustIntegration extractOrderId:payload.properties withKey:@"orderId"];
        if (orderId) {
            [event setTransactionId:orderId];
        }

        [Adjust trackEvent:event];
    }
}

- (void)reset
{
    [Adjust resetSessionPartnerParameters];
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [Adjust setDeviceToken:deviceToken];
}

- (void)adjustAttributionChanged:(ADJAttribution *)attribution
{
    [self.analytics track:@"Install Attributed" properties:@{
        @"provider" : @"Adjust",
        @"trackerToken" : attribution.trackerToken ?: [NSNull null],
        @"trackerName" : attribution.trackerName ?: [NSNull null],
        @"campaign" : @{
            @"source" : attribution.network ?: [NSNull null],
            @"name" : attribution.campaign ?: [NSNull null],
            @"content" : attribution.clickLabel ?: [NSNull null],
            @"adCreative" : attribution.creative ?: [NSNull null],
            @"adGroup" : attribution.adgroup ?: [NSNull null]
        }
    }];
}

- (NSString *)getMappedCustomEventToken:(NSString *)event
{
    NSDictionary *tokens = [self.settings objectForKey:@"customEvents"];
    NSString *token = [tokens objectForKey:event];
    return token;
}

- (BOOL)setEventBufferingEnabled
{
    return [(NSNumber *)[self.settings objectForKey:@"setEventBufferingEnabled"] boolValue];
}

- (BOOL)setEnvironmentProduction
{
    return [(NSNumber *)[self.settings objectForKey:@"setEnvironmentProduction"] boolValue];
}


- (BOOL)trackAttributionData
{
    return [(NSNumber *)[self.settings objectForKey:@"trackAttributionData"] boolValue];
}

- (BOOL)setDelay
{
    return [(NSNumber *)[self.settings objectForKey:@"setDelay"] boolValue];
}

@end
