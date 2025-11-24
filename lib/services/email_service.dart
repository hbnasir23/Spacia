import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class EmailService {

    static Future<void> sendOrderReceipt({
    required String userEmail,
    required String userName,
    required String orderId,
    required List<OrderItem> items,
    required double totalAmount,
    required String deliveryAddress,
    String? paymentDetails, // optional, e.g. 'Paid with Visa **** 4242'
  }) async {
    try {
      // Create email document in Firestore
      // This will be picked up by a Cloud Function to send the actual email
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [userEmail],
        'message': {
          'subject': 'Order Confirmation - Spacia #$orderId',
          'html': _generateReceiptHTML(
            userName: userName,
            orderId: orderId,
            items: items,
            totalAmount: totalAmount,
            deliveryAddress: deliveryAddress,
            paymentDetails: paymentDetails,
          ),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending email: $e');
      // Don't throw error - email sending is not critical
    }
  }

  static String _generateReceiptHTML({
    required String userName,
    required String orderId,
    required List<OrderItem> items,
    required double totalAmount,
    required String deliveryAddress,
    String? paymentDetails,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} at ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    String itemsHTML = '';
    for (var item in items) {
      itemsHTML += '''
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eee;">
            ${item.productName}
          </td>
          <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">
            ${item.quantity}
          </td>
          <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">
            \$${item.price.toStringAsFixed(2)}
          </td>
          <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right; font-weight: 600;">
            \$${(item.price * item.quantity).toStringAsFixed(2)}
          </td>
        </tr>
      ''';
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Order Receipt</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Arial', sans-serif; background-color: #f5f5f5;">
      <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <!-- Header -->
        <div style="background-color: #4A3428; padding: 30px; text-align: center;">
          <h1 style="color: #ffffff; margin: 0; font-size: 28px;">Spacia</h1>
          <p style="color: #E8D5C4; margin: 10px 0 0 0; font-size: 14px;">Your AR Shopping Destination</p>
        </div>

        <!-- Content -->
        <div style="padding: 30px;">
          <h2 style="color: #4A3428; margin-top: 0;">Order Confirmation</h2>
          
          <p style="color: #666; font-size: 16px; line-height: 1.6;">
            Dear $userName,
          </p>
          
          <p style="color: #666; font-size: 16px; line-height: 1.6;">
            Thank you for your order! We've received your order and will process it shortly.
          </p>

          <!-- Order Details Box -->
          <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 8px 0; color: #666;">Order ID:</td>
                <td style="padding: 8px 0; text-align: right; font-weight: 600; color: #4A3428;">#$orderId</td>
              </tr>
              <tr>
                <td style="padding: 8px 0; color: #666;">Order Date:</td>
                <td style="padding: 8px 0; text-align: right; font-weight: 600; color: #4A3428;">$dateStr</td>
              </tr>
              <tr>
                <td style="padding: 8px 0; color: #666;">Payment Method:</td>
                <td style="padding: 8px 0; text-align: right; font-weight: 600; color: #4A3428;">${paymentDetails ?? 'Cash on Delivery'}</td>
              </tr>
              <tr>
                <td style="padding: 8px 0; color: #666; vertical-align: top;">Delivery Address:</td>
                <td style="padding: 8px 0; text-align: right; font-weight: 600; color: #4A3428;">$deliveryAddress</td>
              </tr>
            </table>
          </div>

          <!-- Order Items -->
          <h3 style="color: #4A3428; margin-top: 30px;">Order Items</h3>
          <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
            <thead>
              <tr style="background-color: #f5f5f5;">
                <th style="padding: 12px; text-align: left; color: #4A3428; font-weight: 600;">Product</th>
                <th style="padding: 12px; text-align: center; color: #4A3428; font-weight: 600;">Qty</th>
                <th style="padding: 12px; text-align: right; color: #4A3428; font-weight: 600;">Price</th>
                <th style="padding: 12px; text-align: right; color: #4A3428; font-weight: 600;">Total</th>
              </tr>
            </thead>
            <tbody>
              $itemsHTML
            </tbody>
            <tfoot>
              <tr>
                <td colspan="3" style="padding: 20px 12px 12px 12px; text-align: right; font-size: 18px; font-weight: 600; color: #4A3428;">
                  Total Amount:
                </td>
                <td style="padding: 20px 12px 12px 12px; text-align: right; font-size: 20px; font-weight: bold; color: #4A3428;">
                  \$${totalAmount.toStringAsFixed(2)}
                </td>
              </tr>
            </tfoot>
          </table>

          <!-- Info Box -->
          <div style="background-color: #E8D5C4; padding: 20px; border-radius: 8px; margin: 30px 0;">
            <p style="margin: 0; color: #4A3428; font-size: 14px; line-height: 1.6;">
              <strong>💡 What's Next?</strong><br>
              Your order will be processed and dispatched soon. You'll receive an update when your order is on its way.
              Please keep the exact amount ready for Cash on Delivery.
            </p>
          </div>

          <p style="color: #666; font-size: 16px; line-height: 1.6;">
            If you have any questions about your order, please don't hesitate to contact us.
          </p>

          <p style="color: #666; font-size: 16px; line-height: 1.6;">
            Best regards,<br>
            <strong style="color: #4A3428;">The Spacia Team</strong>
          </p>
        </div>

        <!-- Footer -->
        <div style="background-color: #f5f5f5; padding: 20px; text-align: center; border-top: 1px solid #ddd;">
          <p style="margin: 0; color: #999; font-size: 12px;">
            This is an automated email. Please do not reply to this message.
          </p>
          <p style="margin: 10px 0 0 0; color: #999; font-size: 12px;">
            © ${DateTime.now().year} Spacia. All rights reserved.
          </p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Compatibility wrapper (explicit name) to accept paymentDetails
  static Future<void> sendOrderReceiptWithDetails({
    required String userEmail,
    required String userName,
    required String orderId,
    required List<OrderItem> items,
    required double totalAmount,
    required String deliveryAddress,
    String? paymentDetails,
  }) async {
    return sendOrderReceipt(
      userEmail: userEmail,
      userName: userName,
      orderId: orderId,
      items: items,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      paymentDetails: paymentDetails,
    );
  }
}
