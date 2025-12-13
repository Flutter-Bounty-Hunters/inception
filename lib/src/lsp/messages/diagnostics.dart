import 'common_types.dart';

class Diagnostic {
  const Diagnostic({
    required this.code,
    required this.message,
    required this.range,
    required this.severity,
    required this.source,
  });

  final String code;
  final String message;
  final Range range;
  final int severity;
  final String source;

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    return Diagnostic(
      code: json['code'] as String,
      message: json['message'] as String,
      range: Range.fromJson(json['range'] as Map<String, dynamic>),
      severity: json['severity'] as int,
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'range': range.toJson(),
      'severity': severity,
      'source': source,
    };
  }
}
