package com.virus.fluxmly;
import android.nfc.Tag;

import io.flutter.Log;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.ximalaya.ting.android.opensdk.auth.constants.XmlyConstants;
import com.ximalaya.ting.android.opensdk.constants.ConstantsOpenSdk;
import com.ximalaya.ting.android.opensdk.constants.DTransferConstants;
import com.ximalaya.ting.android.opensdk.datatrasfer.CommonRequest;
import com.ximalaya.ting.android.opensdk.model.album.GussLikeAlbumList;
import com.ximalaya.ting.android.opensdk.model.track.Track;
import com.ximalaya.ting.android.opensdk.model.track.TrackList;
import com.ximalaya.ting.android.opensdk.model.column.ColumnDetail;
import com.ximalaya.ting.android.opensdk.model.column.ColumnDetailAlbum;
import com.ximalaya.ting.android.opensdk.model.column.ColumnDetailTrack;
import com.ximalaya.ting.android.opensdk.datatrasfer.IDataCallBack;
import com.ximalaya.ting.android.opensdk.model.PlayableModel;
import com.ximalaya.ting.android.opensdk.player.XmPlayerManager;
import com.ximalaya.ting.android.opensdk.player.service.IXmPlayerStatusListener;
import com.ximalaya.ting.android.opensdk.player.service.XmPlayListControl;
import com.ximalaya.ting.android.opensdk.player.service.XmPlayerException;
import com.google.gson.reflect.TypeToken;
import com.ximalaya.ting.android.opensdk.httputil.BaseResponse;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.lang.reflect.Type;

import com.google.gson.Gson;


/** FluxmlyPlugin */
public class FluxmlyPlugin implements MethodCallHandler {


  private static final String TAG = "XMLY";
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
//  private EventChannel.EventSink eventSink = null;
  private static Registrar registrar;
  private CommonRequest mXimalaya=null;
  private TrackList mTrackHotList;
  private XmPlayerManager mPlayerManager;
  private final MethodChannel channel;


  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "fluxmly");
    channel.setMethodCallHandler(new FluxmlyPlugin(registrar,channel));
  }

  private FluxmlyPlugin(Registrar registrar,MethodChannel channel){
    this.channel = channel;
    this.channel.setMethodCallHandler(this);
    this.registrar = registrar;
    mPlayerManager =XmPlayerManager.getInstance(registrar.context());
  }


  @Override
  public void onMethodCall(final MethodCall call, final Result result) {

    handleMethodCall(call,result);
  }

  private void handleMethodCall(final MethodCall call,final Result result){
    switch(call.method){
      case "init":
        ConstantsOpenSdk.isDebug = true;
        String appKey = call.argument("appKey");
        String appSecret = call.argument("appSecret");
        String packId = call.argument("packId");
        mXimalaya = CommonRequest.getInstanse();
        mXimalaya.setAppkey(appKey);
        mXimalaya.setPackid(packId);
        mXimalaya.init(registrar.activeContext(),appSecret);
        //初始化播放器
        mPlayerManager.init();
        mPlayerManager.setBreakpointResume(false);
        //播放器监听
        mPlayerManager.addPlayerStatusListener(mPlayerStatusListener);

        result.success(200);
        break;
      case "getGuessLikeAlbum":
        getGuessLikeAlbum(call,result);
        break;
      case "getTracks":
        getTracks(call,result);
        break;
      case "playTrack":
        //播放器监听
        mPlayerManager.addPlayerStatusListener(mPlayerStatusListener);
        List trackList = call.argument("trackList");
        int index = call.argument("index");

        //转化成List<Track>
        List<Track> tracks=new ArrayList<Track>();
        try {
          Type listType = (new TypeToken<Track>() {
          }).getType();

          for(Object trackModel:trackList){
            String str = new Gson().toJson(trackModel);
            Track track = (Track)BaseResponse.getResponseBodyStringToObject(listType, str);
            tracks.add(track);
          }
        } catch (Exception e) {
          //TODO: handle exception
        }


        mPlayerManager.setPlayList(tracks,index);
        break;
      case "pause":
        mPlayerManager.pause();
        result.success(1);
        break;
      case "play":
        int playIndex = call.argument("index");
        if(playIndex >= 0){
          mPlayerManager.play(playIndex);
        }else{
          mPlayerManager.play();
        }

        result.success(1);
        break;
      case "stop":
        mPlayerManager.stop();
        result.success(1);
        break;
      case "playPre":
        mPlayerManager.playPre();
        result.success(1);
        break;
      case "playNext":
        mPlayerManager.playNext();
        result.success(1);
        break;
      case "getDuration":
        result.success(""+mPlayerManager.getDuration());
        break;
      case "getPlayCurrPositon":
        int res = mPlayerManager.getPlayCurrPositon();
        Log.e(TAG,"音频当前:"+res);
        result.success(""+res);
        break;
      case "seekTo":
        int pos = call.argument("pos");

        mPlayerManager.seekTo(pos);
        break;
      case "release":
        if(mPlayerManager!=null){
          mPlayerManager.removePlayerStatusListener(mPlayerStatusListener);
        }
        break;
      case "setPlayMode":
        if(mPlayerManager!=null){
          int playModeIndex = call.argument("playModeIndex");
          if(playModeIndex==1){
            mPlayerManager.setPlayMode(XmPlayListControl.PlayMode.PLAY_MODEL_LIST_LOOP);
          }else{
            mPlayerManager.setPlayMode(XmPlayListControl.PlayMode.PLAY_MODEL_SINGLE_LOOP);
          }

          result.success(1);
        }
        break;
      case "trackRichInfo":
        getTrackRichInfo(call,result);
        break;
      default:
        result.notImplemented();
    }
  }

  private void getTrackRichInfo(MethodCall call, final Result result) {
    Map<String, String> map = new HashMap<String, String>();
    String trackID = call.argument("trackID");
    map.put(DTransferConstants.TRACK_ID,""+trackID);

    CommonRequest.baseGetRequest("https://api.ximalaya.com/tracks/get_single", map, new IDataCallBack() {
      @Override
      public void onSuccess(Object o) {
        result.success(""+o);
      }

      @Override
      public void onError(int i, String s) {
        Log.e(TAG,"ERROR:"+i+",message:"+s);
      }
    }, new CommonRequest.IRequestCallBack() {
      @Override
      public Object success(String s) throws Exception {
        return s;

      }
    });
  }

  private void getGuessLikeAlbum(MethodCall call, final Result result) {
    Map<String, String> map = new HashMap<String, String>();
    int count = call.argument("count");
    map.put(DTransferConstants.LIKE_COUNT,""+count);
    CommonRequest.getGuessLikeAlbum(map, new IDataCallBack<GussLikeAlbumList>() {
      @Override
      public void onSuccess(GussLikeAlbumList gussLikeAlbumList) {
        if(gussLikeAlbumList!=null && gussLikeAlbumList.getAlbumList() != null && gussLikeAlbumList.getAlbumList().size() !=0){
          final String data = new Gson().toJson(gussLikeAlbumList);
          result.success(""+data);
        }
      }

      @Override
      public void onError(int i, String s) {
        Log.e(TAG,"ERROR:"+i+",message:"+s);
      }
    });
  }

  public void getTracks(MethodCall call,final Result result){
    Map<String, String> map = new HashMap<String, String>();
    int albumID = call.argument("albumID");
    String sort = call.argument("sort");
    int page = call.argument("page");
    map.put(DTransferConstants.ALBUM_ID,albumID+"");
    map.put(DTransferConstants.SORT,sort);
    map.put(DTransferConstants.PAGE,""+page);
    CommonRequest.getTracks(map,new IDataCallBack<TrackList>(){
      @Override
      public void onSuccess(TrackList trackList) {
        if (trackList != null && trackList.getTracks() != null && trackList.getTracks().size() != 0) {
//          if(mTrackHotList!=null){
//            trackList.getTracks().addAll(0 ,mTrackHotList.getTracks());
//          }

          mTrackHotList = trackList;
          final String data=new Gson().toJson(mTrackHotList);
          result.success(""+data);
        }
      }

      @Override
      public void onError(int i, String s) {
        System.out.println(""+i+s);
      }
    });
  }

  private static Map<String, Object> buildArguments(Object value) {
    Map<String, Object> result = new HashMap<>();
    result.put("value", value);
    return result;
  }

  //====================== 播放器回调方法 开始===================
  private IXmPlayerStatusListener mPlayerStatusListener = new IXmPlayerStatusListener() {
    @Override
    public void onPlayProgress(int currPos, int duration) {
      Map<String,Integer> result = new HashMap<>();
      result.put("currPos",currPos);
      result.put("duration",duration);
      final String data=new Gson().toJson(result);

      channel.invokeMethod("onPosition",data);
    }

    @Override
    public boolean onError(XmPlayerException exception) {
      Log.e(TAG,"错误信息"+exception);
      return false;
    }

    @Override
    public void onBufferProgress(int position) {

    }

    public void onBufferingStop() {
    }

    public void onBufferingStart() {

    }

    @Override
    public void onSoundPlayComplete() {
      Map<String,String> result = new HashMap<>();
      result.put("status","1");
      result.put("extra","1");
      final String data=new Gson().toJson(result);
      channel.invokeMethod("completePlay",data);
    }

    @Override
    public void onPlayPause() {

    }

    @Override
    public void onPlayStart() {


    }

    @Override
    public void onPlayStop() {

    }

    private void updateButtonStatus() {}

    @Override
    public void onSoundSwitch(PlayableModel laModel, PlayableModel curModel) {}

    @Override
    public void onSoundPrepared() {

    }
  };
  //====================== 播放器回调方法 结束===================


}
