# AFNetworking-AutoRetry
An iOS category adding retry functionality to requests made using AFNetworking 2

## Installation with CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like AFNetworking in your projects. See the ["Getting Started" guide for more information](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking). You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate AFNetworking-AutoRetry into your Xcode project using CocoaPods, specify it in your `Podfile`:

    pod 'AFNetworking+AutoRetry'

Then, run the following command:

    pod install

## Usage
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
If you encounter any questions or issues, please use the tag `afnetworking-autoretry` to ask in [Stack Overflow](http://stackoverflow.com). If you think you found a bug, please report it at [Issues](https://github.com/shaioz/AFNetworking-AutoRetry/issues).

##Credits
AFNetworking is owned and maintained by the [Alamofire Software Foundation](http://alamofire.org/).
AFNetworking-AutoRetry is created by [Shai Ohev Zion](https://github.com/shaioz) and now maintained by [Shivan Raptor](https://github.com/shivanraptor) and [Daniel Jankovič](https://github.com/jold).
