import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

typedef void TimeChangeHandler(Duration time);
typedef void StringChangeHandler(String value);

enum PlayMode {
  PLAY_MODEL_SINGLE,
  PLAY_MODEL_SINGLE_LOOP,
  PLAY_MODEL_LIST,
  PLAY_MODEL_LIST_LOOP,
  PLAY_MODEL_RANDOM
}

class Fluxmly {
  static final MethodChannel _channel = const MethodChannel('fluxmly');
  StreamSubscription<dynamic> _streamSubscription;
  TimeChangeHandler durationHandler;
  TimeChangeHandler positionHandler;
  StringChangeHandler playerHandler;

  Fluxmly() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  void setDurationHandler(TimeChangeHandler handler) {
    durationHandler = handler;
  }

  void setPositionHandler(TimeChangeHandler handler) {
    positionHandler = handler;
  }

  void setPlayerHandler(StringChangeHandler handler){
    playerHandler = handler;
  }

  static Future<int> init(
      String appKey, String appSecret, String packId) async {
    final int res = await _channel.invokeMethod(
        "init", {"appKey": appKey, "appSecret": appSecret, "packId": packId});
    return res;
  }

  //猜你喜欢
  static Future<String> getGuessLikeAlbum(int count) async {
    final String res =
        await _channel.invokeMethod("getGuessLikeAlbum", {"count": count});
    return res;
  }

  //获取专辑列表
  static Future<String> getTracks(int albumID, String sort, int page) async {
    final String res = await _channel.invokeMethod(
        "getTracks", {"albumID": albumID, "sort": sort, "page": page});
    return res;
  }

  Future playTrack(List trackList, int index) async {
    final String res=await _channel
        .invokeMethod("playTrack", {"trackList": trackList, "index": index});
    return res;
  }

  Future<int> play({int index}) async {
    final res = await _channel.invokeMethod("play", {"index": index ?? 0});
    return res;
  }

  Future<int> pause() async {
    final int res = await _channel.invokeMethod("pause");
    return res;
  }

  Future<int> stop() async{
    final int res = await _channel.invokeMethod("stop");
    return res;
  }

  Future playPre() async {
    final int res = await _channel.invokeMethod("playPre");
    return res;
  }

  Future playNext() async {
    final int res = await _channel.invokeMethod("playNext");
    return res;
  }

  static Future<int> getDuration() {
    final Future<int> res = _channel.invokeMethod("getDuration");
    return res;
  }

  static Future<int> getPlayCurrPositon() async {
    final Future<int> res = await _channel.invokeMethod("getPlayCurrPositon");
    return res;
  }

  Future<int> seek(int position) {
    _channel.invokeMethod("seekTo", {"pos": position});
  }

  Future setPlayMode(int index) async {
    final res =
        await _channel.invokeMethod("setPlayMode", {"playModeIndex": index});
    return res;
  }

  Future<void> dispose() async {
    // First stop and release all native resources.
    _channel.setMethodCallHandler(null);
    await _channel.invokeMethod("release");
  }

  //获取详情
  Future trackRichInfo(String trackID) async {
    final res =
        await _channel.invokeMethod("trackRichInfo", {"trackID": trackID});
    return res;
  }

  Future platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onPosition':
        Map<String, dynamic> res = json.decode(call.arguments);
        int _pos = res['currPos'];
        int _dur = res['duration'];
        if (positionHandler != null) {
          positionHandler(new Duration(milliseconds: _pos));
        } else {
          print("positionHandler为空");
        }
        if (durationHandler != null) {

          durationHandler(new Duration(milliseconds: _dur));
        }
        break;
      case 'completePlay':
        Map<String, dynamic> res = json.decode(call.arguments);
        String status = res['status'];

        if(playerHandler!= null){
          playerHandler(status);
        }else{
          print("playerHandler为空");
        }
        break;
      default:
        print('Unknowm method ${call.method} ');
    }
  }
}
