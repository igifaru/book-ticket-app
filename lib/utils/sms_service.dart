// lib/utils/sms_service.dart
import 'package:flutter/material.dart';

class SMSService {
  // For a real implementation, use a proper SMS service API like Twilio or Africa's Talking
  // This is a simplified version for demonstration purposes
  // In SMSService
  Future<bool> sendPasswordResetSMS(
    String phoneNumber,
    String name,
    String resetCode,
  ) async {
    try {
      print("\n===========================================");
      print("VERIFICATION CODE: $resetCode");
      print("===========================================\n");

      await Future.delayed(Duration(seconds: 1));

      // Return success
      return true;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }
}
