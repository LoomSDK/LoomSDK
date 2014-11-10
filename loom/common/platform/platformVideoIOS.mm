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

#define UIColorFromRGB(rgbValue) [UIColor \
       colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
       green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
       blue:((float)(rgbValue & 0xFF))/255.0 alpha:((float)((rgbValue & 0xFF000000) >> 24))/255.0]


//syncs to the control modes defined in the LoomScript file Video.ls
enum 
{
    ControlMode_Show            = 0,
    ControlMode_Hide            = 1,
    ControlMode_StopOnTouch     = 2
};


static VideoEventCallback gEventCallback = NULL;
static unsigned int gBackgroundColor = 0xFF000000;
static unsigned int gControlMode = 0;

static UIViewController* getParentViewController()
{
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

@interface MoviePlayerViewController : UIViewController <UIGestureRecognizerDelegate>

+ (MoviePlayerViewController *)controller:(NSURL *)videoUrl;

@end

@interface MoviePlayerViewController ()

@property (nonatomic, retain) MPMoviePlayerController*  videoPlayer; 
@property (nonatomic, retain) NSURL*                    videoUrl;    
@property (nonatomic, retain) id                        becameActiveObserver;    

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

    self.videoPlayer = [[[MPMoviePlayerController alloc] initWithContentURL:self.videoUrl] autorelease];
    self.videoPlayer.controlStyle             = (gControlMode == ControlMode_Show) ? MPMovieControlStyleFullscreen : MPMovieControlStyleNone;
    self.videoPlayer.scalingMode              = MPMovieScalingModeAspectFit;
    self.videoPlayer.shouldAutoplay           = YES;
    self.videoPlayer.view.frame               = getParentViewController().view.bounds;
    self.videoPlayer.fullscreen               = YES;

    self.videoPlayer.backgroundView.backgroundColor = UIColorFromRGB(gBackgroundColor);

    [[NSNotificationCenter defaultCenter] addObserver:self      
                                          selector:@selector(videoFinished:)
                                          name:MPMoviePlayerPlaybackDidFinishNotification
                                          object:self.videoPlayer];    
    
    //auto-resume video playback when the application becomes active
    self.becameActiveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                                        object:[UIApplication sharedApplication] 
                                                                        queue:[NSOperationQueue mainQueue] 
                                                                        usingBlock:^(NSNotification *note) 
                                                                        { [self.videoPlayer play]; }
    ];    

    [self.videoPlayer prepareToPlay];
    [self.view addSubview:self.videoPlayer.view];

    //do we need to stop on touch?
    if(gControlMode == ControlMode_StopOnTouch)
    {
        UITapGestureRecognizer *touch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchPlayer:)];
        touch.delegate = self;
        [self.videoPlayer.view addGestureRecognizer:touch];
        [touch release];
    }    
}

// this allows you to dispatch touches
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch 
{
    return YES;
}

// this enables you to handle multiple recognizers on single view
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{
    return YES;
}

- (void)touchPlayer:(UITapGestureRecognizer *)gesture
{
    [self.videoPlayer stop];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void) videoFinished:(NSNotification*)notification 
{
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded || reason == MPMovieFinishReasonUserExited)  
    {
        //movie finished playing
        gEventCallback("complete", "");
    }
    else
    {
        //error?
        gEventCallback("fail", "");
    }

    //remove active observer
    [[NSNotificationCenter defaultCenter] removeObserver:self.becameActiveObserver];

    [self dismissViewControllerAnimated:NO completion:nil];
}

@end


int platform_videoSupported()
{
    return true;
}

void platform_videoInitialize(VideoEventCallback eventCallback)
{
    gEventCallback = eventCallback;    
}

void platform_videoPlayFullscreen(const char *video, int scaleMode, int controlMode, unsigned int bgColor)
{
    // remember the background color as we can't set it here
    gBackgroundColor = bgColor;
    gControlMode = controlMode;

    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/"];
    resourcePath = [resourcePath stringByAppendingString:[NSString stringWithUTF8String:video]];
    
    NSLog(@"%@", resourcePath);

    NSURL *videoUrl = [NSURL fileURLWithPath:resourcePath];
    [getParentViewController() presentViewController:[MoviePlayerViewController controller:videoUrl] animated:NO completion:nil];

}
