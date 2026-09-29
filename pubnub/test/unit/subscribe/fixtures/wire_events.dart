part of '../subscription_events_test.dart';

const _presenceJoin = r'''
{"a":"3","f":514,"p":{"t":"17905741224037960","r":41},"k":"demo","c":"ch-pnpres",
 "u":{"pn_action":"join","pn_channel":"ch","pn_ispresence":1,"pn_occupancy":1,"pn_precise_timestamp":1790574122401,"pn_timestamp":1790574122,"pn_uuid":"listener"},
 "d":{"action":"join","uuid":"listener","timestamp":1790574122,"precise_timestamp":1790574122401,"occupancy":1},
 "b":"ch-pnpres"}
''';

const _presenceStateChange = r'''
{"a":"3","f":514,"p":{"t":"17905741733755692","r":41},"k":"demo","c":"ch-pnpres",
 "u":{"pn_action":"state-change","pn_channel":"ch","pn_ispresence":1,"pn_occupancy":2,"pn_precise_timestamp":1790574173373,"pn_state_mood":"ok","pn_timestamp":1790574173,"pn_uuid":"probe-user-11266"},
 "d":{"action":"state-change","uuid":"probe-user-11266","timestamp":1790574173,"precise_timestamp":1790574173373,"data":{"mood":"ok"},"occupancy":2},
 "b":"ch-pnpres"}
''';

const _presenceInterval = r'''
{"a":"3","f":514,"p":{"t":"17905741800000000","r":41},"k":"demo","c":"ch-pnpres",
 "u":{"pn_action":"interval","pn_channel":"ch","pn_ispresence":1,"pn_occupancy":3},
 "d":{"action":"interval","timestamp":1790574180,"occupancy":3,"join":["u1","u2"],"leave":["u3"],"timeout":["u4"]},
 "b":"ch-pnpres"}
''';

const _message = r'''
{"a":"3","f":514,"i":"probe-user-32499","p":{"t":"17905741246383965","r":31},"k":"demo","c":"ch",
 "u":{"m":1},"d":{"text":"hello"},"cmt":"chat-msg","b":"ch"}
''';

const _signal = r'''
{"a":"3","f":514,"e":1,"i":"probe-user-32499","p":{"t":"17905741247663673","r":31},"k":"demo","c":"ch",
 "d":"typing","cmt":"typing-sig","b":"ch"}
''';

const _messageActionAdded = r'''
{"a":"3","f":514,"e":3,"i":"probe-user-32499","p":{"t":"17905741248364496","r":31},"k":"demo","c":"ch",
 "d":{"data":{"actionTimetoken":"17905741248321456","messageTimetoken":"17905741246383965","type":"reaction","value":"smile"},"event":"added","source":"actions","version":"1.0"},
 "b":"ch"}
''';

const _messageActionRemoved = r'''
{"a":"3","f":514,"e":3,"i":"probe-user-11266","p":{"t":"17905741695733002","r":31},"k":"demo","c":"ch",
 "d":{"data":{"actionTimetoken":"17905741684723396","messageTimetoken":"17905741684004892","type":"reaction","value":"x"},"event":"removed","source":"actions","version":"1.0"},
 "b":"ch"}
''';

const _file = r'''
{"a":"3","f":514,"e":4,"i":"probe-user-32499","p":{"t":"17905741250258938","r":31},"k":"demo","c":"ch",
 "d":{"message":{"note":"pic"},"file":{"id":"abc-123","name":"cat.png"}},"cmt":"file-msg","b":"ch"}
''';

const _objectsChannelSet = r'''
{"a":"3","f":514,"e":2,"p":{"t":"17905741254705001","r":21},"k":"demo","c":"ch",
 "d":{"source":"objects","version":"2.0","event":"set","type":"channel","data":{"custom":{"k":"v"},"description":"d","eTag":"9fa5cdad728e8e80118ac14e357bdd48","id":"ch","name":"Probe Chan","updated":"2026-09-28T05:42:05.461456Z"}},
 "b":"ch"}
''';

const _objectsChannelDelete = r'''
{"a":"3","f":514,"e":2,"p":{"t":"17905741706853308","r":21},"k":"demo","c":"ch",
 "d":{"source":"objects","version":"2.0","event":"delete","type":"channel","data":{"id":"ch"}},
 "b":"ch"}
''';

const _objectsUuidSet = r'''
{"a":"3","f":514,"e":2,"p":{"t":"17905741260702617","r":21},"k":"demo","c":"ch",
 "d":{"source":"objects","version":"2.0","event":"set","type":"uuid","data":{"custom":{"a":1},"eTag":"ab9e625153f1bacc28508d28b6a22089","id":"ch","name":"Probe User","updated":"2026-09-28T05:42:06.052512Z"}},
 "b":"ch"}
''';

const _objectsUuidDelete = r'''
{"a":"3","f":514,"e":2,"p":{"t":"17905741730019892","r":21},"k":"demo","c":"ch",
 "d":{"source":"objects","version":"2.0","event":"delete","type":"uuid","data":{"id":"ch"}},
 "b":"ch"}
''';

const _objectsMembershipSet = r'''
{"a":"3","f":514,"e":2,"p":{"t":"17905741266592242","r":21},"k":"demo","c":"ch",
 "d":{"source":"objects","version":"2.0","event":"set","type":"membership","data":{"channel":{"id":"ch"},"custom":{"role":"admin"},"eTag":"Acr+lIO/3JX93wE","updated":"2026-09-28T05:42:06.651180671Z","uuid":{"id":"probe-user-32499"}}},
 "b":"ch"}
''';

const _objectsMembershipDelete = r'''
{"a":"3","f":514,"e":2,"p":{"t":"17905741718217479","r":21},"k":"demo","c":"ch",
 "d":{"source":"objects","version":"2.0","event":"delete","type":"membership","data":{"channel":{"id":"ch"},"uuid":{"id":"probe-user-11266"}}},
 "b":"ch"}
''';

const _dataSyncEntityCreate = r'''
{"a":"4","f":0,"e":5,"p":{"t":"17905749563923636","r":21},"k":"demo","c":"ch",
 "d":{"version":"1.0","metadata":{"event":"create","source":"data-sync","type":"entity","className":"JSCustomer","classLevel":"SubKey","classVersion":1},
      "data":{"id":"dartcustomer.40601","updatedAt":"2026-09-28T05:55:55.583771Z","createdAt":"2026-09-28T05:55:55.583771Z","eTag":"3w5e111z2x3lk","expiresAt":"2027-09-29T00:00:00Z","payload":{"city":"Pune","email":"a@b.test","lastName":"B","firstName":"A","customerId":"dartcustomer.40601","creditScore":700}}},
 "b":"ch"}
''';

const _dataSyncEntityUpdate = r'''
{"a":"4","f":0,"e":5,"p":{"t":"17905749583741605","r":21},"k":"demo","c":"ch",
 "d":{"version":"1.0","metadata":{"event":"update","source":"data-sync","type":"entity","className":"JSCustomer","classLevel":"SubKey","classVersion":1},
      "data":{"id":"dartcustomer.40601","updatedAt":"2026-09-28T05:55:57.821736Z","createdAt":"2026-09-28T05:55:55.583771Z","eTag":"3w5e111z2x54m","expiresAt":"2027-09-29T00:00:00Z","payload":{"city":"Pune","email":"a@b.test","lastName":"B","firstName":"A","customerId":"dartcustomer.40601","creditScore":710}}},
 "b":"ch"}
''';

const _dataSyncEntityDelete = r'''
{"a":"4","f":0,"e":5,"p":{"t":"17905749864310939","r":21},"k":"demo","c":"ch",
 "d":{"version":"1.0","metadata":{"event":"delete","source":"data-sync","type":"entity","className":"JSCustomer","classLevel":"SubKey","classVersion":1},
      "data":{"id":"dartcustomer.40601","deletedAt":"2026-09-28T05:56:25.631142Z"}},
 "b":"ch"}
''';

const _dataSyncUserCreate = r'''
{"a":"4","f":0,"e":5,"p":{"t":"17905749634040437","r":21},"k":"demo","c":"ch",
 "d":{"version":"1.0","metadata":{"event":"create","source":"data-sync","type":"user","className":"User","classLevel":"Global","classVersion":1},
      "data":{"id":"dartcap.user40601","updatedAt":"2026-09-28T05:56:02.754424Z","createdAt":"2026-09-28T05:56:02.754424Z","eTag":"3w5e111z2x96j","expiresAt":"2026-10-29T00:00:00Z","payload":{"name":"U"}}},
 "b":"ch"}
''';

const _dataSyncChannelDelete = r'''
{"a":"4","f":0,"e":5,"p":{"t":"17905749819198501","r":22},"k":"demo","c":"ch",
 "d":{"version":"1.0","metadata":{"event":"delete","source":"data-sync","type":"channel","className":"Channel","classLevel":"Global","classVersion":1},
      "data":{"id":"dartcap.chan40601","deletedAt":"2026-09-28T05:56:20.742571Z"}},
 "b":"ch"}
''';

const _dataSyncMembershipUpdate = r'''
{"a":"4","f":0,"e":5,"p":{"t":"17905749729019891","r":21},"k":"demo","c":"ch",
 "d":{"version":"1.0","metadata":{"event":"update","source":"data-sync","type":"membership","className":"Membership","classLevel":"Global","classVersion":1},
      "data":{"id":"dartcap.mem40601","updatedAt":"2026-09-28T05:56:12.076338Z","createdAt":"2026-09-28T05:56:09.777225Z","eTag":"3w5e111z2xg4l","channelId":"dartcap.chan40601","userId":"dartcap.user40601","expiresAt":"2026-10-29T00:00:00Z","payload":{"role":"owner"}}},
 "b":"ch"}
''';

// Not captured live: an event type the SDK does not know about.
const _unknownType = r'''
{"a":"3","f":514,"e":99,"i":"someone","p":{"t":"17905741900000000","r":31},"k":"demo","c":"ch",
 "d":{"anything":"goes"},"b":"ch"}
''';
