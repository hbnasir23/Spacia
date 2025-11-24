import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stripe_keys.dart';

class StripeService {
  // Create PaymentIntent
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amountCents,
    String currency = 'usd',
    String? transferDestinationAccountId,
    String description = '',
  }) async {
    final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

    // Calculate 10% admin fee
    final int applicationFee = (amountCents * 0.10).round();

    final body = <String, String>{
      'amount': amountCents.toString(),
      'currency': currency,
      'payment_method_types[]': 'card',
      'description': description,
    };

    // If transferring to connected account
    if (transferDestinationAccountId != null &&
        transferDestinationAccountId.isNotEmpty) {
      body['application_fee_amount'] = applicationFee.toString();
      body['transfer_data[destination]'] = transferDestinationAccountId;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Stripe create PaymentIntent failed: ${response.statusCode} ${response.body}');
    }

    return json.decode(response.body);
  }

  // Confirm PaymentIntent
  static Future<Map<String, dynamic>> confirmPaymentIntent(
      String paymentIntentId, String paymentMethodId) async {
    final url = Uri.parse(
        'https://api.stripe.com/v1/payment_intents/$paymentIntentId/confirm');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'payment_method': paymentMethodId,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Stripe confirm PaymentIntent failed: ${response.statusCode} ${response.body}');
    }

    return json.decode(response.body);
  }

  // Retrieve card info safely (NO UNSUPPORTED EXPANSIONS)
  static Future<Map<String, dynamic>> retrievePaymentMethod(
      String paymentIntentId) async {
    // VALID expansion (only expand top-level "charges")
    final url = Uri.parse(
        'https://api.stripe.com/v1/payment_intents/$paymentIntentId?expand[]=charges');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $stripeSecretKey',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Stripe retrieve PaymentIntent failed: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> resp = json.decode(response.body);

    try {
      // charges.data[0]
      final charges = resp['charges']?['data'];
      if (charges is List && charges.isNotEmpty) {
        final charge = charges[0];

        // payment_method_details.card
        final pmDetails = charge['payment_method_details'];
        if (pmDetails is Map && pmDetails['card'] is Map) {
          return pmDetails['card']; // {brand: visa, last4: 4242, exp_month: ..}
        }

        // fallback: payment_method (expanded basic info)
        final pm = charge['payment_method'];
        if (pm is Map && pm['card'] is Map) {
          return pm['card'];
        }
      }
    } catch (_) {}

    return <String, dynamic>{};
  }
}
