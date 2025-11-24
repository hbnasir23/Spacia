import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../constants/app_colors.dart';

class AddProductScreen extends StatefulWidget {
  final String businessId;
  final String? productId; // optional for edit

  const AddProductScreen({super.key, required this.businessId, this.productId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = []; // URLs already stored on product doc when editing
  final Set<int> _removedExistingImageIndexes = {}; // indexes of existing images the user removed
  File? _selected3DModel;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.productId != null) _loadProductForEdit();
  }

  Future<void> _loadCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    final seen = <String>{};
    final cats = <Map<String, dynamic>>[];
    for (var doc in snapshot.docs) {
      final id = doc.id;
      if (seen.contains(id)) continue;
      seen.add(id);
      cats.add({'id': id, 'name': (doc.data()['name'] ?? 'Unnamed').toString()});
    }
    setState(() {
      _categories = cats;
      // If selected category is not present in the new list, reset it to null
      if (_selectedCategoryId != null && !_categories.any((c) => c['id'].toString() == _selectedCategoryId)) {
        _selectedCategoryId = null;
      }
    });
  }

  Future<void> _loadProductForEdit() async {
    try {
      final doc = await _firestore.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = (data['name'] ?? '').toString();
          _descController.text = (data['description'] ?? '').toString();
          _priceController.text = (data['price'] ?? 0).toString();
          _quantityController.text = (data['quantity'] ?? 0).toString();
          _selectedCategoryId = data['category']?.toString();
          if (data['imageUrl'] is List) {
            _existingImageUrls = List<String>.from(data['imageUrl']);
          } else if (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty) {
            _existingImageUrls = [(data['imageUrl'] as String)];
          }
          if (data['imageUrl'] is List) {
            // not loading remote images into File list; leave _selectedImages empty and show existing images if needed
          }
        });
      }
    } catch (e) {
      // ignore load errors for now
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 75);

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _pick3DModel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb', 'gltf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selected3DModel = File(result.files.single.path!);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('3D Model selected: ${result.files.single.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking 3D model: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.red),
      );
      return;
    }
    // For edit mode allow zero new images (keep existing)
    if (widget.productId == null && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload new images and merge with existing images that were not removed
      List<String> uploadedNewImageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final ref = FirebaseStorage.instance.ref(
          'products/${widget.businessId}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        await ref.putFile(_selectedImages[i]);
        final url = await ref.getDownloadURL();
        uploadedNewImageUrls.add(url);
      }

      // Keep existing images except those user removed
      final keptExisting = <String>[];
      for (int i = 0; i < _existingImageUrls.length; i++) {
        if (!_removedExistingImageIndexes.contains(i)) keptExisting.add(_existingImageUrls[i]);
      }

      final imageUrls = [...keptExisting, ...uploadedNewImageUrls];

      // Upload 3D model if selected
      String? modelUrl;
      if (_selected3DModel != null) {
        final modelRef = FirebaseStorage.instance.ref(
          'products/${widget.businessId}/${DateTime.now().millisecondsSinceEpoch}_model.glb',
        );
        await modelRef.putFile(_selected3DModel!);
        modelUrl = await modelRef.getDownloadURL();
      }

      // Create or update product
      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()),
        'category': _selectedCategoryId,
        'imageUrl': imageUrls,
        'modelUrl': modelUrl,
        'businessId': widget.businessId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.productId == null) {
        await _firestore.collection('products').add(data);
      } else {
        await _firestore.collection('products').doc(widget.productId).update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productId == null ? 'Product added successfully!' : 'Product updated successfully!'), backgroundColor: Colors.green),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descController.clear();
    _priceController.clear();
    _quantityController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedImages = [];
      _selected3DModel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Parent provides top bar; render form only
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title removed to avoid duplicate top bar; BusinessTopBar provides the header
              const SizedBox(height: 6),

              _buildTextField('Product Name', _nameController, 'Enter product name'),
              const SizedBox(height: 16),

              _buildTextField('Description', _descController, 'Enter product description', maxLines: 4),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Price (\$)', _priceController, '0.00', keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Quantity', _quantityController, '0', keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildCategoryDropdown(),
              const SizedBox(height: 24),

              _buildImagePicker(),
              const SizedBox(height: 24),

              _build3DModelPicker(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _addProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(widget.productId == null ? 'Add Product' : 'Save Changes', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Poppins'),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBrown, width: 2)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _categories.any((c) => c['id'].toString() == _selectedCategoryId) ? _selectedCategoryId : null,
              isExpanded: true,
              hint: const Text('Select Category', style: TextStyle(fontFamily: 'Poppins')),
              items: _categories.map((cat) => DropdownMenuItem<String>(
                value: cat['id'].toString(),
                child: Text((cat['name'] ?? 'Unnamed').toString(), style: const TextStyle(fontFamily: 'Poppins')),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Images', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImages,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
            ),
            child: _existingImageUrls.isEmpty && _selectedImages.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Tap to add images', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey))]))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: _existingImageUrls.length + _selectedImages.length,
                    itemBuilder: (context, index) {
                      if (index < _existingImageUrls.length) {
                        final url = _existingImageUrls[index];
                        final removed = _removedExistingImageIndexes.contains(index);
                        return Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => Container(color: AppColors.lightBrown))),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (removed) _removedExistingImageIndexes.remove(index); else _removedExistingImageIndexes.add(index);
                              }),
                              child: CircleAvatar(radius: 12, backgroundColor: removed ? Colors.red : Colors.black45, child: Icon(removed ? Icons.undo : Icons.close, size: 14, color: Colors.white)),
                            ),
                          ),
                        ]);
                      } else {
                        final selIndex = index - _existingImageUrls.length;
                        return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImages[selIndex], fit: BoxFit.cover));
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _build3DModelPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3D Model (Optional)', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
        const SizedBox(height: 4),
        const Text('Upload GLB or GLTF file for AR view', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pick3DModel,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBrown,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.view_in_ar, color: AppColors.darkBrown, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected3DModel != null
                            ? 'Model Selected'
                            : 'Tap to select 3D model',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selected3DModel != null)
                        Text(
                          _selected3DModel!.path.split('/').last,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  _selected3DModel != null ? Icons.check_circle : Icons.upload_file,
                  color: _selected3DModel != null ? Colors.green : AppColors.darkBrown,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
