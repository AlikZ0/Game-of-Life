import '../network/api_exception.dart';

/// A lightweight sealed success/failure type used by repositories so callers
/// handle errors explicitly instead of relying on thrown exceptions bubbling
/// up through the UI.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(ApiException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  ApiException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Pattern-match both branches.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ApiException error) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Failure<T>(:final error) => onFailure(error),
      };

  /// Transform the success value, preserving failures.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Success<R>(transform(value)),
        Failure<T>(:final error) => Failure<R>(error),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final ApiException error;
}

/// Runs [body], mapping any thrown [ApiException] into a [Failure].
Future<Result<T>> guardResult<T>(Future<T> Function() body) async {
  try {
    return Result.success(await body());
  } on ApiException catch (e) {
    return Result.failure(e);
  } catch (e) {
    return Result.failure(ApiException(message: e.toString()));
  }
}
