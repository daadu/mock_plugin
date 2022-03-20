part of '../mock_plugin.dart';

// E().toString should contain class name
Matcher _throwsWithPlatformException<E extends Exception>() =>
    throwsA(predicate(
            (e) => e is PlatformException && e.message!.contains(E.toString()),
        E.toString()));

final throwsNoStubMockPluginError =
_throwsWithPlatformException<NoStubMockPluginError>();

@visibleForTesting
class NoStubMockPluginError implements Exception {
  final MockedPlugin plugin;
  final MethodCall call;

  const NoStubMockPluginError(this.plugin, this.call);

  @override
  String toString() {
    return "\n\tNoStubMockPluginError: no stub for $call found for $plugin."
        "\n\tcalls: ${plugin._calls}"
        "\n\tstubs: ${plugin._stubs}"
        "\n";
  }
}