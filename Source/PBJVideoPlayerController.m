//
//  PBJVideoPlayerController.m
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

#import "PBJVideoPlayerController.h"
#import "PBJVideoView.h"

#import <AVFoundation/AVFoundation.h>

#define LOG_PLAYER 0
#ifndef DLog
#if !defined(NDEBUG) && LOG_PLAYER
#   define DLog(fmt, ...) NSLog((@"player: " fmt), ##__VA_ARGS__);
#else
#   define DLog(...)
#endif
#endif

// KVO contexts
static NSString * const PBJVideoPlayerObserverContext = @"PBJVideoPlayerObserverContext";
static NSString * const PBJVideoPlayerItemObserverContext = @"PBJVideoPlayerItemObserverContext";
static NSString * const PBJVideoPlayerLayerObserverContext = @"PBJVideoPlayerLayerObserverContext";

// KVO player keys
static NSString * const PBJVideoPlayerControllerTracksKey = @"tracks";
static NSString * const PBJVideoPlayerControllerPlayableKey = @"playable";
static NSString * const PBJVideoPlayerControllerDurationKey = @"duration";
static NSString * const PBJVideoPlayerControllerRateKey = @"rate";

// KVO player item keys
static NSString * const PBJVideoPlayerControllerStatusKey = @"status";
static NSString * const PBJVideoPlayerControllerEmptyBufferKey = @"playbackBufferEmpty";
static NSString * const PBJVideoPlayerControllerPlayerKeepUpKey = @"playbackLikelyToKeepUp";

// KVO player layer keys
static NSString * const PBJVideoPlayerControllerReadyForDisplay = @"readyForDisplay";

// TODO: scrubbing support
//static float const PBJVideoPlayerControllerRates[PBJVideoPlayerRateCount] = { 0.25, 0.5, 0.75, 1, 1.5, 2 };
//static NSInteger const PBJVideoPlayerRateCount = 6;

@interface PBJVideoPlayerController () <
    UIGestureRecognizerDelegate>
{
    AVAsset *_asset;
    AVPlayer *_player;
    AVPlayerItem *_playerItem;

    NSString *_videoPath;
    PBJVideoView *_videoView;

    PBJVideoPlayerPlaybackState _playbackState;
    PBJVideoPlayerBufferingState _bufferingState;
    
    // flags
    struct {
        unsigned int readyForPlayback:1;
        unsigned int playbackLoops:1;
        unsigned int playbackFreezesAtEnd:1;
    } __block _flags;
}

@end

@implementation PBJVideoPlayerController

@synthesize delegate = _delegate;
@synthesize videoPath = _videoPath;
@synthesize playbackState = _playbackState;
@synthesize bufferingState = _bufferingState;
@synthesize videoFillMode = _videoFillMode;

#pragma mark - getters/setters

- (void)setVideoFillMode:(NSString *)videoFillMode
{
	if (_videoFillMode != videoFillMode) {
		_videoFillMode = videoFillMode;
		_videoView.videoFillMode = _videoFillMode;
	}
}

- (NSString *)videoPath
{
    return _videoPath;
}

- (void)setVideoPath:(NSString *)videoPath
{
    if (!videoPath || [videoPath length] == 0)
        return;

    NSURL *videoURL = [NSURL URLWithString:videoPath];
    if (!videoURL || ![videoURL scheme]) {
        videoURL = [NSURL fileURLWithPath:videoPath];
    }
    _videoPath = videoPath;

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    [self _setAsset:asset];
}

- (BOOL)playbackLoops
{
    return _flags.playbackLoops;
}

- (void)setPlaybackLoops:(BOOL)playbackLoops
{
    _flags.playbackLoops = (unsigned int)playbackLoops;
    if (!_player)
        return;
    
    if (!_flags.playbackLoops) {
        _player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    } else {
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    }
}

- (BOOL)playbackFreezesAtEnd
{
    return _flags.playbackFreezesAtEnd;
}

- (void)setPlaybackFreezesAtEnd:(BOOL)playbackFreezesAtEnd
{
    _flags.playbackFreezesAtEnd = (unsigned int)playbackFreezesAtEnd;
}

- (NSTimeInterval)maxDuration {
    NSTimeInterval maxDuration = -1;
    
    if (CMTIME_IS_NUMERIC(_playerItem.duration)) {
        maxDuration = CMTimeGetSeconds(_playerItem.duration);
    }
    
    return maxDuration;
}

- (void)_setAsset:(AVAsset *)asset
{
    if (_asset == asset)
        return;
    
    _flags.readyForPlayback = NO;

    if (_playbackState == PBJVideoPlayerPlaybackStatePlaying) {
        [self pause];
    }

    _bufferingState = PBJVideoPlayerBufferingStateUnknown;
    _asset = asset;

    if (!_asset) {
        [self _setPlayerItem:nil];
    }
    
    NSArray *keys = @[PBJVideoPlayerControllerTracksKey, PBJVideoPlayerControllerPlayableKey, PBJVideoPlayerControllerDurationKey];
    
    [_asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        [self _enqueueBlockOnMainQueue:^{
        
            // check the keys
            for (NSString *key in keys) {
                NSError *error = nil;
                AVKeyValueStatus keyStatus = [asset statusOfValueForKey:key error:&error];
                if (keyStatus == AVKeyValueStatusFailed) {
                    _playbackState = PBJVideoPlayerPlaybackStateFailed;
                    [_delegate videoPlayerPlaybackStateDidChange:self];
                    return;
                }
            }

            // check playable
            if (!_asset.playable) {
                _playbackState = PBJVideoPlayerPlaybackStateFailed;
                [_delegate videoPlayerPlaybackStateDidChange:self];
                return;
            }

            // setup player
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:_asset];
            [self _setPlayerItem:playerItem];
            
        }];
    }];
}

- (void)_setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem == playerItem)
        return;
    
    // remove observers
    if (_playerItem) {
        // AVPlayerItem KVO
        [_playerItem removeObserver:self forKeyPath:PBJVideoPlayerControllerEmptyBufferKey context:(__bridge void *)(PBJVideoPlayerItemObserverContext)];
        [_playerItem removeObserver:self forKeyPath:PBJVideoPlayerControllerPlayerKeepUpKey context:(__bridge void *)(PBJVideoPlayerItemObserverContext)];
        [_playerItem removeObserver:self forKeyPath:PBJVideoPlayerControllerStatusKey context:(__bridge void *)(PBJVideoPlayerItemObserverContext)];

        // notifications
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:_playerItem];
    }
    
    _playerItem = playerItem;
    
    // add observers
    if (_playerItem) {
        // AVPlayerItem KVO
        [_playerItem addObserver:self forKeyPath:PBJVideoPlayerControllerEmptyBufferKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(PBJVideoPlayerItemObserverContext)];
        [_playerItem addObserver:self forKeyPath:PBJVideoPlayerControllerPlayerKeepUpKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(PBJVideoPlayerItemObserverContext)];
        [_playerItem addObserver:self forKeyPath:PBJVideoPlayerControllerStatusKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(PBJVideoPlayerItemObserverContext)];
        
        // notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:_playerItem];
    }
    
    if (!_flags.playbackLoops) {
        _player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    } else {
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    }

    [_player replaceCurrentItemWithPlayerItem:_playerItem];
}

#pragma mark - init

- (void)dealloc
{
    _videoView.player = nil;
    _delegate = nil;

    // notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Layer KVO
    [_videoView.layer removeObserver:self forKeyPath:PBJVideoPlayerControllerReadyForDisplay context:(__bridge void *)PBJVideoPlayerLayerObserverContext];

    // AVPlayer KVO
    [_player removeObserver:self forKeyPath:PBJVideoPlayerControllerRateKey context:(__bridge void *)PBJVideoPlayerObserverContext];

    // player
    [_player pause];
    
    // player item
    [self _setPlayerItem:nil];
}

#pragma mark - view lifecycle

- (void)loadView
{
    _player = [[AVPlayer alloc] init];
    _player.actionAtItemEnd = AVPlayerActionAtItemEndPause;

    // Player KVO
    [_player addObserver:self forKeyPath:PBJVideoPlayerControllerRateKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(PBJVideoPlayerObserverContext)];

    // load the playerLayer view
    _videoView = [[PBJVideoView alloc] initWithFrame:CGRectZero];
    _videoView.videoFillMode = AVLayerVideoGravityResizeAspect;
    _videoView.playerLayer.hidden = YES;
    self.view = _videoView;

    // playerLayer KVO
    [_videoView.playerLayer addObserver:self forKeyPath:PBJVideoPlayerControllerReadyForDisplay options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(PBJVideoPlayerLayerObserverContext)];
    
    // Application NSNotifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];        
    [nc addObserver:self selector:@selector(_applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [nc addObserver:self selector:@selector(_applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [nc addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_playbackState == PBJVideoPlayerPlaybackStatePlaying)
        [self pause];
}

#pragma mark - private methods

- (void)_videoPlayerAudioSessionActive:(BOOL)active
{
    NSString *category = active ? AVAudioSessionCategoryPlayback : AVAudioSessionCategoryAmbient;
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:category error:&error];
    if (error) {
        DLog(@"audio session active error (%@)", error);
    }
}

- (void)_updatePlayerRatio
{
}

#pragma mark - public methods

- (void)playFromBeginning
{
    DLog(@"playing from beginnging...");
    
    [_delegate videoPlayerPlaybackWillStartFromBeginning:self];
    [_player seekToTime:kCMTimeZero];
    [self playFromCurrentTime];
}

- (void)playFromCurrentTime
{
    DLog(@"playing...");
    
    _playbackState = PBJVideoPlayerPlaybackStatePlaying;
    [_delegate videoPlayerPlaybackStateDidChange:self];
    [_player play];
}

- (void)pause
{
    if (_playbackState != PBJVideoPlayerPlaybackStatePlaying)
        return;
    
    DLog(@"pause");
    
    [_player pause];
    _playbackState = PBJVideoPlayerPlaybackStatePaused;
    [_delegate videoPlayerPlaybackStateDidChange:self];
}

- (void)stop
{
    if (_playbackState == PBJVideoPlayerPlaybackStateStopped)
        return;
    
    DLog(@"stop");

    [_player pause];
    _playbackState = PBJVideoPlayerPlaybackStateStopped;
    [_delegate videoPlayerPlaybackStateDidChange:self];
}

#pragma mark - main queue helper

typedef void (^PBJVideoPlayerBlock)();

- (void)_enqueueBlockOnMainQueue:(PBJVideoPlayerBlock)block {
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

#pragma mark - UIResponder

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_videoPath) {
        
        switch (_playbackState) {
            case PBJVideoPlayerPlaybackStateStopped:
            {
                [self playFromBeginning];
                break;
            }
            case PBJVideoPlayerPlaybackStatePaused:
            {
                [self playFromCurrentTime];
                break;
            }
            case PBJVideoPlayerPlaybackStatePlaying:
            case PBJVideoPlayerPlaybackStateFailed:
            default:
            {
                [self pause];
                break;
            }
        }
        
    } else {
        [super touchesEnded:touches withEvent:event];
    }
    
}

- (void)_handleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (_playbackState == PBJVideoPlayerPlaybackStatePlaying) {
        [self pause];
    } else if (_playbackState == PBJVideoPlayerPlaybackStateStopped) {
        [self playFromBeginning];
    } else {
        [self playFromCurrentTime];
    }
}

#pragma mark - AV NSNotificaions

- (void)_playerItemDidPlayToEndTime:(NSNotification *)aNotification
{
    if (_flags.playbackLoops || !_flags.playbackFreezesAtEnd) {
        [_player seekToTime:kCMTimeZero];
    }
    
    if (!_flags.playbackLoops) {
        [self stop];
        [_delegate videoPlayerPlaybackDidEnd:self];
    }
}

- (void)_playerItemFailedToPlayToEndTime:(NSNotification *)aNotification
{
    _playbackState = PBJVideoPlayerPlaybackStateFailed;
    [_delegate videoPlayerPlaybackStateDidChange:self];
    DLog(@"error (%@)", [[aNotification userInfo] objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey]);
}

#pragma mark - App NSNotifications

- (void)_applicationWillResignActive:(NSNotification *)aNotfication
{
    if (_playbackState == PBJVideoPlayerPlaybackStatePlaying)
        [self pause];
}

- (void)_applicationWillEnterForeground:(NSNotification *)aNotfication
{
}

- (void)_applicationDidEnterBackground:(NSNotification *)aNotfication
{
    if (_playbackState == PBJVideoPlayerPlaybackStatePlaying)
        [self pause];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == (__bridge void *)(PBJVideoPlayerObserverContext) ) {
    
        // Player KVO
    
    } else if ( context == (__bridge void *)(PBJVideoPlayerItemObserverContext) ) {
        
        // PlayerItem KVO
        
        if ([keyPath isEqualToString:PBJVideoPlayerControllerEmptyBufferKey]) {
            if (_playerItem.playbackBufferEmpty) {
                DLog(@"playback buffer is empty");
            }
        } else if ([keyPath isEqualToString:PBJVideoPlayerControllerPlayerKeepUpKey]) {
            if (_playerItem.playbackLikelyToKeepUp) {
                DLog(@"playback buffer is likely to keep up");
                if (_playbackState == PBJVideoPlayerPlaybackStatePlaying) {
                    [self playFromCurrentTime];
                }
            }
        }
        
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerStatusReadyToPlay:
            {
                _videoView.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
                [_videoView.playerLayer setPlayer:_player];
                _videoView.playerLayer.hidden = NO;
                break;
            }
            case AVPlayerStatusFailed:
            {
                _playbackState = PBJVideoPlayerPlaybackStateFailed;
                [_delegate videoPlayerPlaybackStateDidChange:self];
                break;
            }
            case AVPlayerStatusUnknown:
            default:
                break;
        }

    } else if ( context == (__bridge void *)(PBJVideoPlayerLayerObserverContext) ) {
    
        // PlayerLayer KVO
        
        if ([keyPath isEqualToString:PBJVideoPlayerControllerReadyForDisplay]) {
            if (_videoView.playerLayer.readyForDisplay) {
                [_delegate videoPlayerReady:self];
            }
        }
    
    } else {
    
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
    }
}

@end
