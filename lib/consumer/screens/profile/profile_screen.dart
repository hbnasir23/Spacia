import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Ensure location permission before using geolocation or maps.
  Future<bool> _ensureLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  bool _uploading = false;
  Map<String, dynamic>? _userData;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    setState(() {
      _userData = data;
      final loc = data['location'];
      if (loc != null) {
        _userLocation = LatLng(loc['lat'], loc['lng']);
      }
      _loading = false;
    });
  }

  Future<void> _uploadPhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null) return;

      setState(() => _uploading = true);

      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref('user_profiles/${user.uid}.jpg');

      // Upload the file
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();

      // Update Firestore with the new photo URL
      await _firestore.collection('users').doc(user.uid).update({'photoUrl': url});

      setState(() {
        _userData?['photoUrl'] = url;
        _uploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.darkBrown,
          ),
        );
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editField(String field, String label) async {
    final controller = TextEditingController(text: _userData?[field] ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBrown),
            onPressed: () async {
              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .update({field: controller.text.trim()});
              setState(() => _userData?[field] = controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.darkBrown,
            onPrimary: Colors.white,
            onSurface: AppColors.darkBrown,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final dob =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'dob': dob});
      setState(() => _userData?['dob'] = dob);
    }
  }

  Future<void> _selectLocation() async {
    final granted = await _ensureLocationPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required'))
        );
      }
      return;
    }

    // Try to get current location first, fallback to San Francisco
    LatLng current = _userLocation ?? const LatLng(37.7749, -122.4194);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      current = LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Use fallback location if current location fails
      print('Could not get current location: $e');
    }

    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        GoogleMapController? mapController;
        LatLng selectedLocation = current;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.darkBrown,
                title: const Text(
                  'Select Location',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: current, zoom: 14),
                    onMapCreated: (ctrl) {
                      mapController = ctrl;
                    },
                    onTap: (pos) {
                      setDialogState(() => selectedLocation = pos);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('loc'),
                        position: selectedLocation,
                        draggable: true,
                        onDragEnd: (pos) {
                          setDialogState(() => selectedLocation = pos);
                        },
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  ),
                  // Current location button - bottom left
                  Positioned(
                    bottom: 100,
                    left: 16,
                    child: FloatingActionButton(
                      heroTag: "myLoc",
                      backgroundColor: Colors.white,
                      onPressed: () async {
                        try {
                          final pos = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );
                          final latLng = LatLng(pos.latitude, pos.longitude);
                          mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(target: latLng, zoom: 16),
                            ),
                          );
                          setDialogState(() => selectedLocation = latLng);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not get current location'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.my_location, color: AppColors.darkBrown),
                    ),
                  ),
                  // Info card at top
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Tap on the map or drag the marker to select your location',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ),
                  // Confirm button - bottom right
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: "confirmLoc",
                      backgroundColor: AppColors.darkBrown,
                      onPressed: () => Navigator.pop(context, selectedLocation),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'location': {'lat': result.latitude, 'lng': result.longitude},
        'latitude': result.latitude,
        'longitude': result.longitude,
      });
      setState(() => _userLocation = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully!'),
            backgroundColor: AppColors.darkBrown,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkBrown),
      );
    }

    final user = _auth.currentUser!;
    final name = _userData?['name'] ?? 'User';
    final email = user.email ?? 'Not set';
    final dob = _userData?['dob'] ?? 'Not set';
    final address = _userData?['address'] ?? 'Not set';
    final image = _userData?['photoUrl'];

    return Container(
      color: AppColors.lightBrown,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSizes.w(context, 0.08)),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: AppSizes.h(context, 0.03)),

            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: AppColors.darkBrown.withOpacity(0.2),
                  backgroundImage: image != null ? NetworkImage(image) : null,
                  child: image == null
                      ? const Icon(Icons.person, size: 55, color: AppColors.darkBrown)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: InkWell(
                    onTap: _uploadPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.darkBrown,
                        shape: BoxShape.circle,
                      ),
                      child: _uploading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSizes.h(context, 0.03)),

            _infoRow("Full Name", name, () => _editField('name', 'Full Name')),
            const SizedBox(height: 15),
            _infoRow("Email", email, null, editable: false),
            const SizedBox(height: 15),
            _infoRow("Date of Birth", dob, _editDOB),
            const SizedBox(height: 15),
            _infoRow("Address", address, () => _editField('address', 'Address')),
            const SizedBox(height: 15),
            _infoRow(
              "Location",
              _userLocation != null ? "Set" : "Not set",
              _selectLocation,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, VoidCallback? onEdit,
      {bool editable = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Poppins', color: Colors.black87)),
              ],
            ),
          ),
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.darkBrown, size: 20),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
