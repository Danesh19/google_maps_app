import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;

import 'booking_page.dart';

const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final loc.Location locationController = loc.Location();
  TextEditingController pickupController = TextEditingController();
  TextEditingController dropOffController = TextEditingController();

  LatLng? currentPosition;
  LatLng? pickupPosition;
  LatLng? dropOffPosition;
  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initializeMap());
  }

  Future<void> initializeMap() async {
    await fetchLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Pickup & Drop-off'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: pickupController,
                  decoration: InputDecoration(
                    hintText: 'Enter Pickup Location',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        pickupPosition = await fetchLocationFromAddress(pickupController.text);
                        updateMap();
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: dropOffController,
                  decoration: InputDecoration(
                    hintText: 'Enter Drop-off Location',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        dropOffPosition = await fetchLocationFromAddress(dropOffController.text);
                        updateMap();
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 70.0),
                  child: currentPosition == null
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentPosition!,
                      zoom: 13,
                    ),
                    markers: {
                      if (currentPosition != null)
                        Marker(
                          markerId: const MarkerId('currentLocation'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          position: currentPosition!,
                        ),
                      if (pickupPosition != null)
                        Marker(
                          markerId: const MarkerId('pickupLocation'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                          position: pickupPosition!,
                        ),
                      if (dropOffPosition != null)
                        Marker(
                          markerId: const MarkerId('dropOffLocation'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          position: dropOffPosition!,
                        ),
                    },
                    polylines: Set<Polyline>.of(polylines.values),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                if (pickupPosition != null && dropOffPosition != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingPage(
                        pickupPosition: pickupPosition!,
                        dropOffPosition: dropOffPosition!,
                      ),
                    ),
                  );
                } else {
                  debugPrint('Please select both pickup and drop-off locations');
                }
              },
              child: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    final currentLocation = await locationController.getLocation();
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      setState(() {
        currentPosition = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
      });
    }
  }

  Future<LatLng?> fetchLocationFromAddress(String address) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
    return null;
  }

  Future<void> updateMap() async {
    if (pickupPosition != null && dropOffPosition != null) {
      final coordinates = await fetchPolylinePoints();
      generatePolyLineFromPoints(coordinates);
    }

    setState(() {});
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${pickupPosition!.latitude},${pickupPosition!.longitude}&destination=${dropOffPosition!.latitude},${dropOffPosition!.longitude}&key=$googleMapsApiKey&mode=driving');

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['routes'].isNotEmpty) {
      final points = data['routes'][0]['overview_polyline']['points'];
      return PolylinePoints().decodePolyline(points).map((point) => LatLng(point.latitude, point.longitude)).toList();
    } else {
      debugPrint('No route found');
      return [];
    }
  }

  Future<void> generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');

    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    setState(() => polylines[id] = polyline);
  }
}
