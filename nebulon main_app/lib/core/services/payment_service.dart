import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse)? onSuccess;
  final Function(PaymentFailureResponse)? onFailure;
  final Function(ExternalWalletResponse)? onWallet;

  PaymentService({this.onSuccess, this.onFailure, this.onWallet}) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onWallet?.call(response);
  }

  void openCheckout({
    required double amount,
    required String name,
    required String email,
    required String defaultContact,
  }) {
    var options = {
      'key':
          'rzp_test_demo12345', // In production, this would come from an env file or backend integration
      'amount': (amount * 100)
          .toInt(), // Razorpay expects amount in smallest currency sub-unit (paise for INR)
      'name': 'Smart Vault Funding',
      'description': 'Account Deposit',
      'prefill': {'contact': defaultContact, 'email': email},
      'theme': {'color': '#101A77'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
