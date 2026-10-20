import 'package:signals_flutter/signals_flutter.dart';
import '../../core/result/result.dart';

abstract class AsyncViewModel {
  final loading = signal(false);
  final errorMessage = signal<String?>(null);
  final successMessage = signal<String?>(null);
  int _generation = 0;
  int _pending = 0;

  Future<Result<T>> run<T>(
    Future<Result<T>> Function() action, {
    void Function(T data)? onSuccess,
    String? successText,
  }) async {
    final generation = _generation;
    _pending++;
    loading.value = true;
    errorMessage.value = null;
    successMessage.value = null;
    try {
      final result = await action();
      if (generation != _generation) {
        return const Failure('A sessão foi alterada.');
      }
      if (result case Success<T>(:final data)) {
        onSuccess?.call(data);
        successMessage.value = successText;
      } else if (result case Failure<T>(:final message)) {
        errorMessage.value = message;
      }
      return result;
    } catch (error) {
      if (generation == _generation) {
        errorMessage.value = 'Não foi possível concluir a operação.';
      }
      return Failure('Não foi possível concluir a operação.', cause: error);
    } finally {
      if (generation == _generation) {
        _pending--;
        loading.value = _pending > 0;
      }
    }
  }

  void clearSession() {
    _generation++;
    _pending = 0;
    loading.value = false;
    errorMessage.value = null;
    successMessage.value = null;
    clearData();
  }

  void clearData();
}
