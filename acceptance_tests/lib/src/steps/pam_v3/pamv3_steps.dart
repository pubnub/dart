import '../../world.dart';
import 'step_given_authorizedUUID.dart';
import 'step_given_knownToken_with_UUID_pattern_permission.dart';
import 'step_given_knownToken_with_UUID_resource_permission.dart';
import 'step_given_knownToken_with_authorizedUUID.dart';
import 'step_given_pam_enabled_keyset.dart';
import 'step_given_resource__name_type.dart';
import 'step_given_resource_pattern_name_type.dart';
import 'step_given_resource_pattern_permission.dart';
import 'step_given_resource_permission.dart';
import 'step_given_ttl.dart';
import 'step_then_error_detail_location.dart';
import 'step_then_error_detail_location_type.dart';
import 'step_then_error_detail_message.dart';
import 'step_then_error_is_returned.dart';
import 'step_then_error_message.dart';
import 'step_then_error_source.dart';
import 'step_then_error_status_code.dart';
import 'step_then_parsedToken_Not_contains_authorizedUUID.dart';
import 'step_then_parsedtoken_contains_given_authorizedUUID.dart';
import 'step_then_token_contains_expected_pattern_permission.dart';
import 'step_then_token_contains_expected_resource_permission.dart';
import 'step_then_token_contains_pattern_permission.dart';
import 'step_then_token_contains_resource_permission.dart';
import 'step_then_token_contains_ttl.dart';
import 'step_when_I_attempt_to_grant.dart';
import 'step_when_grantToken.dart';
import 'step_when_parseToken.dart';

import 'package:gherkin/gherkin.dart';

final List<StepDefinitionGeneric<PubNubWorld>> pamv3Steps = [
  StepGivenAuthUUID(),
  StepGivenKnownTokenWithAuthorizedUUID(),
  StepGivenKnownTokenWithUUIDResourcePatternPermissions(),
  StepGivenKnownTokenWithUUIDResourcePermissions(),
  StepGivenPAMenabledKeyset(),
  StepGivenResourceNameAndType(),
  StepGivenResourcePatternNameAndType(),
  StepGivenResourcePatternPermission(),
  StepGivenResourcePermission(),
  StepGivenTtl(),
  StepThenErrorIsReturned(),
  StepThenErrorMessage(),
  StepThenErrorDetailLocationType(),
  StepThenErrorDetailLocation(),
  StepThenErrorDetailMessage(),
  StepThenErrorSource(),
  StepThenErrorStatusCode(),
  StepThenParsedTokenContainsGivenAuthorizedUUID(),
  StepThenParsedTokenShouldNotContainAuthorizedUUID(),
  StepThenTokenHasExpectedResourcePatternPermission(),
  StepThenTokenHasExpectedResourcePermission(),
  StepThenTokenHasResourcePatternPermission(),
  StepThenTokenHasResourcePermission(),
  StepThenTokenContainsTTL(),
  StepWhenGrantToken(),
  StepWhenAttemptGrantToken(),
  StepWhenParseToken()
];
