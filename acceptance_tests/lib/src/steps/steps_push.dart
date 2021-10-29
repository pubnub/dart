import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepWhenIListPushChannels
    extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I list {gateway} push channels$');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'listPushChannels';
      world.latestResult =
          await world.pubnub.listPushChannels('deviceId', gateway);
    } catch (e) {
      world.latestResultType = 'listPushChannelsFailureWithoutTopic';
      world.latestResult = e;
    }
  }
}

class StepWhenIListPushChannelsWithoutTopic
    extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I list {gateway} push channels with topic');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'listPushChannels';
      world.latestResult = await world.pubnub
          .listPushChannels('deviceId', gateway, topic: 'topic');
    } catch (e) {
      world.latestResultType = 'listPushChannelsFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIAddPushChannels
    extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I add {gateway} push channels$');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'addPushChannels';
      world.latestResult = await world.pubnub
          .addPushChannels('deviceId', gateway, {'channel-1'});
    } catch (e) {
      world.latestResultType = 'addPushChannelsFailureWithoutTopic';
      world.latestResult = e;
    }
  }
}

class StepWhenIAddPushChannelsWithoutTopic
    extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I add {gateway} push channels with topic');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'addPushChannels';
      world.latestResult = await world.pubnub
          .addPushChannels('deviceId', gateway, {'channel-1'}, topic: 'topic');
    } catch (e) {
      world.latestResultType = 'addPushChannelsFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIRemovePushChannels
    extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I remove {gateway} push channels$');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'removePushChannels';
      world.latestResult = await world.pubnub
          .removePushChannels('deviceId', gateway, {'channel-1'});
    } catch (e) {
      world.latestResultType = 'removePushChannelsFailureWithoutTopic';
      world.latestResult = e;
    }
  }
}

class StepWhenIRemovePushChannelsWithoutTopic
    extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I remove {gateway} push channels with topic');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'removePushChannels';
      world.latestResult = await world.pubnub.removePushChannels(
          'deviceId', gateway, {'channel-1'},
          topic: 'topic');
    } catch (e) {
      world.latestResultType = 'removePushChannelsFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIRemoveDevice extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I remove {gateway} device$');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'removeDevice';
      world.latestResult = await world.pubnub.removeDevice('deviceId', gateway);
    } catch (e) {
      world.latestResultType = 'removeDeviceFailureWithoutTopic';
      world.latestResult = e;
    }
  }
}

class StepWhenIRemoveDeviceWithTopic
    extends When1WithWorld<PushGateway, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I remove {gateway} device with topic');

  @override
  Future<void> executeStep(PushGateway gateway) async {
    try {
      world.latestResultType = 'removeDevice';
      world.latestResult =
          await world.pubnub.removeDevice('deviceId', gateway, topic: 'topic');
    } catch (e) {
      world.latestResultType = 'removeDeviceFailure';
      world.latestResult = e;
    }
  }
}
