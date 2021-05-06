part of 'acceptance_tests.dart';

extension EnvExtension on String {
  bool get asBool {
    switch (toLowerCase()) {
      case 'true':
        return true;
      case 'false':
      default:
        return false;
    }
  }
}

late final SKIP_ASSEMBLY = env['SKIP_ASSEMBLY']?.asBool ?? false;
late final FORCE_ASSEMBLY = env['FORCE_ASSEMBLY']?.asBool ?? false;
late final SKIP_BUILD = env['SKIP_BUILD']?.asBool ?? false;
late final FORCE_BUILD = env['FORCE_BUILD']?.asBool ?? false;
late final GITHUB_TOKEN = env['GITHUB_TOKEN'] ?? '';
late final DEBUG = env['DEBUG']?.asBool ?? false;
