/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/NSSet.h>

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformVideo.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAppleVideoLogGroup, "loom.video.apple", 1, 0);

static VideoEventCallback gEventCallback = NULL;

static UIViewController* getParentViewController()
{
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}


@interface MoviePlayerViewController : UIViewController

+ (MoviePlayerViewController *)controller:(NSURL *)videoUrl;

@end

@interface MoviePlayerViewController ()

@property (nonatomic, retain) MPMoviePlayerController* videoPlayer; 
@property (nonatomic, retain) NSURL*                   videoUrl;    

@end

@implementation MoviePlayerViewController

+ (MoviePlayerViewController *)controller:(NSURL *)videoUrl
{
    MoviePlayerViewController* controller = [[MoviePlayerViewController alloc] autorelease];    
    controller.videoUrl = videoUrl;    
    return controller;
}

- (void)dealloc
{
    [self.videoPlayer stop];
    
    self.videoPlayer = nil;
    self.videoUrl    = nil;
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"MPMoviePlayerController";

    NSLog(@"View Did Load");

    self.videoPlayer = [[[MPMoviePlayerController alloc] initWithContentURL:self.videoUrl] autorelease];
    self.videoPlayer.controlStyle             = MPMovieControlStyleNone;
    self.videoPlayer.scalingMode              = MPMovieScalingModeAspectFit;
    self.videoPlayer.shouldAutoplay           = YES;
    self.videoPlayer.view.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.videoPlayer.view.autoresizesSubviews = YES;
    self.videoPlayer.view.frame               = getParentViewController().view.bounds;

    [[NSNotificationCenter defaultCenter] addObserver:self      
                                          selector:@selector(videoFinished:)
                                          name:MPMoviePlayerPlaybackDidFinishNotification
                                          object:self.videoPlayer];    
    
    [self.videoPlayer prepareToPlay];
    [self.view addSubview:self.videoPlayer.view];
}

- (void)viewDidUnload
{
    [self.videoPlayer stop];

    self.videoPlayer = nil;
    self.videoUrl    = nil;

    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setWantsFullScreenLayout:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController.view setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    [super viewWillDisappear:animated];
}

- (void)videoFinished:(NSNotification *)notification
{
    NSLog(@"Video ended!");
}

@end


int platform_videoSupported()
{
    return true;
}

void platform_videoInitialize(VideoEventCallback eventCallback)
{
    gEventCallback = eventCallback;

    ////TODO: video playback support on iOS
}

void platform_videoPlayFullscreen(const char *video, int scaleMode, int controlMode, unsigned int bgColor)
{
    //TODO: Add error checking

    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];            
    resourcePath = [resourcePath stringByAppendingString:@"/assets/bigbuckbunny.mp4"];
    
    NSLog(@"%@", resourcePath);

    NSURL *videoUrl = [NSURL fileURLWithPath:resourcePath];

    [getParentViewController() presentViewController:[MoviePlayerViewController controller:videoUrl] animated:YES completion:nil];

    /*

    gVideoPlayer = [[[MPMoviePlayerController alloc] initWithContentURL:videoUrl] retain];

    [[NSNotificationCenter defaultCenter] addObserver:gVideoPlayer      
                                          selector:@selector(VideoFinished:)
                                          name:MPMoviePlayerPlaybackDidFinishNotification
                                          object:gVideoPlayer];

    gVideoPlayer.controlStyle             = MPMovieControlStyleNone;//MPMovieControlStyleDefault;
    gVideoPlayer.scalingMode              = MPMovieScalingModeAspectFit;
    gVideoPlayer.shouldAutoplay           = YES;
    gVideoPlayer.view.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gVideoPlayer.view.autoresizesSubviews = YES;
    gVideoPlayer.view.frame               = getParentViewController().view.bounds;
    
    [gVideoPlayer prepareToPlay];
    [getParentViewController().view addSubview:gVideoPlayer.view];
    */

}
