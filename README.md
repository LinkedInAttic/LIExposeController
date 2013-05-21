# LIExposeController
LIExposeController is a new navigation paradigm for iOS apps. A great example is [LinkedIn's iPhone app](http://itunes.apple.com/us/app/linkedin/id288429040?mt=8).

LIExposeController acts as a container view controller, much like UINavigationController or UITabBarController. It manages a set of UIViewControllers as separate "stacks" so that users can easily switch between multiple screens.

## Instructions
1. Add LIExposeController.h and LIExposeController.m to your Xcode project.
2. Create an instance like so: <pre><code>exposeController = [[LIExposeController alloc] init];</code></pre>
3. Add your view controllers: <pre><code>exposeController.viewControllers = [NSArray arrayWithObjects:..., nil];</code></pre>
4. Add expose controller to your view hierarchy: <pre><code>window.rootViewController = exposeController;</code></pre>
5. Enjoy!

<!-- MacBuildServer Install Button -->
<div class="macbuildserver-block">
    <a class="macbuildserver-button" href="http://macbuildserver.com/project/github/build/?xcode_project=Demo%2FDemo.xcodeproj&amp;target=Demo&amp;repo_url=https%3A%2F%2Fgithub.com%2Flinkedin%2FLIExposeController&amp;build_conf=Release" target="_blank"><img src="http://com.macbuildserver.github.s3-website-us-east-1.amazonaws.com/button_up.png"/></a><br/><sup><a href="http://macbuildserver.com/github/opensource/" target="_blank">by MacBuildServer</a></sup>
</div>
<!-- MacBuildServer Install Button -->

### Frameworks Required
1. UIKit
2. Foundation
3. QuartzCore
4. CoreGraphics

### Screenshots
![Screen 1 Alt](LIExposeController/raw/master/Screenshots/screen1.png "Screen 1")
![Screen 2 Alt](LIExposeController/raw/master/Screenshots/screen2.png "Screen 2")

## Authors
* Sudeep Yegnashankaran \([LinkedIn](http://www.linkedin.com/in/sudeepy), [github](https://github.com/sudeepy)\)
* Peter Shih \([LinkedIn](http://www.linkedin.com/in/ptshih), [github](https://github.com/ptshih)\)

## License
The source code is available under the Apache 2.0 license.
