import '../../world.dart';
import 'package:gherkin/gherkin.dart';

import 'step_given_keyset.dart';
import 'step_then_error_response.dart';
import 'step_then_messagesContainsType.dart';
import 'step_then_receive.dart';
import 'step_then_success_response.dart';
import 'step_when_publish_with_type.dart';
import 'step_when_sendFile.dart';
import 'step_when_signal_with_type.dart';
import 'step_when_subscribe.dart';

final List<StepDefinitionGeneric<PubNubWorld>> customMessageTypeSteps = [
  StepGivenTheDemoKeyset(),
  StepWhenIPublishWithCustomType(),
  StepThenIReceiveSuccessfulResponsePublish(),
  StepThenIReceivePublishErrorResponse(),
  StepWhenISignalWithCustomType(),
  StepWhenISubscribeChannalForCustomMessageType(),
  StepThenIReceiveMessagesInSubscriptionResponse(),
  StepThenReceivedMessagesHasMessageTypes(),
  StepWhenISendFileCustomType(),
];