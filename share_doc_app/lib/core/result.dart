import 'failures.dart';

class Result<T> {
  final T? value;
  final Failure? failure;

  const Result.ok(this.value) : failure = null;
  const Result.fail(this.failure) : value = null;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) fail,
  }) {
    if (isSuccess) return ok(value as T);
    return fail(failure!);
  }
}
