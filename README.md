![PBJVideoPlayer](https://raw.github.com/piemonte/PBJVideoPlayer/master/PBJVideoPlayer.gif)

## PBJVideoPlayer
`PBJVideoPlayer` is a simple iOS video player library.

### Features
- [x] plays local media or streams remote media over HTTP
- [x] customizable UI and user interaction
- [x] no size restrictions
- [x] orientation change support
- [x] simple API

If you're looking for a video player written in [Swift](https://developer.apple.com/swift/), checkout [Player](https://github.com/piemonte/player). For video recording, checkout [PBJVision](https://github.com/piemonte/PBJVision).

[![Build Status](https://travis-ci.org/piemonte/PBJVideoPlayer.svg)](https://travis-ci.org/piemonte/PBJVideoPlayer)
[![Pod Version](https://img.shields.io/cocoapods/v/PBJVideoPlayer.svg?style=flat)](http://cocoadocs.org/docsets/PBJVideoPlayer/)

## Installation

[CocoaPods](http://cocoapods.org) is the recommended method of installing PBJVideoPlayer, just to add the following line to your `Podfile`:

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
_videoPlayerController.delegate = self;
_videoPlayerController.view.frame = self.view.bounds;

// setup media
_videoPlayerController.videoPath = PBJViewControllerVideoPath;

// present
[self addChildViewController:_videoPlayerController];
[self.view addSubview:_videoPlayerController.view];
[_videoPlayerController didMoveToParentViewController:self];
```

## Community

- Need help? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/pbjvideoplayer) with the tag 'pbjvideoplayer'.
- Questions? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/pbjvideoplayer) with the tag 'pbjvideoplayer'.
- Found a bug? Open an [issue](https://github.com/piemonte/PBJVideoPlayer/issues).
- Feature idea? Open an [issue](https://github.com/piemonte/PBJVideoPlayer/issues).
- Want to contribute? Submit a [pull request](https://github.com/piemonte/PBJVideoPlayer/pulls).

## Resources

* [AV Foundation Programming Guide](https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
* [PBJVision, iOS camera engine, features touch-to-record video, slow motion video, and photo capture](https://github.com/piemonte/PBJVision)
* [Player, a simple iOS video player in Swift](https://github.com/piemonte/player)

## License

PBJVideoPlayer is available under the MIT license, see the [LICENSE](https://github.com/piemonte/PBJVideoPlayer/blob/master/LICENSE) file for more information.
