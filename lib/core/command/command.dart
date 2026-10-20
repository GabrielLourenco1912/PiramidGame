import 'package:signals_flutter/signals_flutter.dart';

import '../result/result.dart';

typedef CommandAction<T> = Future<Result<T>> Function();
typedef CommandAction1<P, T> = Future<Result<T>> Function(P parameter);

class Command<T> {
  Command(this._action);

  final CommandAction<T> _action;

  final isRunning = signal(false);
  final errorMessage = signal<String?>(null);
  final lastResult = signal<Result<T>?>(null);

  Future<Result<T>> execute() async {
    if (isRunning.value) {
      return const Failure('Aguarde a acao atual terminar.');
    }

    isRunning.value = true;
    errorMessage.value = null;

    try {
      final result = await _action();
      lastResult.value = result;
      if (result case Failure<T>(:final message)) {
        errorMessage.value = message;
      }
      return result;
    } catch (error) {
      final failure = Failure<T>(
        'Nao foi possivel concluir a acao.',
        cause: error,
      );
      lastResult.value = failure;
      errorMessage.value = failure.message;
      return failure;
    } finally {
      isRunning.value = false;
    }
  }
}

class Command1<P, T> {
  Command1(this._action);

  final CommandAction1<P, T> _action;

  final isRunning = signal(false);
  final errorMessage = signal<String?>(null);
  final lastResult = signal<Result<T>?>(null);

  Future<Result<T>> execute(P parameter) async {
    if (isRunning.value) {
      return const Failure('Aguarde a acao atual terminar.');
    }

    isRunning.value = true;
    errorMessage.value = null;

    try {
      final result = await _action(parameter);
      lastResult.value = result;
      if (result case Failure<T>(:final message)) {
        errorMessage.value = message;
      }
      return result;
    } catch (error) {
      final failure = Failure<T>(
        'Nao foi possivel concluir a acao.',
        cause: error,
      );
      lastResult.value = failure;
      errorMessage.value = failure.message;
      return failure;
    } finally {
      isRunning.value = false;
    }
  }
}
