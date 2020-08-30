//
//  XMReqMgr.h
//  XMOpenPlatform
//
//  Created by nali on 15/8/24.
//
//

#import <Foundation/Foundation.h>
#import "XMSDKInfo.h"
#import "XMErrorModel.h"


typedef void (^XMRequestHandler)(id result,XMErrorModel *error);

//------------------------------------------------------------------------------------

#pragma mark - XMReqDelegate

@protocol XMReqDelegate <NSObject>

/* 初始化请求成功 */
-(void)didXMInitReqOK:(BOOL)result;

/* 初始化请求失败 */
-(void)didXMInitReqFail:(XMErrorModel *)respModel;

@optional

/* accessToken过期 */
/* 若接入付费接口，必须实现此代理方法，并在此方法中刷新accessToken。此处的accessToken指的是XMLYAuthorize中登录成功后获取的授权登录token。 */
- (void)didXMAuthAccessTokenExpired;

/* 付费内容播放失败/下载失败/下单失败 */
- (void)didXMOpenPayFailWithError:(XMErrorModel *)error;

/* 付费内容支付成功 */
- (void)didXMPurchaseSucceed;

/* 付费内容支付失败 */
- (void)didXMPurchaseFailWithError:(XMErrorModel *)error;

/* 购买支付页面已显示 */
- (void)didXMPurchaseViewAppear;

/* 用户退出购买支付页面 */
- (void)didXMPurchaseViewBackByUser;

@end

//------------------------------------------------------------------------------------

#pragma mark - XMReqMgr

@interface XMReqMgr : NSObject

@property (nonatomic,strong) NSString *proxyHost;  //http 代理 host
@property (nonatomic,assign) NSInteger proxyPort;  //http 代理 port
@property (nonatomic,strong) NSString *proxyUsername;  //http 代理 认证用户
@property (nonatomic,strong) NSString *proxyPassword;  //http 代理 认证密码

@property (nonatomic,assign) BOOL usingSynPost;
@property (nonatomic,strong) NSString *appkey;
@property (nonatomic,strong) NSString *appSecret;

/** 1代表强制使用https，2代表强制使用http，其他值则不进行处理
    如果需要用到广播，则必须支持http请求
*/
@property (nonatomic,assign) NSUInteger usingHttpWhenRequestApiDomain;

@property (nonatomic, assign) BOOL enableDeviceIdHashMode;

@property (nonatomic, copy) NSString  *deviceInfo; //!< sdk所使用的设备信息

@property (nonatomic, assign) BOOL isAuthLoggedOut; //!<  授权登录已退出，如设置为YES则不再触发代理方法didXMAuthAccessTokenExpired

+ (XMReqMgr *)sharedInstance;

+ (NSString *)version;

@property (nonatomic,weak) id<XMReqDelegate> delegate;

/**
 *  生成或更新动态口令（如没有则生成、有则更新）
 *
 *  @param appKey 必填，开放平台应用唯一Key
 *
 *  @param appSecret     必填，APP的私钥，用于生产sig签名
 */
- (void)registerXMReqInfoWithKey:(NSString *)appKey appSecret:(NSString *)appSecret;

/**
 *  请求喜马拉雅的内容
 *
 *  @param reqType 必填，请求类型
 *
 *  @param params  必填，请求参数字典
 *
 *  @param reqHandler 必填，请求完成后的回调block
 */
- (void)requestXMData:(XMReqType)reqType params:(NSDictionary*)params withCompletionHander:(XMRequestHandler)reqHandler;

/**
*  请求喜马拉雅的内容扩展接口 - 在请求类型不包含所需请求的接口时使用
*
*  @param path    必填，请求路径，例如@"business/category"
*
*  @param params  必填，请求参数字典
*
*  @param reqHandler 必填，请求完成后的回调block
*/
- (void)requestXMDataWithPath:(NSString *)path params:(NSDictionary*)params completionHandler:(XMRequestHandler)reqHandler;

- (void)postDataToXMSvr:(NSInteger)reqType params:(NSDictionary*)params withCompletionHander:(XMRequestHandler)reqHandler;

/**
 *  请在 AppDelegate的 - (void)applicationWillTerminate:(UIApplication *)application 中调用
 *
 */
- (void)closeXMReqMgr;



//--------------------------------付费相关----------------------------------------------------
#pragma mark - 付费相关

/**
 * 将授权成功获得的token同步到XMReqMgr
 */
- (void)updateAuthTokenToXMReqMgr:(NSString *)authToken;

/**
 *  请求付费相关接口
 *
 *  @param reqType 必填，请求类型
 *  @param params  必填，请求参数字典
 *  @param reqHandler 必填，请求完成后的回调block
 *
 *  @param accessToken 必填，此处的accessToken指的是XMLYAuthorize中登录成功后获取的授权登录token
 */
- (void)requestXMAuthData:(XMReqType)reqType withAuthToken:(NSString *)accessToken params:(NSDictionary*)params withCompletionHander:(XMRequestHandler)reqHandler;

/**
 *  下单接口
 *
 *  @param params  必填，请求参数字典
 *  @param reqHandler 必填，请求完成后的回调block
 *
 */
- (void)postOrderWithParams:(NSDictionary *)params withCompletionHander:(XMRequestHandler)reqHandler;

/**
 *  取消订单接口
 *
 *  @param params  必填，请求参数字典
 *  @param reqHandler 必填，请求完成后的回调block
 *
 */
- (void)cancelOrderWithParams:(NSDictionary *)params withCompletionHandler:(XMRequestHandler)reqHandler;

/**
 *  取消所有现存订单
 */
- (void)cancelAllPendingOrders;

/**
 *  现存订单数组
 */
- (NSArray *)getAllPendingOrdersArray;

/**
 *  删除所有现存订单，为防止某些情况下订单已失效仍存在于沙盒中，一般情况下不需使用
 */
- (void)deleteAllPendingOrdersArray;


@end
