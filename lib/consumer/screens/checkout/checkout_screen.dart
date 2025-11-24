import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/order_model.dart';
import '../../../services/email_service.dart';
import '../../../services/stripe_keys.dart';
import '../../../services/stripe_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  bool _processingOrder = false;
  String _paymentMethod = 'cash'; // 'cash' or 'card'

  Map<String, dynamic>? _userData;
  LatLng? _userLocation;
  String _address = '';

  // ---------- CARD UI CONTROLLERS ----------
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController(); // MM/YY
  final TextEditingController _cvcController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.example';
    _cardNumberController.addListener(() {
      final formatted = formatCardNumber(_cardNumberController.text);
      if (_cardNumberController.text != formatted) {
        _cardNumberController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    _expiryController.addListener(() {
      final formatted = formatExpiry(_expiryController.text);
      if (_expiryController.text != formatted) {
        _expiryController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    _cvcController.addListener(() {
      final formatted = formatCVC(_cvcController.text);
      if (_cvcController.text != formatted) {
        _cvcController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    _loadUserData();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};

    setState(() {
      _userData = data;
      _address = data['address'] ?? '';
      final loc = data['location'];
      if (loc != null) {
        _userLocation = LatLng(loc['lat'], loc['lng']);
      }
      _loading = false;
    });
  }
  // ---------- FORMATTERS ----------

// Format card number as XXXX XXXX XXXX XXXX
  String formatCardNumber(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    final trimmed = digitsOnly.substring(0, digitsOnly.length.clamp(0, 16));
    final buf = StringBuffer();

    for (int i = 0; i < trimmed.length; i++) {
      buf.write(trimmed[i]);
      if ((i + 1) % 4 == 0 && i + 1 != trimmed.length) {
        buf.write(' ');
      }
    }
    return buf.toString();
  }

// Format expiry as MM/YY with auto slash
  String formatExpiry(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return '';

    // ---- FIRST DIGIT LOGIC ----
    if (digits.length == 1) {
      int d = int.tryParse(digits[0]) ?? 0;

      if (d == 0 || d == 1) {
        return digits; // valid starts: 0 or 1
      } else {
        // For 2-9, auto-correct to 0X
        return '0$d';
      }
    }

    // ---- ENSURE ONLY 4 TOTAL DIGITS (MMYY) ----
    digits = digits.substring(0, digits.length.clamp(0, 4));

    // ---- MONTH VALIDATION ----
    int month = int.tryParse(digits.substring(0, 2)) ?? 0;
    if (month < 1 || month > 12) {
      // Fix invalid "13", "22", etc.
      return digits.substring(0, 1);
    }

    // ---- FORMAT WITH SLASH ----
    if (digits.length > 2) {
      return digits.substring(0, 2) + "/" + digits.substring(2);
    }

    return digits;
  }


// Limit CVC to 3 digits
  String formatCVC(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return digits.substring(0, digits.length.clamp(0, 3));
  }


  Future<void> _editAddress() async {
    final controller = TextEditingController(text: _address);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delivery Address',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your delivery address',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkBrown,
            ),
            onPressed: () async {
              final newAddress = controller.text.trim();
              if (newAddress.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .update({'address': newAddress});
              setState(() => _address = newAddress);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address updated successfully!'),
                    backgroundColor: AppColors.darkBrown,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocation() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      final res = await Permission.locationWhenInUse.request();
      if (!res.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
        }
        return;
      }
    }

    LatLng current = _userLocation ?? const LatLng(37.7749, -122.4194);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      current = LatLng(position.latitude, position.longitude);
    } catch (e) {
      // ignore, keep fallback
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
                  'Select Delivery Location',
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
                    initialCameraPosition: CameraPosition(
                      target: current,
                      zoom: 14,
                    ),
                    onMapCreated: (ctrl) {
                      mapController = ctrl;
                    },
                    onTap: (pos) {
                      setDialogState(() => selectedLocation = pos);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('delivery'),
                        position: selectedLocation,
                        draggable: true,
                        onDragEnd: (pos) {
                          setDialogState(() => selectedLocation = pos);
                        },
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Tap on the map or drag the marker to select delivery location',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 16,
                    child: FloatingActionButton(
                      heroTag: "currentLoc",
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
                      child: const Icon(Icons.my_location,
                          color: AppColors.darkBrown),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: "confirmLoc",
                      backgroundColor: AppColors.darkBrown,
                      onPressed: () => Navigator.pop(context, selectedLocation),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

      setState(() {
        _userLocation = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery location updated!'),
            backgroundColor: AppColors.darkBrown,
          ),
        );
      }
    }
  }

  // ---------- STRIPE CARD VALIDATION HELPERS ----------

  bool _validateCardInputs() {
    final number = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text.replaceAll(' ', '');
    final cvc = _cvcController.text.trim();

    if (number.isEmpty || expiry.isEmpty || cvc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all card fields'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final parts = expiry.split('/');
    if (parts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry must be in MM/YY format'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final month = int.tryParse(parts[0]);
    final yearRaw = parts[1];
    final year = int.tryParse(
        yearRaw.length == 2 ? '20$yearRaw' : yearRaw); // 24 -> 2024-ish

    if (month == null ||
        year == null ||
        month < 1 ||
        month > 12 ||
        year < DateTime.now().year - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expiry date'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (cvc.length < 3 || cvc.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid CVC'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<CardDetails> _buildStripeCardDetails() async {
    final number = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text.replaceAll(' ', '');
    final parts = expiry.split('/');

    final month = int.parse(parts[0]);
    final yearRaw = parts[1];
    final year = int.parse(
        yearRaw.length == 2 ? '20$yearRaw' : yearRaw); // crude but fine

    return CardDetails(
      number: number,
      cvc: _cvcController.text.trim(),
      expirationMonth: month,
      expirationYear: year,
    );
  }

  Future<void> _placeOrder() async {
    if (_address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set delivery location on map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _processingOrder = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final user = _auth.currentUser!;

      // Validate stock
      bool stockAvailable = true;
      String outOfStockProduct = '';

      for (var cartItem in cart.items.values) {
        final productDoc = await _firestore
            .collection('products')
            .doc(cartItem.product.id)
            .get();

        if (!productDoc.exists) {
          stockAvailable = false;
          outOfStockProduct = cartItem.product.name;
          break;
        }

        final currentQuantity = productDoc.data()?['quantity'] ?? 0;
        if (currentQuantity < cartItem.quantity) {
          stockAvailable = false;
          outOfStockProduct = cartItem.product.name;
          break;
        }
      }

      if (!stockAvailable) {
        setState(() => _processingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sorry, "$outOfStockProduct" is out of stock or insufficient quantity'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Build order items
      final orderItems = cart.items.values.map((cartItem) {
        return OrderItem(
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          productImage: cartItem.product.imageUrl.isNotEmpty
              ? cartItem.product.imageUrl[0]
              : '',
          price: cartItem.product.price,
          quantity: cartItem.quantity,
        );
      }).toList();

      // ---------- STRIPE CARD PAYMENT FLOW ----------
      String? paymentIntentId;
      if (_paymentMethod == 'card') {
        // Validate custom UI fields first
        if (!_validateCardInputs()) {
          setState(() => _processingOrder = false);
          return;
        }

        try {
          final amountCents = (cart.totalAmount * 100).round();

          // 1) Create PaymentIntent via your backend
          final intent = await StripeService.createPaymentIntent(
            amountCents: amountCents,
            currency: 'usd',
            transferDestinationAccountId: null,
            description: 'Order from Spacia',
          );
          paymentIntentId = intent['id'] as String?;
          if (paymentIntentId == null) {
            throw Exception('No PaymentIntent id returned');
          }

          // 2) Push our custom card details into Stripe
          final cardDetails = await _buildStripeCardDetails();
          await Stripe.instance.dangerouslyUpdateCardDetails(cardDetails);

          // 3) Create PaymentMethod (this still uses Stripe's internal card state)
          final billing = BillingDetails(
            name: _userData?['name'] ?? _auth.currentUser?.email,
          );

          final paymentMethod = await Stripe.instance.createPaymentMethod(
            params: PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(
                billingDetails: billing,
              ),
            ),
          );

          // 4) Confirm PaymentIntent on your backend
          final confirmed = await StripeService.confirmPaymentIntent(
            paymentIntentId,
            paymentMethod.id,
          );

          final status = confirmed['status'] as String? ?? '';
          if (status != 'succeeded' && status != 'requires_capture') {
            throw Exception('Payment not successful (status: $status)');
          }
        } catch (e) {
          setState(() => _processingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // ---------- SAVE ORDER ----------
      final order = OrderModel(
        id: '',
        userId: user.uid,
        items: orderItems,
        totalAmount: cart.totalAmount,
        paymentMethod: _paymentMethod,
        status: _paymentMethod == 'card' ? 'paid' : 'pending',
        deliveryAddress: {
          'address': _address,
          'lat': _userLocation!.latitude,
          'lng': _userLocation!.longitude,
        },
        createdAt: DateTime.now(),
      );

      final orderMap = order.toMap();
      if (paymentIntentId != null) {
        orderMap['paymentIntentId'] = paymentIntentId;
        orderMap['paymentStatus'] = 'paid';
      }

      final docRef = await _firestore.collection('orders').add(orderMap);

      // Batch reduce stock
      final batch = _firestore.batch();
      for (var cartItem in cart.items.values) {
        final productRef =
        _firestore.collection('products').doc(cartItem.product.id);
        final productDoc = await productRef.get();
        final currentQuantity = productDoc.data()?['quantity'] ?? 0;
        final newQuantity = currentQuantity - cartItem.quantity;
        batch.update(productRef, {
          'quantity': newQuantity >= 0 ? newQuantity : 0,
        });
      }
      await batch.commit();

      // ---------- EMAIL RECEIPT ----------
      if (_paymentMethod == 'cash') {
        await EmailService.sendOrderReceipt(
          userEmail: user.email!,
          userName: _userData?['name'] ?? 'Customer',
          orderId: docRef.id,
          items: orderItems,
          totalAmount: cart.totalAmount,
          deliveryAddress: _address,
        );
      }

      if (_paymentMethod == 'card') {
        // Your StripeService implementation can keep using the intent id
        final paymentMethodDetails =
        await StripeService.retrievePaymentMethod(paymentIntentId!);
        final cardBrand =
            paymentMethodDetails['brand'] ?? paymentMethodDetails['network'] ??
                'Card';
        final last4 = paymentMethodDetails['last4'] ?? '';

        await EmailService.sendOrderReceipt(
          userEmail: user.email!,
          userName: _userData?['name'] ?? 'Customer',
          orderId: docRef.id,
          items: orderItems,
          totalAmount: cart.totalAmount,
          deliveryAddress:
          '$_address\nPayment: Paid with $cardBrand **** $last4',
        );
      }

      // Clear cart + card fields
      cart.clear();
      _cardNumberController.clear();
      _expiryController.clear();
      _cvcController.clear();

      setState(() => _processingOrder = false);

      // ---------- ORDER CONFIRMATION DIALOG ----------
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.darkBrown,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Order Confirmed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                // BODY
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order ID: ${docRef.id}",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        "Total: \$${cart.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Items",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          itemCount: orderItems.length,
                          itemBuilder: (_, i) {
                            final it = orderItems[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: it.productImage.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  it.productImage,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : const Icon(Icons.image),
                              title: Text(
                                it.productName,
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                              subtitle: Text(
                                'Qty: ${it.quantity} • \$${it.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "Delivery Address:\n$_address",
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),

                      const SizedBox(height: 20),

                      // DOWNLOAD RECEIPT BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO → implement PDF download
                          },
                          icon: const Icon(Icons.download, color: AppColors.darkBrown),
                          label: const Text(
                            "Download Receipt",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.darkBrown),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // CONTINUE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _processingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------- UI BUILD ----------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.lightBrown,
        appBar: AppBar(
          backgroundColor: AppColors.darkBrown,
          title: const Text(
            'Checkout',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.darkBrown),
        ),
      );
    }

    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Delivery Address & Location'),
            const SizedBox(height: 12),
            if (_address.isEmpty || _userLocation == null)
              _buildEmptyAddressCard()
            else
              _buildAddressCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Payment Method'),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'cash',
              'Cash on Delivery',
              Icons.money,
              'Pay when your order arrives',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'card',
              'Credit/Debit Card',
              Icons.credit_card,
              'Pay securely with card',
            ),
            const SizedBox(height: 12),
            _buildCardInput(),
            const SizedBox(height: 24),
            _buildSectionTitle('Order Summary'),
            const SizedBox(height: 12),
            _buildSummaryCard(cart),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(cart),
    );
  }

  // ---------- SMALL UI HELPERS ----------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBrown,
      ),
    );
  }

  Widget _buildEmptyAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.orange.shade700),
          const SizedBox(height: 12),
          Text(
            _address.isEmpty && _userLocation == null
                ? 'No delivery address and location set'
                : _address.isEmpty
                ? 'No delivery address set'
                : 'No location set',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _address.isEmpty && _userLocation == null
                ? 'Please add your delivery address and set location to continue'
                : _address.isEmpty
                ? 'Please add your delivery address to continue'
                : 'Please set your location on map to continue',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          if (_address.isEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _editAddress,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Address',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_address.isEmpty && _userLocation == null)
            const SizedBox(height: 12),
          if (_userLocation == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.map),
                label: const Text(
                  'Set Location on Map',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _address.isEmpty ? Colors.grey.shade700 : AppColors.darkBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.darkBrown),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _address,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.map, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lat: ${_userLocation!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_userLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Set',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editAddress,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text(
                    'Change',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBrown,
                    side: const BorderSide(color: AppColors.darkBrown),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectLocation,
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text(
                    'Update Map',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBrown,
                    side: const BorderSide(color: AppColors.darkBrown),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      String value,
      String title,
      IconData icon,
      String subtitle,
      ) {
    final isSelected = _paymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.darkBrown : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.darkBrown.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.darkBrown.withAlpha(26)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.darkBrown : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (val) => setState(() => _paymentMethod = val!),
              activeColor: AppColors.darkBrown,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- CUSTOM CARD UI (NO STRIPE WIDGETS) ----------

  Widget _buildCardInput() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _paymentMethod == 'card'
          ? Container(
        key: const ValueKey('card-input'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.darkBrown.withOpacity(0.4),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card Details',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 14),

            // Card number
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              maxLength: 19,
              decoration: InputDecoration(
                counterText: "",
                labelText: "Card Number",
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Expiry + CVC
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      counterText: "",
                      labelText: "MM/YY",
                      prefixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                      controller: _cvcController,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      decoration: InputDecoration(
                        counterText: "",
                        labelText: "CVC",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Text(
              'Use test card 4242 4242 4242 4242',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Items (${cart.totalQuantity})',
            '\$${cart.totalAmount.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _buildSummaryRow('Delivery Fee', 'Free', isGreen: true),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            '\$${cart.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _processingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _processingOrder
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              _paymentMethod == 'card' ? 'Pay Now' : 'Place Order',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isTotal = false,
        bool isGreen = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.darkBrown : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isGreen
                ? Colors.green
                : (isTotal ? AppColors.darkBrown : Colors.black87),
          ),
        ),
      ],
    );
  }
}
