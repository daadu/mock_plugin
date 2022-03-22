library mock_plugin;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

part 'src/error.dart';
part 'src/verifier.dart';

typedef _Result = Future<Object?>?;
typedef _ResultCallback = _Result Function(MethodCall call);

bool _match(dynamic actual, dynamic matcher) =>
    matcher is Matcher ? matcher.matches(actual, {}) : actual == matcher;

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

  void toResult(_ResultCallback callback) => _callback = callback;

  _Result _call(MethodCall call) {
    assert(_match(call.method, _method));
    assert(_match(call.arguments, _arguments));

    _callCount++;
    return _callback?.call(call);
  }
}

class StubFor {
  Future<Object?>? Function() forCall;

  StubFor(this.forCall);
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

  StubMethod stub(dynamic method, [dynamic arguments = anything]) {
    final stubMethod = StubMethod._(method, arguments);
    _stubs.add(stubMethod);
    return stubMethod;
  }

  bool _shouldCapture = false;
  StubMethod? _capturedStub;

  void _startCapturing() {
    assert(_shouldCapture == false, "Not already capturing");
    _shouldCapture = true;
    _capturedStub = null;
  }

  void _stopCapturing() {
    assert(_shouldCapture, "Should be capturing");
    assert(_capturedStub != null, "Should capture something");
    _shouldCapture = false;
  }

  StubMethod Function(dynamic forCall) get stubFor {
    _startCapturing();
    return (forCall) {
      print("forCall: $forCall");
      _stopCapturing();
      return _capturedStub!;
    };
  }

  _CallCountVerifier verify(dynamic method, [dynamic arguments = anything]) =>
      _CallCountVerifier._(() => _calls
          .where((call) =>
              _match(call.method, method) && _match(call.arguments, arguments))
          .length);

  void reset() {
    _calls.clear();
    _stubs.clear();
  }

  _Result _methodHandler(MethodCall call) async {
    print("called: $call");
    if (_shouldCapture) {
      _capturedStub = StubMethod._(call.method, call.arguments);
      return null;
    }

    // match stub to call - call if found or error
    for (final stub in _stubs) {
      // check if method and arg matches
      if (_match(call.method, stub._method) &&
          _match(call.arguments, stub._arguments)) {
        // add to _calls
        _calls.add(call);

        // call stub and return result
        return stub._call(call);
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
