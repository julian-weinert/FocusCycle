//
//  CycleWindows.h
//  CycleWindows
//
//  Created by Julian Weinert on 07/08/16.
//  Copyright © 2016 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface JFWFocusCycle : NSObject

@property (nonatomic, strong, readonly) NSBundle *bundle;

+ (instancetype)sharedPlugin;

@end