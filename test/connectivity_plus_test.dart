import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_plugin/mock_plugin.dart';

main() {
  late MockedPlugin connectivityPlugin;

  setUp(() {
    connectivityPlugin =
        setUpMockPlugin("dev.fluttercommunity.plus/connectivity");
  });

  group("checkConnectivity", () {
    test("error if not stub", () async {
      connectivityPlugin.stub("??");
      await expectLater(
        () async => await Connectivity().checkConnectivity(),
        throwsNoStubMockPluginError,
      );
    });
    test("not connected", () async {
      // arrange
      connectivityPlugin.stub("check").toResult((_) async => "none");
      // act
      final result = await Connectivity().checkConnectivity();
      // assert
      expect(result, ConnectivityResult.none);
      connectivityPlugin.verify("check").calledOnce();
    });
    test("unknown result", () async {
      // arrange
      connectivityPlugin.stub("check").toResult((_) async => "??");
      // act
      final result = await Connectivity().checkConnectivity();
      // assert
      expect(result, ConnectivityResult.none);
      connectivityPlugin.verify("check").calledOnce();
    });
    test("connected via wifi", () async {
      // arrange
      connectivityPlugin.stub("check").toResult((_) async => "wifi");
      // act
      final result = await Connectivity().checkConnectivity();
      // assert
      expect(result, ConnectivityResult.wifi);
      connectivityPlugin.verify("check").calledOnce();
    });
    test("connected via wifi [verify with stub call]", () async {
      // arrange
      final stubCall = connectivityPlugin.stub("check");
      stubCall.toResult((_) async => "wifi");
      // act
      final result = await Connectivity().checkConnectivity();
      // assert
      expect(result, ConnectivityResult.wifi);
      stubCall.verify.calledOnce();
      connectivityPlugin.verify("check").calledOnce();
    });
  });
}
