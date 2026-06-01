import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:kulineran/components/screens/main_navigation_screen.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/components/widgets/custom_text_field.dart';
import 'package:kulineran/components/widgets/primary_button.dart';
import 'package:kulineran/services/auth_service.dart';
import 'package:kulineran/services/location_service.dart';
import 'package:kulineran/services/post_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<String> _base64Images = [];
  List<Uint8List> _decodedImages = [];
  bool _isLoading = false;
  bool _isPickingImage = false;

  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error initializing location: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _resetToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not get current location. Make sure GPS is enabled.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error resetting location: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      final List<XFile> pickedList = await picker.pickMultiImage(
        imageQuality: 40,
        maxWidth: 700,
      );

      if (pickedList.isNotEmpty) {
        List<String> newEncodes = [];
        List<Uint8List> newDecodes = [];
        for (var picked in pickedList) {
          final bytes = await File(picked.path).readAsBytes();
          final encoded = base64Encode(bytes);
          
          if (encoded.length > 900 * 1024) {
            continue;
          }
          newEncodes.add(encoded);
          newDecodes.add(bytes);
        }

        setState(() {
          _base64Images.addAll(newEncodes);
          _decodedImages.addAll(newDecodes);
          if (_base64Images.length > 5) {
            _base64Images = _base64Images.sublist(0, 5);
            _decodedImages = _decodedImages.sublist(0, 5);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Maximum of 5 images allowed. Extra images were discarded.")),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_base64Images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick at least one photo")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final postService = PostService();

      final uid = authService.currentUid;
      if (uid == null) throw Exception("User not logged in");

      if (_selectedLocation == null) {
        throw Exception("Please set a location on the map.");
      }

      await postService.createPost({
        'userId': uid,
        'foodSpotName': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'photoBase64': _base64Images.first,
        'photosBase64': _base64Images,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Spot posted successfully!")),
        );

        // Reset inputs
        _nameController.clear();
        _descriptionController.clear();
        setState(() {
          _base64Images.clear();
          _decodedImages.clear();
        });

        // Handle navigation
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // Switch back to Home Feed tab
          final mainNavState = context.findAncestorStateOfType<MainNavigationScreenState>();
          if (mainNavState != null) {
            mainNavState.setTab(0);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131313) : Colors.white,
      appBar: AppBar(
        title: const KulineranLogo(fontSize: 20),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // Screen Title
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        
                        fontSize: 24,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      children: const [
                        TextSpan(text: "Share a hidden "),
                        TextSpan(
                          text: "gem",
                          style: TextStyle(color: Color(0xFFFFB300)), // golden yellow
                        ),
                        TextSpan(text: "."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Help the community discover the hidden gems around the area",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Dashed Image Selector Box or Row of Previews
                  if (_base64Images.isEmpty)
                    GestureDetector(
                      onTap: _pickImage,
                      child: CustomPaint(
                        painter: DashedBorderPainter(
                          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        ),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Color(0xFFFF7260),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Add Images",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Select up to 5 photos from gallery",
                                style: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Browse Button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7260),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Browse Images",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _base64Images.length + (_base64Images.length < 5 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _base64Images.length) {
                            // Render the "Add More" dashed box
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: CustomPaint(
                                  painter: DashedBorderPainter(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                                  ),
                                  child: Container(
                                    width: 140,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 32,
                                          color: Color(0xFFFF7260),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Add More",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Render the image preview with a delete overlay button
                          final imgBytes = _decodedImages[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 140,
                                    height: 150,
                                    child: Image.memory(
                                      imgBytes,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _base64Images.removeAt(index);
                                        _decodedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF7260),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                // Number indicator badge (e.g. 1, 2, 3, etc.)
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Place Name
                  CustomTextField(
                    label: "Place Name",
                    hintText: "Place Name",
                    controller: _nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  CustomTextField(
                    label: "Description",
                    hintText: "Write your experiance",
                    controller: _descriptionController,
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Your Location Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Your Location",
                        style: TextStyle(
                          
                          fontSize: 16,
                        ),
                      ),
                      if (_selectedLocation != null)
                        TextButton.icon(
                          onPressed: _isLoadingLocation ? null : _resetToCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 16, color: Color(0xFFFF7260)),
                          label: const Text(
                            "Reset GPS",
                            style: TextStyle(
                              
                              fontSize: 12,
                              color: Color(0xFFFF7260),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Interactive Map Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E5E5),
                      ),
                      child: _isLoadingLocation && _selectedLocation == null
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7260)))
                          : _selectedLocation == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_off,
                                        size: 40,
                                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Location unavailable",
                                        style: TextStyle(
                                          
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: _initLocation,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF7260),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          "Retry location",
                                          style: TextStyle(
                                            
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Stack(
                                  children: [
                                    FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: _selectedLocation!,
                                        initialZoom: 15.0,
                                        onTap: (tapPosition, latLng) {
                                          setState(() {
                                            _selectedLocation = latLng;
                                          });
                                        },
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'com.mdp.kulineran',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _selectedLocation!,
                                              width: 40,
                                              height: 40,
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Color(0xFFFF7260),
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Instructions Banner Overlay
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          "Tap map to refine location coordinates",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Post Button
                  Center(
                    child: PrimaryButton(
                      text: "Post Experiance",
                      onPressed: _submit,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }
}

// Custom Painter to render dashed border around file drop box
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = dashLength;
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}