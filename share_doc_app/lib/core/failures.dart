enum FailureType { network, auth, validation, aiParse, server, unknown }

class Failure {
  final FailureType type;
  final String message;

  const Failure(this.type, this.message);

  factory Failure.network([String message = 'Network error']) =>
      Failure(FailureType.network, message);

  factory Failure.auth([String message = 'Authentication error']) =>
      Failure(FailureType.auth, message);

  factory Failure.validation(String message) =>
      Failure(FailureType.validation, message);

  factory Failure.aiParse([String message = 'AI parsing failed']) =>
      Failure(FailureType.aiParse, message);

  factory Failure.server([String message = 'Server error']) =>
      Failure(FailureType.server, message);

  factory Failure.unknown([String message = 'Unknown error']) =>
      Failure(FailureType.unknown, message);

  @override
  String toString() => 'Failure($type: $message)';
}
