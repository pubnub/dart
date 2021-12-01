import 'package:gherkin/gherkin.dart';

import '../world.dart';
import 'step_given_demo_keyset.dart';
import 'pam_v3/pamv3_steps.dart' show pamv3Steps;
import 'step_given_channel.dart';
import 'step_when_i_add_a_message_action.dart';
import 'step_when_i_publish.dart';
import 'step_when_i_send_a_signal.dart';
import 'step_when_i_subscribe.dart';
import 'step_when_i_request_current_time.dart';
import 'step_when_i_fetch_message_actions.dart';
import 'step_when_i_delete_message_action.dart';
import 'step_message_history.dart';
import 'step_then_message_should_be_received_by_subscribers.dart';
import 'step_then_i_receive_the_message_in_my_subscribe_response.dart';
import 'step_then_i_receive_successful_response.dart';
import 'step_then_i_receive_error_response.dart';
import 'step_then_an_error_is_thrown.dart';
import 'step_then_response_contains_pagination_info.dart';

import 'steps_files.dart';
import 'steps_push.dart';

final List<StepDefinitionGeneric<PubNubWorld>> steps = [
  ...pamv3Steps,
  StepGivenChannel(),
  StepGivenDemoKeyset(),
  StepWhenIAddAMessageAction(),
  StepWhenIPublish(),
  StepWhenISubscribe(),
  StepWhenISendASignal(),
  StepWhenIRequestCurrentTime(),
  StepWhenIFetchMessageActions(),
  StepWhenIDeleteAMessageAction(),
  StepThenMessageShouldBeReceivedBySubscribers(),
  StepThenIReceiveTheMessageInMySubscribeResponse(),
  StepThenAnErrorIsThrown(),
  StepThenIReceiveSuccessfulResponse(),
  StepThenIReceiveErrorResponse(),
  StepThenResponseContainsPaginationInfo(),
  StepWhenIFetchMessageHistoryForSingleChannel(),
  StepWhenIFetchMessageHistoryForMultipleChannels(),
  StepWhenIFetchMessageHistoryWithMessageActions(),
  StepWhenIListFiles(),
  StepWhenIPublishFileMessage(),
  StepWhenIDeleteFile(),
  StepWhenIDownloadFile(),
  StepWhenIAddPushChannels(),
  StepWhenIAddPushChannelsWithoutTopic(),
  StepWhenIListPushChannels(),
  StepWhenIListPushChannelsWithoutTopic(),
  StepWhenIRemovePushChannels(),
  StepWhenIRemovePushChannelsWithoutTopic(),
  StepWhenIRemoveDevice(),
  StepWhenIRemoveDeviceWithTopic(),
];
