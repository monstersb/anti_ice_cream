#import "ImageSnap.h"

@interface ImageSnap()

- (void)captureOutput:(QTCaptureOutput *)captureOutput 
  didOutputVideoFrame:(CVImageBufferRef)videoFrame 
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
       fromConnection:(QTCaptureConnection *)connection;

@end

@implementation ImageSnap

ImageSnap *_snap;

- (id)init{
    self = [super init];
    mCaptureSession = nil;
    mCaptureDeviceInput = nil;
    mCaptureDecompressedVideoOutput = nil;
    mCurrentImageBuffer = nil;
    return self;
}

- (void)dealloc{
    
    if( mCaptureSession )                   [mCaptureSession release];
    if( mCaptureDeviceInput )               [mCaptureDeviceInput release];
    if( mCaptureDecompressedVideoOutput )   [mCaptureDecompressedVideoOutput release];
    CVBufferRelease(mCurrentImageBuffer);
    
    [super dealloc];
}

+ (QTCaptureDevice *)defaultVideoDevice{
    QTCaptureDevice *device = nil;
    device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    if( device == nil ){
        device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
    }
    return device;
}

+ (BOOL) saveImage:(NSImage *)image toPath: (NSString*)path{
    NSData *photoData = [ImageSnap dataFrom:image];
    return [photoData writeToFile:path atomically:NO];
}

+(NSData *)dataFrom:(NSImage *)image {
    NSData *tiffData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:tiffData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
    return [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
}


-(NSImage *)snapshot{
    CVImageBufferRef frame = nil;
    while( frame == nil ){
        @synchronized(self){
            frame = mCurrentImageBuffer;
            CVBufferRetain(frame);
        }
        if( frame == nil ){
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.1]];
        }
        
    }
    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:frame]];
    NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
    [image addRepresentation:imageRep];
    
    return image;
}


-(void)stopSession{
    while( mCaptureSession != nil ){
        [mCaptureSession stopRunning];

        if( [mCaptureSession isRunning] ){
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.1]];
        }else {
            if( mCaptureSession )                   [mCaptureSession release];
            if( mCaptureDeviceInput )               [mCaptureDeviceInput release];
            if( mCaptureDecompressedVideoOutput )   [mCaptureDecompressedVideoOutput release];
            
            mCaptureSession = nil;
            mCaptureDeviceInput = nil;
            mCaptureDecompressedVideoOutput = nil;
        }
        
    }
}

-(BOOL)startSession:(QTCaptureDevice *)device{
    NSError *error = nil;
    
    mCaptureSession = [[QTCaptureSession alloc] init];
    if( ![device open:&error] ){
        [mCaptureSession release];
        mCaptureSession = nil;
        return NO;
    }
    
    mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
    if (![mCaptureSession addInput:mCaptureDeviceInput error:&error]) {
        [mCaptureSession release];
        [mCaptureDeviceInput release];
        mCaptureSession = nil;
        mCaptureDeviceInput = nil;
        return NO;
    }
    
    mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
    [mCaptureDecompressedVideoOutput setDelegate:self];
    if (![mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error]) {
        [mCaptureSession release];
        [mCaptureDeviceInput release];
        [mCaptureDecompressedVideoOutput release];
        mCaptureSession = nil;
        mCaptureDeviceInput = nil;
        mCaptureDecompressedVideoOutput = nil;
        return NO;
    }
    
    @synchronized(self){
        if( mCurrentImageBuffer != nil ){
            CVBufferRelease(mCurrentImageBuffer);
            mCurrentImageBuffer = nil;
        }
    }
    
    [mCaptureSession startRunning];
    
    return YES;
}

- (void)captureOutput:(QTCaptureOutput *)captureOutput 
  didOutputVideoFrame:(CVImageBufferRef)videoFrame 
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
       fromConnection:(QTCaptureConnection *)connection
{
    if (videoFrame == nil ) {
        return;
    }
    CVImageBufferRef imageBufferToRelease;
    CVBufferRetain(videoFrame);
    
    @synchronized(self){
        imageBufferToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;
    }
    CVBufferRelease(imageBufferToRelease);
}

@end

int init() {
    _snap = [[ImageSnap alloc] init];
    [_snap startSession:[ImageSnap defaultVideoDevice]];
    return 0;
}

int release () {
    [_snap stopSession];
    [_snap release];
    return 0;
}

int snap() {
    NSImage *image = nil;
    image = [_snap snapshot];
    if (image != nil)  {
        [ImageSnap saveImage:image toPath:@"ice.png"];
    }
    return 0;
}


int main (int argc, const char * argv[]) {
    NSApplicationLoad();
    NSAutoreleasePool *pool;
    pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
  
    init();
    snap();
    
    release();
    
    [pool drain];
    return 0;
}

