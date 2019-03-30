//
//  ViewController.m
//  AppIconClipper
//
//  Created by Lan on 2019/3/29.
//  Copyright © 2019 SummerTea. All rights reserved.
//

#import "ViewController.h"
#import "RBDragView.h"

@interface ViewController()

@property (weak) IBOutlet NSButton *chooseImageBtn;
@property (weak) IBOutlet NSTextField *tipL;

@property(nonatomic, strong) NSOpenPanel *openPanel;
@property(nonatomic, copy) NSURL *fileUrl;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

#pragma mark - Private

- (void)setup
{
    if ([self.view isKindOfClass:[RBDragView class]])
    {
        __weak typeof(self) weak_self = self;
        ((RBDragView *)self.view).dragBlock = ^(NSArray * _Nonnull list) {
            NSString *path = list.firstObject;
            NSURL *url = [NSURL fileURLWithFileSystemRepresentation:path.UTF8String isDirectory:NO relativeToURL:nil];
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
            if ([attributes[NSFileType] isEqualToString:NSFileTypeRegular])
            {
                BOOL isImage = NO;
                for (NSString *suffix in @[@".png", @".jpg", @".jpeg"])
                {
                    if ([path hasSuffix:suffix])
                    {
                        isImage = YES;
                    }
                }
                if (!isImage) return;
                
                weak_self.fileUrl = url;
            }
        };
    }
}

- (NSString *)fileName
{
    return self.fileUrl.lastPathComponent;
}

- (NSURL *)folderUrl
{
    NSString *fileName = [self fileName];
    NSString *name = [[fileName componentsSeparatedByString:@"."].firstObject stringByAppendingString:@"(icon处理)"];
    return [[self.fileUrl URLByDeletingLastPathComponent] URLByAppendingPathComponent:name];;
}

- (void)createImageWithIndex: (NSInteger)index
                       width: (NSArray *)widthArray
                        name: (NSArray *)nameArray
                  folderPath: (NSString *)folderPath
                  sourceImage: (NSImage *)sourceImage
{
    self.tipL.stringValue = [NSString stringWithFormat:@"处理中 %zd/%zd张", index + 1, widthArray.count];
    NSInteger width = [widthArray[index] integerValue];
    NSString *name = nameArray[index];
    NSRect rect = NSMakeRect(0, 0, width, width);
    
    /*
    //调整图片大小
    NSImage *image = [[NSImage alloc] initWithSize:rect.size];
    [image lockFocus];
    [sourceImage drawInRect:rect
                   fromRect:NSZeroRect
                  operation:NSCompositingOperationCopy
                   fraction:1//透明度
             respectFlipped:YES
                      hints:@{NSImageHintInterpolation:[NSNumber numberWithInt:NSImageInterpolationHigh]}];
    [image unlockFocus];
     */
    
    //生成固定尺寸,不带alpha通道的图片
    CGImageRef imageRef = [sourceImage CGImageForProposedRect:NULL context:NULL hints:NULL];
    //CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    //kCGImageAlphaNoneSkipFirst 不要alpha通道
    CGContextRef context = CGBitmapContextCreate(NULL, width, width, 8, 0, CGImageGetColorSpace(imageRef), kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipFirst);
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
    NSImage *imageWithoutAlpha = [[NSImage alloc] initWithCGImage:imageRefWithoutAlpha size:rect.size];
    
    //保存图片
    NSData *imageData = [imageWithoutAlpha TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    imageRep.size = rect.size;
    NSData *pngData = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    [pngData writeToFile:[NSString stringWithFormat:@"%@/%@", folderPath, name] atomically:YES];
    
    if (index == widthArray.count - 1)
    {
        self.tipL.stringValue = [NSString stringWithFormat:@"处理完成 共%zd张", widthArray.count];
        [[NSWorkspace sharedWorkspace] openFile:folderPath];
    }
    else
    {
        [self createImageWithIndex:index + 1 width:widthArray name:nameArray folderPath:folderPath sourceImage:sourceImage];
    }
}

#pragma mark - Event

- (IBAction)chooseImageBtnTapped:(id)sender
{
    __weak typeof(self) weak_self = self;
    [self.openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == 1)
        {
            if (weak_self.openPanel.URLs.count)
            {
                weak_self.fileUrl = weak_self.openPanel.URLs.firstObject;
            }
        }
    }];
}

- (IBAction)processedBtnTapped:(id)sender
{
    __weak typeof(self) weak_self = self;
    if (!self.fileUrl)
    {
        self.tipL.stringValue = @"请先选择图片!!!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weak_self.tipL.stringValue = @"";
        });
        return;
    }
    
    NSURL *folderUrl = [self folderUrl];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderUrl.path])
    {
        //sandbox机制,导致一直创建失败
        [[NSFileManager defaultManager] createDirectoryAtPath:folderUrl.path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:self.fileUrl error:NULL];
    NSImage *image = [[NSImage alloc] initWithData:[fileHandle readDataToEndOfFile]];
    [self createImageWithIndex:0 width:@[@(20*2), @(20*3), @(29*2), @(29*3), @(40*2), @(40*3), @(60*2), @(60*3), @(1024)] name:@[@"20@2x.png", @"20@3x.png", @"29@2x.png", @"29@3x.png", @"40@2x.png", @"40@3x.png", @"60@2x.png", @"60@3x.png", @"1024.png"] folderPath:folderUrl.path sourceImage: image];
}

#pragma mark - Setter

- (void)setFileUrl:(NSURL *)fileUrl
{
    _fileUrl = fileUrl;
    self.chooseImageBtn.title = [self fileName];
}

#pragma mark - Getter

- (NSOpenPanel *)openPanel
{
    if (!_openPanel)
    {
        self.openPanel = ({
            NSOpenPanel *openPanel = [NSOpenPanel openPanel];
            openPanel.canChooseFiles = YES;
            openPanel.canChooseDirectories = NO;
            openPanel.allowsMultipleSelection = NO;
            [openPanel setPrompt:@"选择图片"];
            openPanel.allowedFileTypes = @[@"png", @"jpg", @"jpeg"];
            openPanel.directoryURL = nil;
            openPanel;
        });
    }
    return _openPanel;
}

@end
