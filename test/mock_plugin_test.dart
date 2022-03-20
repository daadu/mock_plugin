import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_plugin/mock_plugin.dart';

// E().toString should contain class name
Matcher _throwsWithPlatformException<E extends Exception>() =>
    throwsA(predicate(
        (e) => e is PlatformException && e.message!.contains(E.toString()),
        E.toString()));

final throwsNoStubMockPluginError =
    _throwsWithPlatformException<NoStubMockPluginError>();

void main() {
  group("connectivity_plus", () {
    late MockedPlugin connectivityPlugin;

    setUp(() {
      connectivityPlugin =
          setUpMockPlugin("dev.fluttercommunity.plus/connectivity");
    });

    group("checkConnectivity", () {
      test("error if not stub", () async {
        connectivityPlugin.when("??");
        await expectLater(
          () async => await Connectivity().checkConnectivity(),
          throwsNoStubMockPluginError,
        );
      });
      test("not connected", () async {
        // arrange
        connectivityPlugin.when("check").thenResult(() async => "none");
        // act
        final result = await Connectivity().checkConnectivity();
        // assert
        expect(result, ConnectivityResult.none);
        connectivityPlugin.verify("check").calledOnce();
      });
      test("unknown result", () async {
        // arrange
        connectivityPlugin.when("check").thenResult(() async => "??");
        // act
        final result = await Connectivity().checkConnectivity();
        // assert
        expect(result, ConnectivityResult.none);
        connectivityPlugin.verify("check").calledOnce();
      });
      test("connected via wifi", () async {
        // arrange
        connectivityPlugin.when("check").thenResult(() async => "wifi");
        // act
        final result = await Connectivity().checkConnectivity();
        // assert
        expect(result, ConnectivityResult.wifi);
        connectivityPlugin.verify("check").calledOnce();
      });
      test("connected via wifi [verify with stub call]", () async {
        // arrange
        final stubCall = connectivityPlugin.when("check");
        stubCall.thenResult(() async => "wifi");
        // act
        final result = await Connectivity().checkConnectivity();
        // assert
        expect(result, ConnectivityResult.wifi);
        stubCall.verify.calledOnce();
        connectivityPlugin.verify("check").calledOnce();
      });
    });
  });
}
