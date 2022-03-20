part of '../mock_plugin.dart';

class _CallCountVerifier {
  final int Function() _getCallCount;

  _CallCountVerifier._(this._getCallCount);

  void calledNever() => expect(_getCallCount.call(), isZero);

  void calledOnce() => expect(_getCallCount.call(), equals(1));

  void called(dynamic count) => expect(_getCallCount.call(), count);
}
