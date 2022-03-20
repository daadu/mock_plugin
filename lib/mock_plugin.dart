library mock_plugin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

part 'src/error.dart';
part 'src/verifier.dart';

typedef _Result = Future<Object?>?;
typedef _ResultCallback = _Result Function();

@visibleForTesting
class StubMethod {
  final dynamic _method;
  final dynamic _arguments;
  _ResultCallback? _callback;
  int _callCount = 0;
  late _CallCountVerifier _verifier;

  StubMethod._(this._method, this._arguments) {
    _verifier = _CallCountVerifier._(() => _callCount);
  }

  @override
  String toString() => "StubMethod($_method, $_arguments, called: $_callCount)";

  _CallCountVerifier get verify => _verifier;

  void thenResult(_ResultCallback callback) => _callback = callback;

  _Result _call() {
    _callCount++;
    return _callback?.call();
  }
}

@visibleForTesting
class MockedPlugin {
  final MethodChannel _methodChannel;
  final List<MethodCall> _calls = [];
  final List<StubMethod> _stubs = [];

  MockedPlugin._(this._methodChannel) {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(_methodChannel, _methodHandler);
  }

  @override
  String toString() => "MockedPlugin(${_methodChannel.name})";

  StubMethod when(dynamic method, [dynamic arguments = anything]) {
    final stubMethod = StubMethod._(method, arguments);
    _stubs.add(stubMethod);
    return stubMethod;
  }

  _CallCountVerifier verify(dynamic method, [dynamic arguments = anything]) =>
      _CallCountVerifier._(() => _calls
          .where((call) =>
              _matchesMethod(method, call.method) &&
              _matchesArgs(arguments, call.arguments))
          .length);

  void reset() {
    _calls.clear();
    _stubs.clear();
  }

  bool _matchesMethod(dynamic method, String calledMethod) {
    if (method is Matcher) return method.matches(calledMethod, {});

    return method == calledMethod;
  }

  bool _matchesArgs(dynamic arguments, dynamic calledArgs) {
    if (arguments is Matcher) return arguments.matches(calledArgs, {});

    return arguments == calledArgs;
  }

  _Result _methodHandler(MethodCall call) async {
    // match stub to call - call if found or error
    for (final stub in _stubs) {
      // check if  method and arg matches
      if (_matchesMethod(stub._method, call.method) &&
          _matchesArgs(stub._arguments, call.arguments)) {
        // add to _calls
        _calls.add(call);

        // call stub and return result
        return stub._call();
      }
    }

    // throw "no-stub" error
    throw NoStubMockPluginError(this, call);
  }

  void _tearDown() {
    reset();
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(_methodChannel, null);
  }
}

@visibleForTesting
MockedPlugin setUpMockPlugin(
  String methodChannelName, {
  bool shouldTearDown = true,
}) {
  TestWidgetsFlutterBinding.ensureInitialized();

  // setMockMethodCallHandler for the plugin specified
  final methodChannel = MethodChannel(methodChannelName);
  final mockPlugin = MockedPlugin._(methodChannel);

  // tearDown mock plugin after test
  if (shouldTearDown) {
    addTearDown(() => mockPlugin._tearDown());
  }

  return mockPlugin;
}
