import 'package:flutter/material.dart';
import '../services/api_client.dart';

void showError(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : error is StateError
      ? error.message
      : 'Something went wrong. Please try again.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
