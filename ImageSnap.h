//
//  ImageSnap.h
//  ImageSnap
//
//  Created by Robert Harder on 9/10/09.
//
#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#include "ImageSnap.h"


int init();
int release ();
int snap();

@interface ImageSnap : NSObject {
    QTCaptureSession                    *mCaptureSession;
    QTCaptureDeviceInput                *mCaptureDeviceInput;
    QTCaptureDecompressedVideoOutput    *mCaptureDecompressedVideoOutput;
    CVImageBufferRef                    mCurrentImageBuffer;
}

+(QTCaptureDevice *)defaultVideoDevice;
+ (BOOL)saveImage:(NSImage *)image toPath: (NSString*)path;
+(NSData *)dataFrom:(NSImage *)image;

-(id)init;
-(void)dealloc;
-(BOOL)startSession:(QTCaptureDevice *)device;
-(NSImage *)snapshot;
-(void)stopSession;


@end
