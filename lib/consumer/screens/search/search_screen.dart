import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../models/product_model.dart';
import '../products/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _query = '';

  double _minPrice = 0;
  double _maxPrice = 10000;

  String? _selectedCategoryId;
  String? _selectedBusinessId;

  bool _isLoading = false;
  bool _showFilters = false;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBusinesses();
    _loadAllProducts();
  }

  Future<void> _loadCategories() async {
    final snap = await _firestore.collection('categories').get();
    setState(() {
      _categories = snap.docs.map((d) {
        return {'id': d.id, 'name': d['name'] ?? ''};
      }).toList();
    });
  }

  Future<void> _loadBusinesses() async {
    final snap = await _firestore.collection('businesses').get();
    setState(() {
      _businesses = snap.docs.map((d) {
        return {'id': d.id, 'name': d['businessName'] ?? ''};
      }).toList();
    });
  }

  Future<void> _loadAllProducts() async {
    setState(() => _isLoading = true);
    final snap = await _firestore.collection('products').get();

    setState(() {
      _allProducts =
          snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList();
      _isLoading = false;
    });
  }

  void _searchProducts() {
    if (_query.trim().isEmpty) {
      setState(() => _filteredProducts = []);
      return;
    }

    final q = _query.toLowerCase();

    List<ProductModel> results = _allProducts.where((p) {
      return p.name.toLowerCase().contains(q);
    }).toList();

    _applyFiltersTo(results);
  }

  void _applyFiltersTo(List<ProductModel> products) {
    List<ProductModel> filtered = List.from(products);

    // Price
    filtered = filtered.where((p) {
      return p.price >= _minPrice && p.price <= _maxPrice;
    }).toList();

    // Category
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.category == _selectedCategoryId).toList();
    }

    // Business
    if (_selectedBusinessId != null) {
      filtered = filtered.where((p) => p.businessId == _selectedBusinessId).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _applyFilters() {
    List<ProductModel> baseList;

    // If there is NO search query → use ALL products
    if (_query.isEmpty) {
      baseList = List.from(_allProducts);
    }
    // If user has typed something → filter only search matches
    else {
      baseList = _allProducts.where((p) {
        return p.name.toLowerCase().contains(_query.toLowerCase());
      }).toList();
    }

    // Apply price + category + business filters
    _applyFiltersTo(baseList);
    _applyFiltersTo(baseList);
    setState(() {
      _showFilters = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _minPrice = 0;
      _maxPrice = 10000;
      _selectedCategoryId = null;
      _selectedBusinessId = null;
      _showFilters = false;
      _applyFilters();
    });
  }

  bool get _hasActiveFilters {
    return _minPrice > 0 ||
        _maxPrice < 10000 ||
        _selectedCategoryId != null ||
        _selectedBusinessId != null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBrown,
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w(context, 0.04),
        vertical: AppSizes.h(context, 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEARCH BAR + FILTER BUTTON
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (value) {
                    setState(() => _query = value.trim());
                    _searchProducts();
                  },
                  decoration: InputDecoration(
                    prefixIcon:
                    const Icon(Icons.search, color: AppColors.darkBrown),
                    hintText: "Search products...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.darkBrown),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                          _filteredProducts = [];
                        });
                      },
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _hasActiveFilters ? AppColors.darkBrown : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() => _showFilters = !_showFilters);
                  },
                  icon: Icon(
                    Icons.filter_list,
                    color:
                    _hasActiveFilters ? Colors.white : AppColors.darkBrown,
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          // FILTER PANEL
          if (_showFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PRICE RANGE
                  const Text(
                    "Price Range",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightBrown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "\$${_minPrice.toStringAsFixed(0)} - \$${_maxPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        RangeSlider(
                          values: RangeValues(_minPrice, _maxPrice),
                          min: 0,
                          max: 10000,
                          divisions: 100,
                          activeColor: AppColors.darkBrown,
                          onChanged: (v) {
                            setState(() {
                              _minPrice = v.start;
                              _maxPrice = v.end;
                            });
                          },
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CATEGORY DROPDOWN
                  const Text(
                    "Category",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.darkBrown),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("All Categories"),
                        ),
                        ..._categories.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'] as String,
                            child: Text(c['name']),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BUSINESS DROPDOWN
                  const Text(
                    "Business",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.darkBrown),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedBusinessId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("All Businesses"),
                        ),
                        ..._businesses.map<DropdownMenuItem<String>>((b) {
                          return DropdownMenuItem<String>(
                            value: b['id'] as String,
                            child: Text(b['name']),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedBusinessId = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // APPLY + RESET
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text(
                            "RESET",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBrown,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("APPLY"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ACTIVE FILTERS
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_minPrice > 0 || _maxPrice < 10000)
                    Chip(
                      label: Text(
                        '\$${_minPrice.toStringAsFixed(0)} - \$${_maxPrice.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.darkBrown,
                    ),
                  if (_selectedCategoryId != null)
                    Chip(
                      label: Text(
                        _categories
                            .firstWhere((c) => c['id'] == _selectedCategoryId)['name'] ??
                            '',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.darkBrown,
                    ),
                  if (_selectedBusinessId != null)
                    Chip(
                      label: Text(
                        _businesses
                            .firstWhere((b) => b['id'] == _selectedBusinessId)['name'] ??
                            '',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.darkBrown,
                    ),
                ],
              ),
            ),

          // RESULTS
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
              child: Text(
                "No products found",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            )
                : GridView.builder(
              itemCount: _filteredProducts.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, i) {
                final p = _filteredProducts[i];
                final img = p.imageUrl.isNotEmpty ? p.imageUrl.first : '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productId: p.id),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkBrown.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.network(
                              img,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "\$${p.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
