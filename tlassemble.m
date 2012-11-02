/*
*  Copyright (c) 2012, Daniel Bridges
*  All rights reserved.
*  
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions are met:
*      * Redistributions of source code must retain the above copyright
*        notice, this list of conditions and the following disclaimer.
*      * Redistributions in binary form must reproduce the above copyright
*        notice, this list of conditions and the following disclaimer in the
*        documentation and/or other materials provided with the distribution.
*      * Neither the name of the Daniel Bridges nor the
*        names of its contributors may be used to endorse or promote products
*        derived from this software without specific prior written permission.
*  
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
*  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
*  DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
*  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
*  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
*  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*
*/

#ifdef DEBUG
        #define DLOG(fmt, args...) NSLog(@"%s:%d "fmt,__FILE__,__LINE__,args)
    #else
        #define DLOG(fmt, args...)
#endif

#include <stdio.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <QTKit/QTKit.h>

void usage() {
    fprintf(stderr, "%s","Usage: tlassemble INPUTDIRECTORY OUTPUTFILENAME [OPTIONS]\n"
            "Try 'tlassemble --help' for more information.\n");
}

void help() {
    printf("%s","\nUsage: tlassemble INPUTDIRECTORY OUTPUTFILENAME [OPTIONS]\n\n"
          "EXAMPLES\n"
          "tlassemble ./images time_lapse.mov\n"
          "tlassemble ./images time_lapse.mov -fps 30 -height 720 -codec h264 -quality high\n"
          "tlassemble ./images time_lapse.mov -quiet yes\n\n"
          "OPTIONS\n"
          "-fps: Frames per second for final movie can be anywhere between 0.1 and 60.0.\n"
        "-height: If specified images are resized proportionally to height given.\n"
        "-codec: Codec to use to encode can be 'h264' 'photojpeg' 'raw' or 'mpv4'.\n"
      "-quality: Quality to encode with can be 'high' 'normal' 'low'.\n"
        "-quiet: Set to 'yes' to suppress output during encoding.\n"
      "-reverse: Set to 'yes' to reverse the order that images are displayed in the movie.\n"
      "\n"
      "DEFAULTS\n"
      "fps = 30\n"
      "height = original image size\n"
      "codec = h264\n"
      "quality = high\n\n"
      "INFO\n"
      "- Images should be no larger than 1920 x 1080 pixels.\n"
      "- Images have to be jpegs and have the extension '.jpg' or '.jpeg' (case insensitive).\n\n"
      "tlassemble 1.0\n\n"
      "This software is provided in the hope that it will be useful, but without any warranty, without even the implied warranty for merchantability or fitness for a particular purpose. The software is provided as is and its designer is not to be held responsible for any lost data or other corruption.\n\n");
}

int main(int argc, const char *argv[]) {
    // Command line options:
    // 
    // codec (h264, mp4v, photojpeg, raw)
    // fps (between 0.1 and 60)
    // quality (high, normal, low)
    // width (resize proportionally)

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int n;

    double height;
    double fps;   
    NSString *codecSpec;
    NSString *qualitySpec;
    NSString *destPath;
    NSString *inputPath;
	NSArray *imageFiles;
	NSError *err;
	err = nil;
	BOOL isDir;
    BOOL quiet;
    BOOL reverseArray;

    // Parse command line options
    NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
    if (argc == 2) {
        if (strcmp(argv[1], "--help") == 0 ||
            strcmp(argv[1], "-help") == 0) {
            help();
            return 1;
        }
    }
    if (argc < 3) {
        usage();
        return 1;
    }
        
    height = [args doubleForKey:@"height"];
    fps = [args doubleForKey:@"fps"];
    codecSpec = [args stringForKey:@"codec"];
    qualitySpec = [args stringForKey:@"quality"];
    quiet = [args boolForKey:@"quiet"];
    reverseArray = [args boolForKey:@"reverse"];

    NSDictionary *codec = [NSDictionary dictionaryWithObjectsAndKeys:
        @"avc1", @"h264",
        @"mpv4", @"mpv4",
        @"jpeg", @"photojpeg",
        @"raw ", @"raw", nil];
    
    NSDictionary *quality = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithLong:codecLowQuality], @"low",
        [NSNumber numberWithLong:codecNormalQuality], @"normal",
        [NSNumber numberWithLong:codecMaxQuality], @"high", nil];

    if (height > 1080) {
        fprintf(stderr, "%s",
                "Error: Maximum movie height is 1080px, use option "
                "-height to automatically resize images.\n"
                "Try 'tlassemble --help' for more information.\n");
        return 1;
    }

    if (fps == 0.0) {
        fps = 30.0;
    }

    if (fps < 0.1 || fps > 60) {
        fprintf(stderr, "%s","Error: Framerate must be between 0.1 and 60 fps.\n"
                "Try 'tlassemble --help' for more information.\n");
        return 1;
    }

    if (codecSpec == nil) {
        codecSpec = @"h264";
    }

    if (![[codec allKeys] containsObject:codecSpec]) {
        usage();
        return 1;
    }
    
    if (qualitySpec == nil) {
        qualitySpec = @"high";
    }

    if ([[quality allKeys] containsObject:qualitySpec] == NO) {
        usage();
        return 1;
    }
    
    DLOG(@"quality: %@",qualitySpec);
    DLOG(@"codec: %@",codecSpec);
    DLOG(@"fps: %f",fps);
    DLOG(@"height: %f",height);
    DLOG(@"quiet: %i", quiet);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    inputPath = [[NSURL fileURLWithPath:[[NSString stringWithUTF8String:argv[1]]
                    stringByExpandingTildeInPath]] path];
    destPath = [[NSURL fileURLWithPath:[[NSString stringWithUTF8String:argv[2]]
                    stringByExpandingTildeInPath]] path];

    if (![destPath hasSuffix:@".mov"]) {
        fprintf(stderr, "Error: Output filename must be of type '.mov'\n");
        return 1;
    }

    if ([fileManager fileExistsAtPath:destPath]) {
        fprintf(stderr, "Error: Output file already exists.\n");
        return 1;
    }

    if (!([fileManager fileExistsAtPath:[destPath stringByDeletingLastPathComponent]
                       isDirectory:&isDir] && isDir)) {
        fprintf(stderr,
                "Error: Output file is not writable. "
                "Does the destination directory exist?\n");
        return 1;
    }
    
    DLOG(@"Input Path: %@", inputPath);
    DLOG(@"Destination Path: %@", destPath);

    if ((([fileManager fileExistsAtPath:inputPath isDirectory:&isDir] && isDir) && 
		[fileManager isWritableFileAtPath:inputPath]) == NO) {
        fprintf(stderr, "%s","Error: Input directory does not exist.\n"
                "Try 'tlassemble --help' for more information.\n");
        return 1;
	}

    NSDictionary *imageAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
                                         [codec objectForKey:codecSpec], QTAddImageCodecType,
										 [quality objectForKey:qualitySpec], QTAddImageCodecQuality,
										 [NSNumber numberWithLong:1000], QTTrackTimeScaleAttribute,
										 nil];

    DLOG(@"%@",imageAttributes);

    imageFiles = [fileManager contentsOfDirectoryAtPath:inputPath error:&err];
    imageFiles = [imageFiles sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    int imageCount = 0;

    if (reverseArray) {
        NSMutableArray *reversedArray = [NSMutableArray arrayWithCapacity:[imageFiles count]];
        for (NSString *element in [imageFiles reverseObjectEnumerator]) {
            [reversedArray addObject:element];
        }
        imageFiles = reversedArray;
    }
    
    for (NSString *file in imageFiles) {
        if ([[file pathExtension] caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
            [[file pathExtension] caseInsensitiveCompare:@"jpg"] == NSOrderedSame) {
            imageCount++;
        }
    }
    
    if (imageCount == 0) {
        fprintf(stderr, "Error: Directory '%s' %s",
                [[inputPath stringByAbbreviatingWithTildeInPath] UTF8String],
                "does not contain any jpeg images.\n"
                "Try 'tlassemble --help' for more information.\n");
        return 1;
        
    }


    QTMovie *movie = [[QTMovie alloc] initToWritableFile:destPath error:NULL];
    if (movie == nil) {
        fprintf(stderr, "%s","Error: Unable to initialize QT object.\n"
                "Try 'tlassemble --help' for more information.\n");
        return 1;
    }
    [movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];

    long timeScale = 100000;
    long long timeValue = (long long) ceil((double) timeScale / fps);
    QTTime duration = QTMakeTime(timeValue, timeScale);
    
    NSImage *image;
    NSImage *resizedImage;
    NSString *fullFilename;
    
    double width = 0;
    int counter = 0;
    
    for (NSString *file in imageFiles) {
        fullFilename = [inputPath stringByAppendingPathComponent:file];
        if ([[fullFilename pathExtension] caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
            [[fullFilename pathExtension] caseInsensitiveCompare:@"jpg"] == NSOrderedSame) {
            NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
            image = [[NSImage alloc] initWithContentsOfFile:fullFilename];
            
            if (height != 0) {
                //get proportion
                double ratio = [image size].width/[image size].height;
                width = height*ratio;
                resizedImage = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
                [resizedImage lockFocus];
                [image drawInRect:NSMakeRect(0.f, 0.f, width, height) 
                         fromRect:NSZeroRect 
                        operation:NSCompositeSourceOver fraction:1.f];
                [resizedImage unlockFocus];
                
                [movie addImage:resizedImage
                    forDuration:duration
                 withAttributes:imageAttributes];
                
                [resizedImage release];
            }
            else {
                [movie addImage:image
                    forDuration:duration
                 withAttributes:imageAttributes];
            }

            [image release];
            [innerPool release];
            counter++;
            if (!quiet) {
                printf("Processed %s (%i of %i)\n", [file UTF8String], counter, imageCount);
            }
        }
    }
    [movie updateMovieFile];
    
    [movie release];

    if (!quiet) {
        printf("Successfully created %s\n",[[destPath stringByAbbreviatingWithTildeInPath] UTF8String]);
    } 
    // Clean up
    [pool drain];
    return 0;
}

