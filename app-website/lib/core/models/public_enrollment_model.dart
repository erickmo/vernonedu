/// Models for /api/v1/public/enrollment and /api/v1/public/contact

class EnrollmentRequest {
  final String batchId;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? referralCode;
  final Map<String, dynamic>? metadata;

  const EnrollmentRequest({
    required this.batchId,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.referralCode,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'batch_id': batchId,
        'name': name,
        'email': email,
        'phone': phone,
        if (address != null) 'address': address,
        if (referralCode != null) 'referral_code': referralCode,
        if (metadata != null) 'metadata': metadata,
      };
}

class EnrollmentResponse {
  final String enrollmentId;
  final String studentId;
  final String invoiceId;
  final String status;
  final String message;

  const EnrollmentResponse({
    required this.enrollmentId,
    required this.studentId,
    required this.invoiceId,
    required this.status,
    required this.message,
  });

  factory EnrollmentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return EnrollmentResponse(
      enrollmentId: data['enrollment_id'] as String? ?? '',
      studentId: data['student_id'] as String? ?? '',
      invoiceId: data['invoice_id'] as String? ?? '',
      status: data['status'] as String? ?? '',
      message: json['message'] as String? ?? data['message'] as String? ?? '',
    );
  }
}

class ContactRequest {
  final String name;
  final String email;
  final String phone;
  final String message;
  final String? subject;

  const ContactRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    this.subject,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        if (subject != null) 'subject': subject,
      };
}
