import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://mttjvyj6.us-east.insforge.app/api/database/records/transactions');
  final apiKey = 'ik_818b6b6dd19e16e9d768afbba191726d';
  final anonJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MTU2MTB9.A2Jj83_xTKadjREnNYxf0x5XzvQJIIzARkUOWBnflC4';
  
  final response = await http.post(
    url,
    headers: {
      'apikey': apiKey,
      'Authorization': 'Bearer $anonJwt',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'id': 'test-dart-002',
      'title': 'Coffee',
      'amount': 199.0,
      'type': 'DEBIT',
      'category': 'Food',
      'description': 'test',
      'account': 'Primary'
    }),
  );
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
