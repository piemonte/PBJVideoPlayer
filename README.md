![PBJVideoPlayer](https://raw.github.com/piemonte/PBJVideoPlayer/master/PBJVideoPlayer.gif)

## PBJVideoPlayer
`PBJVideoPlayer` is a simple video player library for iOS and tvOS.

[![Build Status](https://travis-ci.org/piemonte/PBJVideoPlayer.svg)](https://travis-ci.org/piemonte/PBJVideoPlayer)
[![Pod Version](https://img.shields.io/cocoapods/v/PBJVideoPlayer.svg?style=flat)](http://cocoadocs.org/docsets/PBJVideoPlayer/)

- Looking for a Swift video player? Check out [Player (Swift)](https://github.com/piemonte/Player).
- Looking for a Swift camera library? Check out [Next Level](https://github.com/NextLevel/NextLevel).

### Features
- [x] plays local media or streams remote media over HTTP
- [x] customizable UI and user interaction
- [x] no size restrictions
- [x] orientation change support
- [x] simple API

## Quick Start

[CocoaPods](http://cocoapods.org) is the recommended method of installing PBJVideoPlayer, just add the following line to your `Podfile`:

```ruby
pod 'PBJVideoPlayer'
```

## Usage
```objective-c
#import <PBJVideoPlayer/PBJVideoPlayer.h>
```

```objective-c
// allocate controller
PBJVideoPlayerController *videoPlayerController = [[PBJVideoPlayerController alloc] init];
videoPlayerController.delegate = self;
videoPlayerController.view.frame = self.view.bounds;

// setup media
videoPlayerController.videoPath = @"https://example.com/video.mp4";

// present
[self addChildViewController:videoPlayerController];
[self.view addSubview:videoPlayerController.view];
[videoPlayerController didMoveToParentViewController:self];
```

## Community

- Need help? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/pbjvideoplayer) with the tag 'pbjvideoplayer'.
- Questions? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/pbjvideoplayer) with the tag 'pbjvideoplayer'.
- Found a bug? Open an [issue](https://github.com/piemonte/PBJVideoPlayer/issues).
- Feature idea? Open an [issue](https://github.com/piemonte/PBJVideoPlayer/issues).
- Want to contribute? Submit a [pull request](https://github.com/piemonte/PBJVideoPlayer/pulls).

## Resources

* [AV Foundation Programming Guide](https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
* [PBJVision](https://github.com/piemonte/PBJVision), iOS camera engine, features touch-to-record video, slow motion video, and photo capture
* [Player](https://github.com/piemonte/player), a simple iOS video player in Swift

## License

PBJVideoPlayer is available under the MIT license, see the [LICENSE](https://github.com/piemonte/PBJVideoPlayer/blob/master/LICENSE) file for more information.
