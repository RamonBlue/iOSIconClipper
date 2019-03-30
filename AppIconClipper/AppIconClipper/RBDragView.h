//
//  RBDragView.h
//  AppIconClipper
//
//  Created by Lan on 2019/3/30.
//  Copyright © 2019 SummerTea. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RBDragView : NSView

@property(nonatomic, copy) void(^dragBlock)(NSArray *list);

@end

NS_ASSUME_NONNULL_END
