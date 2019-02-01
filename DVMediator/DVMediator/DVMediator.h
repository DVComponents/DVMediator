//
//  DVMediator.h
//  DVMediator
//
//  Created by David on 2019/1/31.
//  Copyright © 2019年 ADIOS. All rights reserved.
//  参考casa 学习他的思想。具体CT详见https://github.com/casatwy/CTMediator

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVMediator : NSObject

+ (instancetype)shareInstance;

// 远程URL开启
- (id)openURL:(NSURL *)url complition:(void (^)(_Nullable id result))complition;
// 本地Module调用
- (id)performModuleWithName:(NSString *)name actionName:(NSString *)action params:(NSDictionary *)params shouldCache:(BOOL)shouldCache;
// 移除module根据名字
- (void)removeModuleWithName:(NSString *)moduleName;

@end

NS_ASSUME_NONNULL_END
