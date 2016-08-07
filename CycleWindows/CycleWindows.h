//
//  CycleWindows.h
//  CycleWindows
//
//  Created by Julian Weinert on 07/08/16.
//  Copyright © 2016 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface CycleWindows : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end