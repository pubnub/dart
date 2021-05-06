import 'package:gherkin/gherkin.dart';

import '../world.dart';
import 'step_given_channel.dart';
import 'step_when_i_publish.dart';
import 'step_then_message_should_be_received_by_subscribers.dart';
import 'step_then_i_receive_the_message_in_my_subscribe_response.dart';
import 'step_when_i_subscribe.dart';
import 'step_given_demo_keyset.dart';
import 'step_then_i_receive_successful_response.dart';

final List<StepDefinitionGeneric<PubNubWorld>> steps = [
  StepGivenChannel(),
  StepWhenIPublish(),
  StepThenMessageShouldBeReceivedBySubscribers(),
  StepWhenISubscribe(),
  StepThenIReceiveTheMessageInMySubscribeResponse(),
  StepGivenDemoKeyset(),
  StepThenIReceiveSuccessfulResponse()
];
