import '../../world.dart';
import 'package:gherkin/gherkin.dart';

import 'step_given_keyset.dart';
import 'step_given_storage_enabled.dart';
import 'step_then_error_response.dart';
import 'step_then_history_customMessageTypes.dart';
import 'step_then_history_messages.dart';
import 'step_then_messagesContainsType.dart';
import 'step_then_no_CustomType.dart';
import 'step_then_receive.dart';
import 'step_then_success_response.dart';
import 'step_when_fetchMessages.dart';
import 'step_when_fetch_custom_channel.dart';
import 'step_when_fetch_with_custom.dart';
import 'step_when_publish_with_type.dart';
import 'step_when_sendFile.dart';
import 'step_when_signal_with_type.dart';
import 'step_when_subscribe.dart';

final List<StepDefinitionGeneric<PubNubWorld>> customMessageTypeSteps = [
  StepGivenTheDemoKeyset(),
  StepGivenTheStorageEnabledKeyset(),
  StepWhenIPublishWithCustomType(),
  StepThenIReceiveSuccessfulResponsePublish(),
  StepThenIReceivePublishErrorResponse(),
  StepWhenISignalWithCustomType(),
  StepWhenISubscribeChannalForCustomMessageType(),
  StepWhenFetchMessagesWithMessageType(),
  StepThenIReceiveMessagesInSubscriptionResponse(),
  StepThenReceivedMessagesHasMessageTypes(),
  StepWhenFetchMessagesWithCustomMessageType(),
  StepThenHistoryReceivedMessagesHasMessageTypesInt(),
  StepWhenFetchMessagesWithParams(),
  StepWhenISendFileCustomType(),
  StepThenReceivedMessagesNoCustomMessageTypes(),
  StepThenHistoryReceivedMessagesHasCustomMessageTypes()
];