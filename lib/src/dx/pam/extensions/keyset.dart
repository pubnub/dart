import 'package:pubnub/src/core/core.dart';

extension PamKeySetExtension on Keyset {
  Map<String, Map<String, String>> get resourceTokens =>
      this.settings[#resourceTokens];

  Map<String, Map<String, String>> get patternTokens =>
      this.settings[#patternTokens];

  void addResourceTokens(String resourceType, Map<String, String> resources) {
    if (this.settings[#resourceTokens] is! Map)
      this.settings[#resourceTokens] = <String, Map<String, String>>{};
    if (this.settings[#resourceTokens][resourceType] is! Map) {
      this.settings[#resourceTokens][resourceType] = resources;
    }
    this.settings[#resourceTokens][resourceType].addAll(resources);
  }

  void addResourcePatternTokens(
      String resourceType, Map<String, String> resources) {
    if (this.settings[#patternTokens] is! Map)
      this.settings[#patternTokens] = <String, Map<String, String>>{};
    if (this.settings[#patternTokens][resourceType] is! Map) {
      this.settings[#patternTokens][resourceType] = resources;
    }
    this.settings[#patternTokens][resourceType].addAll(resources);
  }
}
