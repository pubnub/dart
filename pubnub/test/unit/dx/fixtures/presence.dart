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

const _hereNowWithNextOffsetNeededResponse = '''
{
  "message": "OK",
  "payload": {
    "channels": {
      "my_channel": {
        "occupancy": 3,
        "uuids": [
          "0a9e2e6a-1a36-4299-aa18-4d349e0019e5",
          "24a51c02-f0bd-4f6a-b2cb-42dcf6ac6138"
        ]
      },
      "test": {
        "occupancy": 4,
        "uuids": [
          "93ce8247-223e-410d-a612-8e21c7ecb54a",
          "7e4c3056-1ea8-437e-bf68-253926a99309",
          "32f3fafb-3406-4ed0-aed5-1cdf138d9706"
        ]
      }
    },
    "total_channels": 2,
    "total_occupancy": 7
  },
  "service": "Presence",
  "status": 200
}
''';

const _hereNowWithOutNextOffsetLastPage = '''
{
    "message": "OK",
    "payload": {
        "channels": {
            "my_channel": {
                "occupancy": 3,
                "uuids": [
                    "0a9e2e6a-1a36-4299-aa18-4d349e0019e5",
                    "24a51c02-f0bd-4f6a-b2cb-42dcf6ac6138"
                ]
            },
            "test": {
                "occupancy": 4,
                "uuids": [
                    "93ce8247-223e-410d-a612-8e21c7ecb54a",
                    "7e4c3056-1ea8-437e-bf68-253926a99309",
                    "32f3fafb-3406-4ed0-aed5-1cdf138d9706"
                ]
            }
        },
        "total_channels": 2,
        "total_occupancy": 7
    },
    "service": "Presence",
    "status": 200
}
''';

const _hereNowWithOffsetRequired = '''
{
    "message": "OK",
    "payload": {
        "channels": {
            "my_channel": {
                "occupancy": 3,
                "uuids": [
                    "0a9e2e6a-1a36-4299-aa18-4d349e0019e5",
                    "24a51c02-f0bd-4f6a-b2cb-42dcf6ac6138"
                ]
            },
            "test": {
                "occupancy": 4,
                "uuids": [
                    "93ce8247-223e-410d-a612-8e21c7ecb54a",
                    "7e4c3056-1ea8-437e-bf68-253926a99309"
                ]
            }
        },
        "total_channels": 2,
        "total_occupancy": 7
    },
    "service": "Presence",
    "status": 200
}
''';

const _hereNowWithOffsetRequiredUnevenCount = '''
{
    "message": "OK",
    "payload": {
        "channels": {
            "my_channel": {
                "occupancy": 3,
                "uuids": [
                    "0a9e2e6a-1a36-4299-aa18-4d349e0019e5",
                    "24a51c02-f0bd-4f6a-b2cb-42dcf6ac6138"
                ]
            },
            "test": {
                "occupancy": 4,
                "uuids": [
                    "93ce8247-223e-410d-a612-8e21c7ecb54a",
                    "7e4c3056-1ea8-437e-bf68-253926a99309"
                ]
            }
        },
        "total_channels": 2,
        "total_occupancy": 7
    },
    "service": "Presence",
    "status": 200
}
''';

const _hereNowSingleChannelResponse4Occupancies = '''
{
    "message": "OK",
    "occupancy": 4,
    "service": "Presence",
    "status": 200,
    "uuids": [
        "93ce8247-223e-410d-a612-8e21c7ecb54a",
        "7e4c3056-1ea8-437e-bf68-253926a99309",
        "32f3fafb-3406-4ed0-aed5-1cdf138d9706",
        "5125atqy-3406-4ed0-aed5-1cdf138d9706"
    ]
}
''';

const _hereNowSingleChannelResponse4OccupanciesLimit2 = '''
{
    "message": "OK",
    "occupancy": 4,
    "service": "Presence",
    "status": 200,
    "uuids": [
        "93ce8247-223e-410d-a612-8e21c7ecb54a",
        "7e4c3056-1ea8-437e-bf68-253926a99309"
    ]
}
''';

const _hereNowSingleChannelResponse4OccupanciesLimit2Offset1 = '''
{
    "message": "OK",
    "occupancy": 4,
    "service": "Presence",
    "status": 200,
    "uuids": [
        "7e4c3056-1ea8-437e-bf68-253926a99309",
        "32f3fafb-3406-4ed0-aed5-1cdf138d9706"
    ]
}
''';

const _hereNowSingleChannelsResponseMatchesLimit = '''
{
    "message": "OK",
    "occupancy": 2,
    "service": "Presence",
    "status": 200,
    "uuids": [
        "7e4c3056-1ea8-437e-bf68-253926a99309",
        "32f3fafb-3406-4ed0-aed5-1cdf138d9706"
    ]
}
''';
