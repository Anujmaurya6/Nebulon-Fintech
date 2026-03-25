import 'package:dio/dio.dart';
import 'dart:convert';

void main() async {
  final dio = Dio(
      BaseOptions(
        baseUrl: 'https://mttjvyj6.us-east.insforge.app',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'apikey': 'ik_818b6b6dd19e16e9d768afbba191726d',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MTU2MTB9.A2Jj83_xTKadjREnNYxf0x5XzvQJIIzARkUOWBnflC4'
        },
      ),
    );
    
  try {
    final response = await dio.get('/api/database/records/transactions', queryParameters: {'order': 'created_at.desc'});
    print(response.data.runtimeType);
    final data = response.data as List? ?? [];
    print('Length: ${data.length}');
    
    // Test computing logic
    double income = 0;
    double expenses = 0;
    for (final json in data) {
      final rawType = (json['type'] ?? 'expense').toString().toLowerCase();
      String mappedType = 'expense';
      if (rawType == 'income' || rawType == 'credit') {
        mappedType = 'income';
      } else if (rawType == 'expense' || rawType == 'debit') {
        mappedType = 'expense';
      }
      final bool isIncome = mappedType == 'income';
      final amount = (json['amount'] ?? 0).toDouble();
      
      if (isIncome) income += amount;
      else expenses += amount;
    }
    
    print('Income: $income, Expenses: $expenses');
  } catch (e) {
    print('Error: $e');
  }
}
