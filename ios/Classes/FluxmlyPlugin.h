#import <Flutter/Flutter.h>
#import "XMSDK.h"

@interface FluxmlyPlugin : NSObject<FlutterPlugin,XMReqDelegate,XMTrackPlayerDelegate,FlutterStreamHandler>

@property (nonatomic,strong)XMTrack *track;
@property (nonatomic,strong)NSArray *trackList;
@end
