// lib/utils/email_service.dart
import 'package:flutter/material.dart';

class EmailService {
  // For a real implementation, use a proper email service API like SendGrid
  // This is a simplified version for demonstration purposes
  Future<bool> sendPasswordResetEmail(String email, String name, String resetCode) async {
    try {
      // In a real implementation, you would use an email service API
      // For development, we'll just simulate sending an email
      debugPrint('DEVELOPMENT MODE: Email would be sent to $email');
      debugPrint('Email content:');
      debugPrint('Subject: Reset Your Password');
      debugPrint('Body: Hello $name,\n\n');
      debugPrint('Your password reset code is: $resetCode\n\n');
      debugPrint('This code will expire in 1 hour.\n\n');
      debugPrint('If you did not request a password reset, please ignore this email.\n\n');
      debugPrint('Regards,\nRwanda Bus Team');
      
      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));
      
      // Return success
      return true;
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }
}