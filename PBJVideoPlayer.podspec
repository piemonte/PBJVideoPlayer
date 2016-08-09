Pod::Spec.new do |s|
  s.name = 'PBJVideoPlayer'
  s.version = '0.3.3'
  s.summary = 'simple video player library for iOS and tvOS, featuring touch-to-play'
  s.homepage = 'https://github.com/piemonte/PBJVideoPlayer'
  s.social_media_url = 'http://twitter.com/piemonte'
  s.license = 'MIT'
  s.authors = { 'patrick piemonte' => 'piemonte@alumni.cmu.edu' }
  s.source = { :git => "https://github.com/piemonte/PBJVideoPlayer.git", :tag => s.version }
  s.frameworks = 'Foundation', 'AVFoundation', 'CoreGraphics', 'QuartzCore', 'UIKit'
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.source_files = 'Source'
  s.requires_arc = true
  s.screenshot = "https://raw.github.com/piemonte/PBJVideoPlayer/master/PBJVideoPlayer.gif"
end
