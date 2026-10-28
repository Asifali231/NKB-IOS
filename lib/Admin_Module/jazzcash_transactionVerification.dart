import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionStatus {
  final String responseCode;
  final String responseMessage;
  final String paymentResponseCode;
  final String paymentResponseMessage;
  final String status;

  TransactionStatus({
    required this.responseCode,
    required this.responseMessage,
    required this.paymentResponseCode,
    required this.paymentResponseMessage,
    required this.status,
  });

  factory TransactionStatus.fromJson(Map<String, dynamic> json) {
    return TransactionStatus(
      responseCode: json['pp_ResponseCode'] ?? '',
      responseMessage: json['pp_ResponseMessage'] ?? '',
      paymentResponseCode: json['pp_PaymentResponseCode'] ?? '',
      paymentResponseMessage: json['pp_PaymentResponseMessage'] ?? '',
      status: json['pp_Status'] ?? '',
    );
  }
}

class JazzCash_StatusInq extends StatefulWidget {
  @override
  _JazzCash_StatusInqState createState() => _JazzCash_StatusInqState();
}

class _JazzCash_StatusInqState extends State<JazzCash_StatusInq> {
  final _formKey = GlobalKey<FormState>();
  final _txnRefNoController = TextEditingController();
  TransactionStatus? _transactionStatus;
  bool _isLoading = false;
  String? _errorMessage;

  // Configuration
  // static const String merchantId = 'MC142126';
  // static const String password = 'hb7x50d0c2';
  // static const String integrityKey = 'xx3dg1d4s2';
  // static const String apiEndpoint =
  //     'https://sandbox.jazzcash.com.pk/ApplicationAPI/API/PaymentInquiry/Inquire';
  //


  static const String merchantId = 'MC142126';
  static const String password = 'hb7x50d0c2';
  static const String integrityKey = 'xx3dg1d4s2';
  static const String apiEndpoint =
      'https://onlinepayments.jazzcash.com.pk/payment-orchestrator/api/v1/rest/payments/status/inquiry';


  String _generateSecureHash(Map<String, String> params) {
    var sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    String hashString = integrityKey;
    sortedParams.forEach((key, value) {
      hashString += '&$value';
    });

    var key = utf8.encode(integrityKey);
    var bytes = utf8.encode(hashString);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);

    return digest.toString().toUpperCase();
  }

  Future<void> _checkTransactionStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _transactionStatus = null;
    });

    try {
      final params = {
        'pp_MerchantID': merchantId,
        'pp_Password': password,
        'pp_TxnRefNo': _txnRefNoController.text,
      };

      final secureHash = _generateSecureHash(params);
      final requestBody = {
        ...params,
        'pp_SecureHash': secureHash,
      };

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _transactionStatus = TransactionStatus.fromJson(responseData);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch transaction status. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Verify Transactions',
          style: GoogleFonts.poppins(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF2D3748)),
            onPressed: () {
              setState(() {
                _txnRefNoController.clear();
                _transactionStatus = null;
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
      body: Expanded(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status Inquiry',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Enter transaction reference number to check status',
                                style: GoogleFonts.inter(
                                  color: Color(0xFF718096),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 24),
                              TextFormField(
                                controller: _txnRefNoController,
                                style: GoogleFonts.inter(),
                                decoration: InputDecoration(
                                  labelText: 'Transaction Reference',
                                  labelStyle: TextStyle(color: Color(0xFF718096)),
                                  hintText: 'Enter transaction reference number',
                                  filled: true,
                                  fillColor: Color(0xFFF7FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFF3B82F6),
                                      width: 1,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a transaction reference number';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _checkTransactionStatus,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                      : Text(
                                    'Check Status',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Color(0xFFDC2626),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Color(0xFFDC2626),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_transactionStatus != null) ...[
                        SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        _transactionStatus!.paymentResponseCode,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              _transactionStatus!.paymentResponseCode,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          _transactionStatus!.status,
                                          style: GoogleFonts.inter(
                                            color: _getStatusColor(
                                              _transactionStatus!.paymentResponseCode,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              _buildStatusDetailRow(
                                'Response Code:',
                                _transactionStatus!.responseCode,
                              ),
                              _buildStatusDetailRow(
                                'Response Message:',
                                _transactionStatus!.responseMessage,
                              ),
                              _buildStatusDetailRow(
                                'Payment Response Code:',
                                _transactionStatus!.paymentResponseCode,
                              ),
                              _buildStatusDetailRow(
                                'Payment Message:',
                                _transactionStatus!.paymentResponseMessage,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String responseCode) {
    switch (responseCode) {
      case '121':
        return Color(0xFF059669);
      case '000':
        return Color(0xFF3B82F6);
      default:
        return Color(0xFFDC2626);
    }
  }

  Widget _buildStatusDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _txnRefNoController.dispose();
    super.dispose();
  }
}