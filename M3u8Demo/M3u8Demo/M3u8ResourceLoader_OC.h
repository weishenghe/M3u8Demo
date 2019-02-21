//
//  M3u8ResourceLoader_OC.h
//  M3u8Demo
//
//  Created by heweisheng on 2019/2/20.
//  Copyright © 2019年 owen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVAssetResourceLoader.h>

@interface M3u8ResourceLoader_OC : NSObject <AVAssetResourceLoaderDelegate>

+ (M3u8ResourceLoader_OC *)shared;
- (AVPlayerItem *)playItemWith: (NSString *)url;

@end

