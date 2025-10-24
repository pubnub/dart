part of '../presence_test.dart';

// Mock response templates for presence tests

const _hereNowSuccessResponse = '''
{
  "status": 200,
  "message": "OK",
  "payload": {
    "total_occupancy": 2,
    "total_channels": 1,
    "channels": {
      "test-channel": {
        "occupancy": 2,
        "uuids": ["user1", "user2"]
      }
    }
  }
}
''';

const _hereNowSingleChannelResponse = '''
{
  "status": 200,
  "message": "OK",
  "occupancy": 1,
  "uuids": ["single-user"]
}
''';

const _hereNowMultiChannelResponse = '''
{
  "status": 200,
  "message": "OK",
  "payload": {
    "total_occupancy": 3,
    "total_channels": 2,
    "channels": {
      "channel1": {
        "occupancy": 2,
        "uuids": ["user1", "user2"]
      },
      "channel2": {
        "occupancy": 1,
        "uuids": ["user3"]
      }
    }
  }
}
''';

const _hereNowWithStateResponse = '''
{
  "status": 200,
  "message": "OK",
  "occupancy": 1,
  "uuids": [
    {
      "uuid": "user-with-state",
      "state": {
        "mood": "happy",
        "status": "online",
        "location": "office"
      }
    }
  ]
}
''';

const _hereNowNoUuidsResponse = '''
{
  "status": 200,
  "message": "OK",
  "occupancy": 2
}
''';

const _hereNowEmptyChannelResponse = '''
{
  "status": 200,
  "message": "OK",
  "occupancy": 0,
  "uuids": []
}
''';

const _hereNowErrorResponse = '''
{
  "status": 403,
  "error": true,
  "message": "Forbidden",
  "service": "Presence"
}
''';

// Additional mock responses for edge cases

const _hereNowGlobalResponse = '''
{
  "status": 200,
  "message": "OK",
  "payload": {
    "total_occupancy": 5,
    "total_channels": 3,
    "channels": {
      "channel1": {
        "occupancy": 2,
        "uuids": ["user1", "user2"]
      },
      "channel2": {
        "occupancy": 1,
        "uuids": ["user3"]
      },
      "channel3": {
        "occupancy": 2,
        "uuids": [
          {
            "uuid": "user4",
            "state": {"status": "active"}
          },
          "user5"
        ]
      }
    }
  }
}
''';

final _hereNowLargeResponse = '''
{
  "status": 200,
  "message": "OK",
  "payload": {
    "total_occupancy": 1000,
    "total_channels": 1,
    "channels": {
      "large-channel": {
        "occupancy": 1000,
        "uuids": [''' +
    List.generate(1000, (i) => '"user$i"').join(',') +
    ''']
      }
    }
  }
}
''';

const _hereNowMixedStateResponse = '''
{
  "status": 200,
  "message": "OK",
  "occupancy": 3,
  "uuids": [
    "simple-user",
    {
      "uuid": "user-with-state",
      "state": {
        "mood": "excited",
        "activity": "coding"
      }
    },
    {
      "uuid": "another-user",
      "state": {
        "location": "home",
        "device": "mobile"
      }
    }
  ]
}
''';
