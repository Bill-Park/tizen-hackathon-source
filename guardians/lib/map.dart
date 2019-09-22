// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//TODO: place 다시 살리기.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:guardians/main.dart';
import 'package:http/http.dart' as http;


const kGoogleApiKey = "AIzaSyATcu886D3cfxtrgsspKUjszSK5DzNoqBo";

class PlaceBody extends StatefulWidget {
  final GlobalKey<MyHomePageState> parentKey;

  const PlaceBody({Key key, this.parentKey}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PlaceBodyState();
}

class PlaceBodyState extends State<PlaceBody>
    with SingleTickerProviderStateMixin {
  static final LatLng center = const LatLng(37.478962, 126.887341);
  var val = 30;
  var cameraVal = 90;
  bool cameraMove = false;
  bool lightOn = false;
  int selectIndex = -1;

  GlobalKey mapKey = GlobalKey();
  AnimationController rotationController;

  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(37.478869, 126.887086),
    zoom: 18.0,
  );

  final Set<Polyline> _polyline = {};
  List<LatLng> latlng = List();

  GoogleMapController controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId selectedMarker;
  List<PlacesSearchResult> places = [];

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
    _add(37.482140, 126.885541, '집', 0);
    _add(37.478272, 126.888446, '버스정류장', 0);
    _add(37.478962, 126.887341, '가로등1', 1);
    _add(37.479062, 126.887061, '현재위치', 3);
    _add(37.480018, 126.886161, '가로등2', 1);
    _add(37.480093, 126.886385, '카메라4', 2);
    _add(37.478869, 126.887086, '카메라5', 2);

    latlng.add(LatLng(37.479062, 126.887061));
    latlng.add(LatLng(37.478002, 126.888141));
    latlng.add(LatLng(37.478272, 126.888446));

    setState(() {
      _polyline.add(Polyline(
        polylineId: PolylineId('이동경로'),
        visible: true,
        points: latlng,
        color: Colors.blue,
      ));
    });

  }

  @override
  void initState() {
    super.initState();
    rotationController = AnimationController(
        duration: const Duration(seconds: 1), vsync: this);
    rotationController.animateTo(0.5);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _add(double lat, double lng, String title, int type) async {
    final int markerCount = markers.length;

    if (markerCount == 12) {
      return;
    }

    final MarkerId markerId = MarkerId(title);
    final ImageConfiguration imageConfiguration =
        createLocalImageConfiguration(context);
    String imageName = "assets/camera.png";
    switch (type) {
      case 0:
        imageName = "assets/pin.png";
        break;
      case 1:
        imageName = "assets/light.png";
        break;
      case 2:
        imageName = "assets/camera.png";
        break;
      case 3:
        imageName = "assets/report.png";
        break;
    }
    final Marker marker = Marker(
      markerId: markerId,
      icon:
          await BitmapDescriptor.fromAssetImage(imageConfiguration, imageName),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: title, anchor: Offset(0.5, 0.5)),
      zIndex: type.toDouble(),
      onTap: () {
        setState(() {
          lightOn = false;
          cameraMove = false;
        });
        if (title == '가로등1') {
          if (selectIndex == 1) {
            return;
          }
          setState(() {
            val = 30;
            lightOn = true;
            selectIndex = 1;
          });
        } else if (title == '가로등2') {
          if (selectIndex == 2) {
            return;
          }
          setState(() {
            val = 30;
            lightOn = true;
            selectIndex = 2;
          });
        } else if (title == '카메라4') {
          if (selectIndex == 4) {
            return;
          }
          widget.parentKey.currentState.changeProperty(4);
          setState(() {
            rotationController.animateTo(0.25);
            cameraVal = 90;
            cameraMove = true;
            selectIndex = 4;
          });
        } else if (title == '카메라5') {
          if (selectIndex == 5) {
            return;
          }
          widget.parentKey.currentState.changeProperty(5);
          setState(() {
            rotationController.animateTo(0.5);
            cameraMove = true;
            selectIndex = 5;
          });
        }
      },
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoogleMap googleMap = GoogleMap(
      key: mapKey,
      onMapCreated: _onMapCreated,
      polylines: _polyline,
      initialCameraPosition: _kInitialPosition,
      markers: Set<Marker>.of(markers.values),
    );

    return Stack(
      alignment: Alignment.centerRight,
      children: <Widget>[
        googleMap,
        cameraMove ? Align(
            alignment: Alignment(0, -0.2),
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(rotationController),
              child: InkWell(
                onTap: () {
                  setState(() {
                    cameraMove = false;
                    selectIndex = -1;
                  });
                },
                child: Container(
                    height: 300, child: Image.asset('assets/radar.png')),
              ),
            )) : Container(),
        lightOn
            ? Align(
                alignment: Alignment(1, 0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 50,
                    color: Color(0x99FFFFFF),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        inactiveColor: Colors.black12,
                        activeColor: Colors.green,
                        value: val.toDouble(),
                        min: 0.0,
                        max: 100.0,
                        divisions: 100,
                        label: '$val',
                        onChanged: (double newValue) {
                          setState(() {
                            val = newValue.round();
                          });
                        },
                        onChangeEnd: (double newValue) {
                          setState(() {
                            val = newValue.round();
                            http.post("http://192.168.29.223:3000/set/led/$selectIndex/${val.toInt()}");
                          });
                        },
                      ),
                    ),
                  ),
                ),
              )
            : Container(),
        cameraMove && selectIndex == 4
            ? Align(
                alignment: Alignment(0, 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 50,
                    color: Color(0x99FFFFFF),
                    child: Slider(
                      inactiveColor: Colors.blueAccent,
                      activeColor: Colors.blueAccent,
                      value: cameraVal.toDouble(),
                      min: 0.0,
                      max: 180.0,
                      divisions: 6,
                      label: '${cameraVal - 90}°',
                      onChangeEnd: (double newValue) {
                        setState(() {
                          if (cameraVal > 90) {
                            print('right');
                            http.get("http://192.168.29.223:3000/cctv/4/right");
                            rotationController.animateTo(0.5);
                          } else if (cameraVal < 90) {
                            print('left');
                            http.get("http://192.168.29.223:3000/cctv/4/left");
                            rotationController.animateTo(0.0);
                          } else {
                            rotationController.animateTo(0.25);
                          }
                        });
                      },
                      onChanged: (double newValue) {
                        setState(() {
                          cameraVal = newValue.round();
                        });
                      },
                    ),
                  ),
                ),
              )
            : cameraMove
                ? Align(
                    alignment: Alignment(0, 0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 50,
                        color: Color(0x99FFFFFF),
                        child: Slider(
                          inactiveColor: Colors.black12,
                          activeColor: Colors.black12,
                          value: 90,
                          min: 0.0,
                          max: 180.0,
                          divisions: 6,
                          label: '0°',
                        ),
                      ),
                    ),
                  )
                : Container(),
      ],
    );
  }
}
