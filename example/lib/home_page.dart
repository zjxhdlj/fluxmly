import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluxmly/fluxmly.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List albumList = [];

  @override
  void initState() {
    super.initState();
    getGuessLikeAlbum(50);

  }

  // Platform messages are asynchronous, so we initialize in an async method.


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(230, 230, 230, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(253, 219, 69, 1.0),
        title: Text(
          '喜马拉雅',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20.0),
        itemCount: albumList.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          var album = albumList[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                "/albumList",
                arguments: {
                  "albumID": album['id'],
                },
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10.0),
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  //图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: Image.network(
                      album['cover_url_middle'],
                      width: 100.0,
                      height: 100.0,
                      fit: BoxFit.fill,
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  //标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        //标题
                        Text(
                          album['album_title'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        //推荐理由
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 3.0),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(230, 230, 230, 1),
                            borderRadius: BorderRadius.circular(3.0),
                          ),
                          child: Text(
                            album['recommend_reason'],
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Color.fromRGBO(100, 100, 100, 1),
                            ),
                          ),
                        ),
                        //点赞和播放
                        Row(
                          children: <Widget>[
                            Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 16,
                              ),
                            ),
                            Text(
                              intToString(album['play_count'], 2),
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Color.fromRGBO(100, 100, 100, 1),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future getGuessLikeAlbum(int count) async {
    String data = await Fluxmly.getGuessLikeAlbum(count);


    var res = json.decode(data);
    var resData;
    if(res.runtimeType.toString() == "List<dynamic>"){
       resData = res;
    }else{
       resData = res['albumList'];
    }


    setState(() {
      albumList = resData;
    });
    return 'done';
  }

  //数量转换
  intToString(int count, int position) {
    double totalCount;
    String unit;
    if (count > 100000000) {
      totalCount = (count / 100000000);
      unit = "亿";
    } else if (count > 10000) {
      totalCount = (count / 10000);
      unit = "万";
    } else {
      totalCount = count as double;
    }

    return formatNum(totalCount, 2) + unit;
  }

  formatNum(double num, int postion) {
    if ((num.toString().length - num.toString().lastIndexOf(".") - 1) <
        postion) {
      //小数点后有几位小数
      return num.toStringAsFixed(postion)
          .substring(0, num.toString().lastIndexOf(".") + postion + 1)
          .toString();
    } else {
      return num.toString()
          .substring(0, num.toString().lastIndexOf(".") + postion + 1)
          .toString();
    }
  }
}
