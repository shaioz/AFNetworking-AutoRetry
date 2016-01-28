# AFNetworking-AutoRetry
An iOS category adding retry functionality to requests made using AFNetworking 3. This category also supports AFNetworking 2 (see instructions below).

## Installation with CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like AFNetworking in your projects. See the ["Getting Started" guide for more information](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking). You can install it with the following command:

```bash
$ gem install cocoapods
```

Note: Installing AFNetworking 3 and this category requrie Cocoapods 0.39.0+

To integrate AFNetworking-AutoRetry into your Xcode project using CocoaPods, specify it in your `Podfile`:

    pod 'AFNetworking', '~> 3.0'
    pod 'AFNetworking+AutoRetry', '~> 3.0'
    
If you use this category with AFNetworking 2.x, please specify version 2 using the following line instead:

    pod 'AFNetworking', '~> 2.0'
    pod 'AFNetworking+AutoRetry', '~> 2.2.4'

Then, run the following command:

    pod install

## Usage (AFNetworking 3)
Import the libraries at the top of your .m file

```objective-c
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking+AutoRetry/AFHTTPSessionManager+AutoRetry.h>
```

Then, in your function, 

```objective-c
// setup POST data
NSDictionary *parameters = @{@"key":@"value"};
AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
// set the network timeout duration to 30 seconds
manager.requestSerializer = [[AFHTTPRequestSerializerWithTimeout alloc] initWithTimeout:30];
[manager POST:@"http://www.example.com/api" progress:^(NSProgress * _Nonnull downloadProgress) {
    // progress can be obtained here
} parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
    // success, parse the response here
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    // failure, e.g. network error
} autoRetry:3];
```
where 3 is the number of retries. Similar for GET cases.

## Usage (AFNetworking 2)
Import the libraries at the top of your .m file

```objective-c
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AFNetworking+AutoRetry/AFHTTPRequestOperationManager+AutoRetry.h>
```

Then, in your function:

```objective-c
// setup POST data
NSDictionary *parameters = @{@"key":@"value"};
AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
// set the network timeout duration to 30 seconds
manager.requestSerializer = [[AFHTTPRequestSerializerWithTimeout alloc] initWithTimeout:30];
[manager POST:@"http://www.example.com/api" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
    // success, parse the response here
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    // failure, e.g. network error
} autoRetry:3];
```
where 3 is the number of retries. Similar for GET cases.

##Communication
If you encounter any questions or issues, please use the tag `afnetworking-autoretry` to ask in [Stack Overflow](http://stackoverflow.com); Be sure to specify which version you're using. If you think you found a bug, please report it at [Issues](https://github.com/shaioz/AFNetworking-AutoRetry/issues).

##Credits
AFNetworking is owned and maintained by the [Alamofire Software Foundation](http://alamofire.org/).
AFNetworking-AutoRetry is created by [Shai Ohev Zion](https://github.com/shaioz) and now maintained by [Shivan Raptor](https://github.com/shivanraptor) and [Daniel Jankovič](https://github.com/jold).
