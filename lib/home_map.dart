import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  Set<Marker> _mapMarkers = Set();
  GoogleMapController _mapController;
  Position _currentPosition;
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );
  String searchAddr;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            appBar: AppBar(
              title: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(30.0),
                    ),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: "Buscar direcciones",
                  contentPadding: EdgeInsets.all(8),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(top: 0.0),
                    child: IconButton(
                      iconSize: 30,
                      color: Colors.blue,
                      icon: Icon(Icons.search),
                      onPressed: () {
                        searchAddr = _searchController.text;
                        searchandNavigate(searchAddr);
                      },
                    ),
                  ),
                ),
              ),
            ),
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  onLongPress: _setMarker,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                )
              ],
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text("Error!")),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  searchandNavigate(String searchAddr) {
    Geolocator().placemarkFromAddress(searchAddr).then(
      (result) {
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(
                    result[0].position.latitude, result[0].position.longitude),
                zoom: 17.0),
          ),
        );
      },
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    // add marker
    setState(
      () {
        _mapMarkers.add(
          Marker(
            markerId: MarkerId(coord.toString()),
            position: coord,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return addressInfo(coord.toString(), _markerAddress);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget addressInfo(String coord, String _markerAddress) {
    return Container(
      margin: EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(
              coord,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
            SizedBox(height: 20),
            Text(_markerAddress),
            SizedBox(height: 40),
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Hecho",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return addressInfo(_currentPosition.toString(), _currentAddress);
            },
          );
        },
      ),
    );

    // move camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }
}
