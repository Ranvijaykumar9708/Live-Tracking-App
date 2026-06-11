import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/map_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/location_helper.dart';
import '../../core/constants/constants.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({Key? key}) : super(key: key);

  @override
  _HomeMapScreenState createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final LocationHelper _locationHelper = LocationHelper();
  
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  List<String> _startSuggestions = [];
  List<String> _endSuggestions = [];

  LatLng? _startLocation;
  LatLng? _endLocation;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  void _initCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _startLocation = LatLng(position.latitude, position.longitude);
        _startController.text = "My Current Location";
      });
    }
  }

  void _onStartChanged(String query) async {
    final suggestions = await _locationHelper.fetchLocations(query);
    setState(() {
      _startSuggestions = suggestions;
    });
  }

  void _onEndChanged(String query) async {
    final suggestions = await _locationHelper.fetchLocations(query);
    setState(() {
      _endSuggestions = suggestions;
    });
  }

  void _selectStartLocation(String address, MapProvider viewModel) async {
    _startController.text = address;
    setState(() => _startSuggestions = []);
    final coords = await _locationHelper.getCoordinates(address);
    if (coords != null) {
      _startLocation = LatLng(coords['lat']!, coords['lng']!);
      _checkAndDrawRoute(viewModel);
    }
  }

  void _selectEndLocation(String address, MapProvider viewModel) async {
    _endController.text = address;
    setState(() => _endSuggestions = []);
    final coords = await _locationHelper.getCoordinates(address);
    if (coords != null) {
      _endLocation = LatLng(coords['lat']!, coords['lng']!);
      _checkAndDrawRoute(viewModel);
    }
  }

  void _checkAndDrawRoute(MapProvider viewModel) {
    if (_startLocation != null && _endLocation != null) {
      viewModel.updateLocations(_startLocation!, _endLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapProvider(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 2,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        drawer: _buildDrawer(context),
        body: Consumer<MapProvider>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(28.7041, 77.1025), // Default to Delhi
                    zoom: 12,
                  ),
                  onMapCreated: viewModel.onMapCreated,
                  markers: viewModel.markers,
                  polylines: viewModel.polylines,
                  mapType: viewModel.mapType,
                  trafficEnabled: viewModel.isTrafficEnabled,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  zoomControlsEnabled: false,
                ),
                if (!viewModel.isRideStarted)
                  Positioned(
                    top: 100,
                    left: 16,
                    right: 16,
                    child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 14),
                            const Icon(Icons.trip_origin, color: Colors.blue, size: 16),
                            SizedBox(
                              height: 36,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  5,
                                  (index) => Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.location_on, color: Colors.red, size: 18),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _startController,
                                  onChanged: _onStartChanged,
                                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                                  decoration: const InputDecoration(
                                    hintText: "Enter pickup location",
                                    hintStyle: TextStyle(color: Colors.black54),
                                    prefixIcon: Icon(Icons.circle, size: 12, color: Colors.black),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                              if (_startSuggestions.isNotEmpty)
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: _startSuggestions.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        visualDensity: VisualDensity.compact,
                                        leading: const Icon(Icons.location_on, color: Colors.black54, size: 20),
                                        title: Text(_startSuggestions[index], style: const TextStyle(color: Colors.black87, fontSize: 14)),
                                        onTap: () => _selectStartLocation(_startSuggestions[index], viewModel),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _endController,
                                  onChanged: _onEndChanged,
                                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                                  decoration: const InputDecoration(
                                    hintText: "Where to?",
                                    hintStyle: TextStyle(color: Colors.black54),
                                    prefixIcon: Icon(Icons.square, size: 12, color: Colors.black),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                                if (_endSuggestions.isNotEmpty)
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: _endSuggestions.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          visualDensity: VisualDensity.compact,
                                          leading: const Icon(Icons.location_on, color: Colors.black54, size: 20),
                                          title: Text(_endSuggestions[index], style: const TextStyle(color: Colors.black87, fontSize: 14)),
                                          onTap: () => _selectEndLocation(_endSuggestions[index], viewModel),
                                        );
                                      },
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                // Home and Work Shortcuts
                                Row(
                                  children: [
                                    ActionChip(
                                      avatar: const Icon(Icons.home, size: 16, color: Colors.black87),
                                      label: const Text("Home"),
                                      backgroundColor: Colors.grey[200],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                                      onPressed: () {
                                        final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                                        if (user?.homeAddress != null && user!.homeAddress!.isNotEmpty) {
                                          _selectEndLocation(user.homeAddress!, viewModel);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Home address not set. Update in Profile.")));
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ActionChip(
                                      avatar: const Icon(Icons.work, size: 16, color: Colors.black87),
                                      label: const Text("Work"),
                                      backgroundColor: Colors.grey[200],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                                      onPressed: () {
                                        final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                                        if (user?.workAddress != null && user!.workAddress!.isNotEmpty) {
                                          _selectEndLocation(user.workAddress!, viewModel);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Work address not set. Update in Profile.")));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: (viewModel.distanceText != null) ? 260 : 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'traffic',
                        backgroundColor: viewModel.isTrafficEnabled ? AppColors.accentColor : Colors.white,
                        onPressed: viewModel.toggleTraffic,
                        child: Icon(Icons.traffic, color: viewModel.isTrafficEnabled ? Colors.black : Colors.black),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'mapType',
                        backgroundColor: Colors.white,
                        onPressed: viewModel.toggleMapType,
                        child: const Icon(Icons.layers, color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'location',
                        backgroundColor: AppColors.primaryColor,
                        onPressed: viewModel.centerOnUser,
                        child: const Icon(Icons.my_location, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (viewModel.distanceText != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppStyles.glassBoxDecoration,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (viewModel.isFindingDriver)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: Colors.black),
                                  SizedBox(height: 16),
                                  Text("Finding a driver near you...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          else if (viewModel.isRideStarted && viewModel.driverDetails != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.black12,
                                    child: Icon(Icons.person, color: Colors.black54),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(viewModel.driverDetails!['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        Text("${viewModel.driverDetails!['rating']} ⭐", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
                                    child: Text(viewModel.driverDetails!['carNumber']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            )
                          else if (!viewModel.isRideStarted)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Trip Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    Text("${viewModel.durationText} (${viewModel.distanceText})", 
                                      style: const TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Align(alignment: Alignment.centerLeft, child: Text("Choose a Ride", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600))),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 120,
                                  child: _buildVehicleSelector(viewModel),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("En Route", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Text("${viewModel.durationText} left", style: const TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: viewModel.isRideStarted ? AppColors.errorColor : AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: viewModel.isFindingDriver ? null : () {
                                if (viewModel.isRideStarted) {
                                  viewModel.endRide();
                                  _startController.clear();
                                  _endController.clear();
                                } else {
                                  viewModel.startRide();
                                }
                              },
                              child: Text(viewModel.isRideStarted ? "END RIDE" : "START RIDE", style: AppStyles.buttonText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authViewModel = Provider.of<AuthProvider>(context);
    final user = authViewModel.currentUser;

    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            accountName: Text(user?.name ?? 'User Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
            accountEmail: Text(user?.email ?? 'user@example.com', style: const TextStyle(color: Colors.black54)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.grey[200],
              backgroundImage: user?.imagePath != null ? FileImage(File(user!.imagePath!)) : null,
              child: user?.imagePath == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: AppColors.accentColor),
            title: Text(user?.mobile ?? 'No Mobile', style: const TextStyle(color: AppColors.textPrimary)),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primaryColor),
            title: const Text('Edit Profile', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context); // Close Drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const Divider(color: Colors.black12),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.errorColor),
            title: const Text('Logout', style: TextStyle(color: AppColors.errorColor)),
            onTap: () async {
              await authViewModel.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(MapProvider viewModel) {
    final types = [VehicleType.bike, VehicleType.auto, VehicleType.sedan, VehicleType.suv];
    final titles = ["Moto", "Auto", "Sedan", "SUV"];
    final icons = [Icons.two_wheeler, Icons.electric_rickshaw, Icons.directions_car, Icons.airport_shuttle];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: types.length,
      itemBuilder: (context, index) {
        bool isSelected = viewModel.selectedVehicle == types[index];
        return GestureDetector(
          onTap: () => viewModel.setSelectedVehicle(types[index]),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icons[index], size: 32, color: isSelected ? Colors.white : Colors.black87),
                const SizedBox(height: 8),
                Text(
                  titles[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (viewModel.estimatedFare != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "₹${(viewModel.estimatedFare! * (index == 3 ? 1.5 : (index == 2 ? 1.2 : (index == 1 ? 0.8 : 0.5)))).round()}",
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }
}
