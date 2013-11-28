## PBJVideoPlayer
'PBJVideoPlayer' is an iOS video player, which features touch-to-play.

It supports both iOS 6 and iOS 7 as well as 64-bit, and is capable of playing local and remote video files.

Please review the [release history](https://github.com/piemonte/PBJVideoPlayer/releases) for more information.

## Installation

[CocoaPods](http://cocoapods.org) is the recommended method of installing PBJVideoPlayer, just to add the following line to your `Podfile`:

#### Podfile

```ruby
pod 'PBJVideoPlayer'
```

## Usage
```objective-c
#import "PBJVideoPlayerController.h"
```

```objective-c
// allocate controller
_videoPlayerController = [[PBJVideoPlayerController alloc] init];
_videoPlayerController.delegate = self; _videoPlayerController.view.frame = self.view.bounds;

// setup media
_videoPlayerController.videoPath = PBJViewControllerVideoPath;

// present
[self addChildViewController:_videoPlayerController];
[self.view addSubview:_videoPlayerController.view];
[_videoPlayerController didMoveToParentViewController:self];
```

## License

'PBJVideoPlayer' is available under the MIT license, see the LICENSE file for more information.
