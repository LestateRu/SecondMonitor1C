class PaymentQRCode {
  final String qrCodeData;

  PaymentQRCode({
    required this.qrCodeData,
  });

  factory PaymentQRCode.fromJson(Map<String, dynamic> json) {
    return PaymentQRCode(
      qrCodeData: json['qrCodeData'] as String,
    );
  }
}