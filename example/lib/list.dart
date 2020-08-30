import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluxmly/fluxmly.dart';

class AlbumList extends StatefulWidget {
  final params;
  AlbumList({this.params});
  @override
  _AlbumListState createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  var _futureBuilder;
  int page = 1;
  List tracksList;
  String title = "demo";

  @override
  void initState() {
    super.initState();
    _futureBuilder = getTracks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$title',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(253, 219, 69, 1.0),
      ),
      body: FutureBuilder(
        future: _futureBuilder,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.separated(
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/detail", arguments: {
                        "trackList": tracksList,
                        "trackInfo": tracksList[index],
                        "index": index
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      height: 120.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Image.network(
                            tracksList[index]['cover_url_middle'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.fill,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              "${index + 1}." +
                                  tracksList[index]['track_title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return Divider(
                    height: 1.0,
                    color: Colors.black,
                  );
                },
                itemCount: tracksList.length);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Future getTracks() async {
    String data =
        await Fluxmly.getTracks(widget.params['albumID'], "asc", page);
    var res = json.decode(data);

    setState(() {
      tracksList = res['tracks'];
      title = res['album_title'];
    });
    return "done";
  }
}
