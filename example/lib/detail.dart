import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluxmly/fluxmly.dart';

class TrackDetail extends StatefulWidget {
  final track;
  TrackDetail({this.track});
  @override
  _TrackDetailState createState() => _TrackDetailState();
}

class _TrackDetailState extends State<TrackDetail> {
  var _futureBuilder;
  List trackList;
  var trackInfo;
  int position;
  String trackRichInfo = "加载中";

  Fluxmly _fluxmly;
  Duration _duration = Duration(seconds: 0);
  Duration _position = Duration(seconds: 0);
  bool isPlaying = false;
  bool isLoop = true;

  get durationText =>
      _duration != null ? constructTime(_duration.inSeconds) : '';
  get positionText =>
      _position != null ? constructTime(_position.inSeconds) : '';

  @override
  void initState() {
    super.initState();
    trackList = widget.track['trackList'];
    trackInfo = widget.track['trackInfo'];

    position = widget.track['index'];
    if (_fluxmly == null) {
      _fluxmly = new Fluxmly();
    }

    //初始化播放
    initPlay(trackList, position);

    _fluxmly.setDurationHandler((d) {
      setState(() {
        _duration = d;
      });
    });
    _fluxmly.setPositionHandler((p) {
      setState(() {
        _position = p;
      });
    });
    _fluxmly.setPlayerHandler((value) {
      if(value=="1"){
        //判断当前播放器循环模式
        if(isLoop){
          int indexPos =
          (position + 1) > trackList.length ? position : position + 1;
          //更新
          update(trackList, indexPos,true);
          play(indexPos);
        }else{
          //更新
          update(trackList, position,true);
          play(position);
        }
      }
    });

    //获取详情
    getTrackRichInfo(trackInfo['id'].toString());

    if (mounted) {
      setState(() {
        _duration = Duration(seconds: trackInfo['duration']);
      });
    }
  }

  Future initPlay(trackList, index) async {
    await _fluxmly.playTrack(trackList, index);
  }

  @override
  void dispose() {
    super.dispose();
    _fluxmly.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 0),
            child: ListView(
              padding: EdgeInsets.only(top: 0),
              children: <Widget>[
                //大图
                Center(
                  child: Image.network(
                    trackInfo['cover_url_large'],
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.fill,
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    '${trackInfo['track_title']}',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      alignment: Alignment.center,
                      icon: Icon(
                        Icons.arrow_left,
                        size: 50.0,
                      ),
                      onPressed: () {
                        int time = (_position.inMilliseconds - 10000);

                        _fluxmly.seek(time < 0 ? 0 : time);
                      },
                    ),
                    Text(
                      "${positionText ?? '00:00'}",
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                    Expanded(
                      child: _duration == null
                          ? Container()
                          : Slider(
                              value: _position?.inMilliseconds?.toDouble() ?? 0,
                              onChanged: (double value) {
                                _fluxmly.seek(value.round());
                              },
                              onChangeEnd:(double value){
                                 print(value);
                              },
                              min: 0.0,
                              max: _duration.inMilliseconds.toDouble(),
                            ),
                    ),
                    Text(
                      '${durationText ?? '00:00'}',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_right,
                        size: 50,
                      ),
                      onPressed: () {
                        int endTime = (_position.inMilliseconds + 10000);

                        _fluxmly.seek(endTime>_duration.inMilliseconds? _duration.inMilliseconds:endTime);
                      },
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    //列表
                    IconButton(
                      icon: Icon(
                        Icons.format_list_bulleted,
                        size: 50,
                      ),
                      onPressed: () async {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return Container(
                              padding: EdgeInsets.only(top: 30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: ListView.builder(
                                itemCount: trackList.length,
                                itemBuilder: (context, index) {
                                  return playListItem(
                                      trackList[index], index, position);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    //上一首
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous,
                        size: 50.0,
                      ),
                      onPressed: () {
                        playPre();
                      },
                    ),
                    //播放 暂停
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 50.0,
                      ),
                      onPressed: () async {
                        print("$position");
                        isPlaying ? pause() : play(position);
                      },
                    ),
                    //下一首
                    IconButton(
                      icon: Icon(
                        Icons.skip_next,
                        size: 50.0,
                      ),
                      onPressed: () {
                        playNext();
                      },
                    ),
                    //循环方式
                    IconButton(
                      icon: Icon(
                        isLoop ? Icons.sync : Icons.sync_disabled,
                        size: 40.0,
                      ),
                      onPressed: () async {
                        final res = await _fluxmly.setPlayMode(isLoop ? 3 : 1);
                        if (res == 1) {
                          setState(() {
                            isLoop = !isLoop;
                          });
                        }
                      },
                    )
                  ],
                ),
                //简介
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Text(
                    '简介',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                  ),
                  height: 200,
                  child: ListView(
                    padding: EdgeInsets.only(top: 0, bottom: 50),
                    children: <Widget>[
                      Text(
                        trackRichInfo,
                        style: TextStyle(
                          fontSize: 14.0,
                          height: 2,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.centerLeft,
              color: Colors.transparent,
              height: 80,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  String constructTime(int seconds) {
    int minute = seconds ~/ 60;
    int second = seconds % 60;

    var time;

    time = formatTime(minute) + ":" + formatTime(second);

    return time;
  }

  String formatTime(int timeNum) {
    return timeNum < 10 ? "0" + timeNum.toString() : timeNum.toString();
  }

  Future play(int index, {int pos}) async {

    final result = await _fluxmly.play(index: index);
    if (result == 1) {
      setState(() {
        isPlaying = true;
      });
    }
  }

  Future pause() async {
    final result = await _fluxmly.pause();
    if (result == 1) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  Widget playListItem(item, index, curIndex) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            '${index + 1}.' + item['track_title'],
            style: TextStyle(
                color: curIndex == index ? Colors.orangeAccent : Colors.black87,
                fontSize: 14.0,
                fontWeight: FontWeight.w500),
          ),
          onTap: () async {
            update(trackList, index,false);
            Navigator.of(context).pop();
          },
        ),
        Divider(
          height: 8,
        )
      ],
    );
  }

  update(List list, int index,bool playStatus) async {
    if (isPlaying) {
      //判断是否正在播放，如果在播放则暂停
      final res=await _fluxmly.stop();
    }
    //更换图片和标题
    setState(() {
      isPlaying = playStatus;
      position = index;
      _position = Duration(seconds: 0);
      trackInfo = list[index];
    });
  }

  Future playNext() async {
    final res = await _fluxmly.playNext();
    if (res == 1) {
      int indexPos =
          (position + 1) >= trackList.length ? position : position + 1;
      //更新
      update(trackList, indexPos,true);
    }
  }

  Future playPre() async {
    final res = await _fluxmly.playPre();
    if (res == 1) {
      //更新
      int indexPos = (position - 1) < 0 ? position : position - 1;
      update(trackList, indexPos,true);
    }
  }

  Future getTrackRichInfo(String trackID) async {
    final data = await _fluxmly.trackRichInfo(trackID);
    var res = json.decode(data);

    setState(() {
      trackRichInfo = res['track_intro'];
    });
  }
}
