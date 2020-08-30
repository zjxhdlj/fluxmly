#import "FluxmlyPlugin.h"
#import "XMSDK.h"
#import "XMReqMgr.h"
#import "XMSDKPlayer.h"
#import <AVFoundation/AVFoundation.h>
__weak FluxmlyPlugin* __fluxmlyPlagin;

@interface FluxmlyPlugin(){
    XMSDKPlayer *_sdkPlayer;
    FlutterMethodChannel* _channel;
}

@end

@implementation FluxmlyPlugin


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"fluxmly"
            binaryMessenger:[registrar messenger]];
    FluxmlyPlugin *instance = [[FluxmlyPlugin alloc] initWithRegister:registrar methodChannel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (instancetype)initWithRegister:(NSObject <FlutterPluginRegistrar> *)registrar methodChannel:(FlutterMethodChannel *)flutterMethodChannel {
    _channel = flutterMethodChannel;
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if([@"init" isEqualToString:call.method]){
      //初始化
      NSString *appKey = call.arguments[@"appKey"];
      NSString *appSerect = call.arguments[@"appSecret"];
      [[XMReqMgr sharedInstance] registerXMReqInfoWithKey:appKey appSecret:appSerect];
      [XMReqMgr sharedInstance].delegate = self;
      result(@1);
  }else if([@"getGuessLikeAlbum" isEqualToString:call.method]){
      //获取猜你喜欢
      [self getGuessLikeAlbum:call result:result];
  }else if([@"getTracks" isEqualToString:call.method]){
      //获取专辑详情
      [self getTracks:call result:result];
  }else if([@"trackRichInfo" isEqualToString:call.method]){
      [self trackRichInfo:call result:result];
  }else if([@"playTrack" isEqualToString:call.method]){
      NSArray *trackList = call.arguments[@"trackList"];
      self.trackList = trackList;
      _sdkPlayer = [XMSDKPlayer sharedPlayer];
      [_sdkPlayer setAutoNexTrack:YES];
      _sdkPlayer.trackPlayDelegate = self;
  }else if([@"release" isEqualToString:call.method]){
      [XMSDKPlayer sharedPlayer].trackPlayDelegate = nil;
      [[XMReqMgr sharedInstance] closeXMReqMgr];
  }else if([@"play" isEqualToString:call.method]){
      NSMutableArray *models = [NSMutableArray array];
      Class dataClass = NSClassFromString(@"XMTrack");
      NSNumber *index = call.arguments[@"index"];
      NSInteger integer = [index integerValue];
      NSArray *trackList = self.trackList;
      if(self.trackList.count){
          
          [[XMSDKPlayer sharedPlayer] setPlayMode:XMSDKPlayModeTrack];
          [XMSDKPlayer sharedPlayer].usingResumeFromStart=YES;
          if([trackList isKindOfClass:[NSArray class]]){
              for (NSDictionary *dic in trackList) {
                  id model = [[dataClass alloc] initWithDictionary:dic];
                  [models addObject:model];
              }
          }
          [[XMSDKPlayer sharedPlayer] playWithTrack:models[integer] playlist:models];
          [[XMSDKPlayer sharedPlayer] setAutoNexTrack:YES];
          result(@1);
      }
  }else if([@"pause" isEqualToString:call.method]){
      [[XMSDKPlayer sharedPlayer] pauseTrackPlay];
      result(@1);
  }else if([@"stop" isEqualToString:call.method]){
      [[XMSDKPlayer sharedPlayer] stopTrackPlay];
      result(@1);
  }else if([@"playPre" isEqualToString:call.method]){
      [[XMSDKPlayer sharedPlayer] playPrevTrack];
      [[XMSDKPlayer sharedPlayer] pauseTrackPlay];
      result(@1);
  }else if([@"playNext" isEqualToString:call.method]){
      [[XMSDKPlayer sharedPlayer] playNextTrack];
      [[XMSDKPlayer sharedPlayer] pauseTrackPlay];
      result(@1);
  }else if([@"setPlayMode" isEqualToString:call.method]){
      NSNumber *index = call.arguments[@"playModeIndex"];
      NSInteger mode = [index integerValue];
      if(mode == 1){
          [[XMSDKPlayer sharedPlayer] setTrackPlayMode:XMTrackPlayerModeList];
          NSLog(@"playMode: %ld",[[XMSDKPlayer sharedPlayer] getTrackPlayMode]);
      }else{
          [[XMSDKPlayer sharedPlayer] setTrackPlayMode:XMTrackModeSingle];
          NSLog(@"playMode: %ld",[[XMSDKPlayer sharedPlayer] getTrackPlayMode]);
      }
      result(@1);
  }else if([@"seekTo" isEqualToString:call.method]){
      NSNumber *pos = call.arguments[@"pos"];
      float value = [pos floatValue];
      
      NSInteger second = value/1000;
      
      
      
      [[XMSDKPlayer sharedPlayer] seekToTime:second];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

-(void)trackRichInfo:(FlutterMethodCall *)call result:(FlutterResult)result{
    //获取参数count
    NSString *trackID = call.arguments[@"trackID"];
    //组装请求参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:trackID forKey:@"track_id"];
    
    [[XMReqMgr sharedInstance] requestXMDataWithPath:@"/tracks/get_single" params:params completionHandler:^(id resultData, XMErrorModel *error) {
        if(!error){
            BOOL isValid = [NSJSONSerialization isValidJSONObject:resultData];
            if(isValid){
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultData options:0 error:NULL];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                result(jsonString);
            }
        }else{
            NSLog(@"%@,%@",error.description,result);
        }
    }];
}


-(void)getGuessLikeAlbum:(FlutterMethodCall *)call result:(FlutterResult)result{
    //获取参数count
    NSNumber *count = call.arguments[@"count"];
    //组装请求参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:count forKey:@"like_count"];
    
    [[XMReqMgr sharedInstance] requestXMData:XMReqType_AlbumsGuessLike params:params withCompletionHander:^(id resultData, XMErrorModel *error) {
        if(!error){
            BOOL isValid =[NSJSONSerialization isValidJSONObject:resultData];
            if(isValid){
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultData options:0 error:NULL];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                result(jsonString);
            }
            
        }else{
            NSLog(@"getGuessLikeAlbum Error: error_no:%ld, error_code:%@, error_desc:%@",(long)error.error_no, error.error_code, error.error_desc);
        }
    }];
}

-(void)getTracks:(FlutterMethodCall *)call result:(FlutterResult)result{
    //获取参数count
    NSNumber *albumID = call.arguments[@"albumID"];
    NSString *sort = call.arguments[@"sort"];
    NSNumber *page = call.arguments[@"page"];
    //组装请求参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:albumID forKey:@"album_id"];
    [params setObject:sort forKey:@"sort"];
    [params setObject:page forKey:@"page"];
    
    [[XMReqMgr sharedInstance] requestXMData:XMReqType_AlbumsBrowse params:params withCompletionHander:^(id resultData, XMErrorModel *error) {
        if(!error){
            BOOL isValid =[NSJSONSerialization isValidJSONObject:resultData];
            if(isValid){
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultData options:0 error:NULL];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                result(jsonString);
            }
            
        }else{
            NSLog(@"%@ %@",error.description,result);
        }
    }];
}

- (void)didXMInitReqFail:(XMErrorModel *)respModel {
    NSLog(@"init failed! error_no:%ld, error_code:%@, error_desc:%@", (long)respModel.error_no, respModel.error_code, respModel.error_desc);
}

- (void)didXMInitReqOK:(BOOL)result {
    NSLog(@"init ok");
}

- (void)XMTrackPlayNotifyProcess:(CGFloat)percent currentSecond:(NSUInteger)currentSecond
{
//    NSLog(@"percent: %f, second: %lu", percent, (unsigned long)currentSecond);
    NSInteger _duration = ceil(currentSecond/percent)*1000;
    NSNumber *duration = [NSNumber numberWithDouble:_duration];
    NSNumber *currPos = [NSNumber numberWithInteger:currentSecond*1000];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:duration forKey:@"duration"];
    [params setValue:currPos forKey:@"currPos"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    [_channel invokeMethod:@"onPosition" arguments:jsonString];
}

- (void)XMTrackPlayNotifyCacheProcess:(CGFloat)percent
{
//    NSLog(@"cacheProgress:%f",percent);
}

//- (void)player:(XMPlayer *)player notifyCacheProcess:(CGFloat)percent
//{
//    //_progressPane.processBar.cacheValue = percent;
//}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)XMTrackPlayerDidEnd
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"1" forKey:@"status"];
    [params setValue:@"1" forKey:@"extra"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [_channel invokeMethod:@"completePlay" arguments:jsonString];
    
}

- (void)XMTrackPlayerDidStart
{
    
    
//    NSLog(@"volume didstart---%f", [XMPlayer sharedPlayer].volume);
//    NSLog(@"sdkplayervolume didstart---%f", [XMSDKPlayer sharedPlayer].sdkPlayerVolume);
    NSLog(@"playstate play %ld", (long)[[XMSDKPlayer sharedPlayer] playerState]);

}

- (void)XMTrackPlayerWillPlaying
{
    NSLog(@"playstate will playing %ld", (long)[[XMSDKPlayer sharedPlayer] playerState]);
}

- (void)XMTrackPlayerDidPlaying
{
    
    NSLog(@"current:%@",_sdkPlayer.currentTrack.trackTitle);
    
    NSLog(@"playstate did playing %ld", (long)[[XMSDKPlayer sharedPlayer] playerState]);
}

- (void)XMTrackPlayerDidPaused
{
    NSLog(@"playstate pause %ld", (long)[[XMSDKPlayer sharedPlayer] playerState]);
}

- (void)XMTrackPlayerDidStopped
{
    NSLog(@"playstate stop %ld", (long)[XMSDKPlayer sharedPlayer].playerState);
}

- (void)XMTrackPlayerDidFailedToPlayTrack:(XMTrack *)track withError:(NSError *)error;
{
    NSLog(@"Play track failed due to error:%ld, %@, %@", (long)error.code, error.domain, error.userInfo[NSLocalizedDescriptionKey]);
}

- (BOOL)XMTrackPlayerShouldContinueNextTrackWhenFailed:(XMTrack *)track
{
    return NO;
}

- (void)XMTrackPlayerDidErrorWithType:(NSString *)type withData:(NSDictionary*)data
{
    NSLog(@"player did error with type:%@,\n%@", type, data);
}

- (void)XMTrackPlayerDidPausePlayForBadNetwork
{
    NSLog(@"XMTrackPlayerDidPausePlayForBadNetwork:%@", @(_sdkPlayer.playerState));
}



@end
