//
//  PBJVideoPlayerController.h
//
//  Created by Patrick Piemonte on 5/27/13.
//  Copyright (c) 2013-present, Patrick Piemonte, http://patrickpiemonte.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, PBJVideoPlayerPlaybackState) {
    PBJVideoPlayerPlaybackStateStopped = 0,
    PBJVideoPlayerPlaybackStatePlaying,
    PBJVideoPlayerPlaybackStatePaused,
    PBJVideoPlayerPlaybackStateFailed,
};

typedef NS_ENUM(NSInteger, PBJVideoPlayerBufferingState) {
    PBJVideoPlayerBufferingStateUnknown = 0,
    PBJVideoPlayerBufferingStateReady,
    PBJVideoPlayerBufferingStateDelayed,
};

// PBJVideoPlayerController.view provides the interface for playing/streaming videos
@protocol PBJVideoPlayerControllerDelegate;
@interface PBJVideoPlayerController : UIViewController {
@private
    AVPlayer *_player;
    AVAsset *_asset;
}

@property (nonatomic, weak) id<PBJVideoPlayerControllerDelegate> delegate;

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) AVAsset *asset;

@property (nonatomic, copy, setter=setVideoFillMode:) NSString *videoFillMode; // default, AVLayerVideoGravityResizeAspect

@property (nonatomic) BOOL playbackLoops;
@property (nonatomic) BOOL playbackFreezesAtEnd;
@property (nonatomic, readonly) PBJVideoPlayerPlaybackState playbackState;
@property (nonatomic, readonly) PBJVideoPlayerBufferingState bufferingState;

@property (nonatomic, readonly) NSTimeInterval maxDuration;

@property (nonatomic) float volume;
@property (nonatomic, getter=isMuted) BOOL muted;

- (void)playFromBeginning;
- (void)playFromCurrentTime;
- (void)pause;
- (void)stop;

@end

@protocol PBJVideoPlayerControllerDelegate <NSObject>
@optional
- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer;
- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer;

- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer;
- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer;

- (void)videoPlayerBufferringStateDidChange:(PBJVideoPlayerController *)videoPlayer;
- (void)videoPlayer:(PBJVideoPlayerController *)videoPlayer didUpdatePlayBackProgress:(CGFloat)progress;
- (CMTime)videoPlayerTimeIntervalForPlaybackProgress:(PBJVideoPlayerController *)videoPlayer;

@end
