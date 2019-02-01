//
//  DVMediator.m
//  DVMediator
//
//  Created by David on 2019/1/31.
//  Copyright © 2019年 ADIOS. All rights reserved.
//

#import "DVMediator.h"

@interface DVMediator()

@property (nonatomic,strong) NSMutableDictionary *modulesContainer; ///< module的容器

@end

@implementation DVMediator

static DVMediator *_mediator = nil;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_mediator){
            _mediator = [[DVMediator alloc]init];
        }
    });
    return _mediator;
}

- (id)openURL:(NSURL *)url complition:(void (^)(id _Nullable))complition
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *queryURL = [url query];
    for (NSString *param in [queryURL componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        NSString *key = elts.firstObject;
        if (key) [params setObject:elts.lastObject forKey:key];
    }
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    
    id result = [self performModuleWithName:url.host actionName:actionName params:params shouldCache:NO];
    if (complition){
        if (result){
            complition(result);
        } else {
            complition(nil);
        }
    }
    return result;
}


- (id)performModuleWithName:(NSString *)name actionName:(NSString *)action params:(NSDictionary *)params shouldCache:(BOOL)shouldCache
{
    //1.根据ModuleName 解析出Target的类名 2.是否贮存,如果贮存则存储  3.是否相应,如果相应的话，则进行方法的调用 4.如果不相应,则进入notFound方法进行调用。
    NSString *className = nil;
    if (name.length > 0){
        className = [NSString stringWithFormat:@"Target_%@",name];
    }
    id target = self.modulesContainer[className];
    if (!target){
        Class moduleClass = NSClassFromString(className);
        target = [[moduleClass alloc] init];
    }
    if (shouldCache){
        self.modulesContainer[className] = target;
    }
    NSString *selectorName = nil;
    if (action.length >0){
        selectorName = [NSString stringWithFormat:@"Action_%@",action];
    }
    SEL actionSEL =  NSSelectorFromString(selectorName);
    if (!target){
        [self noTarget:className action:action originParams:params];
        [self.modulesContainer removeObjectForKey:className];
        return nil;
    }
    
    if ([target respondsToSelector:actionSEL]){
       return [self _performSafeTarget:target action:actionSEL params:params];
    } else {
        SEL action1 = NSSelectorFromString(@"selectorNotFount");
        if ([target respondsToSelector:action1]){
            return [self _performSafeTarget:target action:action1 params:params];
        } else {
            [self noTarget:className action:action originParams:params];
            [self.modulesContainer removeObjectForKey:className];
            return nil;
        }
    }
}

- (void)removeModuleWithName:(NSString *)moduleName
{
    NSParameterAssert(moduleName);
    if (moduleName.length == 0) return;
    NSString *targetName = [NSString stringWithFormat:@"Target_%@",moduleName];
    [self.modulesContainer removeObjectForKey:targetName];
}


// 执行无数据的相应
- (void)noTarget:(NSString *)targetStr action:(NSString *)actionStr originParams:(NSDictionary *)originParams
{
    SEL action  = NSSelectorFromString(@"Action_response:");
    NSObject *target = [[NSClassFromString(@"Target_NoTargetAction") alloc] init];
    
    NSMutableDictionary *params = @{}.mutableCopy;
    params[@"originParams"] = originParams;
    params[@"targetString"] = targetStr;
    params[@"selectorString"] = actionStr;
    
    [self _performSafeTarget:target action:action params:params];
}



- (id)_performSafeTarget:(id)target action:(SEL)action params:(NSDictionary *)params
{
   // 0.根据action获取Signature  1.构建invocation  2.根据返回值类型包装返回不一样的数据
    NSMethodSignature *methodSignature = [NSMethodSignature methodSignatureForSelector:action];
    if (!methodSignature) {
        return nil;
    }
    const char *returnType = [methodSignature methodReturnType];
    // 比较C语言字符串
    if (strcmp(returnType, @encode(CGFloat)) == 0){
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.target = self;
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation invoke];
        CGFloat result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
    // 如果无参的话
    if (strcmp(returnType, @encode(void)) == 0){
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.target = self;
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation invoke];
        return nil;
    }
    
    if (strcmp(returnType, @encode(NSInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
    if (strcmp(returnType, @encode(NSUInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSUInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
    if (strcmp(returnType, @encode(BOOL)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        BOOL result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
}




- (NSMutableDictionary *)modulesContainer
{
    if (!_modulesContainer){
        _modulesContainer = [NSMutableDictionary dictionary];
    }
    return _modulesContainer;
}

@end
