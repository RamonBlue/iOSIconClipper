//
//  RBDragView.m
//  AppIconClipper
//
//  Created by Lan on 2019/3/30.
//  Copyright © 2019 SummerTea. All rights reserved.
//

#import "RBDragView.h"

@implementation RBDragView

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        [self registerForDraggedTypes:@[NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSPasteboardTypeFileURL]];
    }
    return self;
}

//当拖动数据进入view时会触发这个函数
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([pboard.types containsObject:NSPasteboardTypeFileURL])
    {
        return NSDragOperationCopy;
    }
    else
    {
        return NSDragOperationNone;
    }
}

//当在view中松开鼠标键时会触发以下函数
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    //拿到文件地址
    NSArray *list = [pboard propertyListForType:NSFilenamesPboardType];
    if (self.dragBlock && list.count)
    {
        self.dragBlock(list);
    }
    return YES;
}

@end
