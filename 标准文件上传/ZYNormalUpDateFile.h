//
//  ZYNormalUpDateFile.h
//  标准文件上传
//
//  Created by Zy on 2018/11/29.
//  Copyright © 2018 360. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ModelPresenterCallback)(NSDictionary*response);
@interface ZYNormalUpDateFile : NSObject
- (void)uploadRequset:(NSDictionary *)info url:(NSString *)url completed:(ModelPresenterCallback)callback;
@end

NS_ASSUME_NONNULL_END
