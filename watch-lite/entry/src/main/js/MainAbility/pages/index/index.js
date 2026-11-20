import storage from '@system.storage';
import { P2pClient, Message, Builder } from '../../common/wearengine';
import { PEER_PKG_NAME, PEER_FINGERPRINT, STORAGE_KEY } from '../../common/constants';
import { emptyTable, parsePayload, applyPayload, formatCountdown } from '../../common/times';

export default {
  data: {
    mosque: 'Open Awqat on phone',
    nextName: '—',
    nextClock: '--:--',
    countdown: '--:--:--',
    status: 'Waiting for phone',
    rows: [
      { name: 'Fajr', clock: '--:--', hi: 'idle' },
      { name: 'Dhuhr', clock: '--:--', hi: 'idle' },
      { name: 'Asr', clock: '--:--', hi: 'idle' },
      { name: 'Maghrib', clock: '--:--', hi: 'idle' },
      { name: 'Isha', clock: '--:--', hi: 'idle' }
    ],
    payload: null,
    timerId: -1,
    p2p: null
  },
  onInit() {
    var blank = emptyTable();
    this.mosque = blank.mosque;
    this.nextName = blank.nextName;
    this.nextClock = blank.nextClock;
    this.countdown = blank.countdown;
    this.status = blank.status;
    this.rows = blank.rows;
    this.loadCache();
    this.startP2p();
  },
  onShow() {
    this.tick();
    this.timerId = setInterval(this.tick, 1000);
    this.askPhone();
  },
  onHide() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  },
  onDestroy() {
    if (this.p2p) {
      this.p2p.unregisterReceiver({
        onSuccess: function () {},
        onFailure: function () {}
      });
    }
  },
  loadCache() {
    var page = this;
    storage.get({
      key: STORAGE_KEY,
      success: function (data) {
        var payload = parsePayload(data);
        if (payload) {
          applyPayload(page, payload);
        }
      },
      fail: function () {}
    });
  },
  saveCache(text) {
    storage.set({
      key: STORAGE_KEY,
      value: text,
      success: function () {},
      fail: function () {}
    });
  },
  startP2p() {
    var page = this;
    var client = new P2pClient();
    client.setPeerPkgName(PEER_PKG_NAME);
    client.setPeerFingerPrint(PEER_FINGERPRINT);
    client.registerReceiver({
      onSuccess: function () {
        page.status = 'Phone link ready';
      },
      onFailure: function () {
        page.status = 'Phone link failed';
      },
      onReceiveMessage: function (data) {
        page.onPhoneMessage(data);
      }
    });
    this.p2p = client;
  },
  onPhoneMessage(data) {
    var text = '';
    if (!data) {
      return;
    }
    if (data.isFileType) {
      return;
    }
    if (typeof data === 'string') {
      text = data;
    } else if (data.message) {
      text = '' + data.message;
    } else {
      text = '' + data;
    }
    var payload = parsePayload(text);
    if (!payload) {
      this.status = 'Bad phone payload';
      return;
    }
    applyPayload(this, payload);
    this.saveCache(text);
  },
  askPhone() {
    if (!this.p2p) {
      return;
    }
    var builder = new Builder();
    builder.setDescription('{"t":"hello"}');
    var message = new Message();
    message.builder = builder;
    this.p2p.send(message, {
      onSuccess: function () {},
      onFailure: function () {},
      onSendResult: function () {}
    });
  },
  tick() {
    if (this.payload) {
      this.countdown = formatCountdown(new Date(), this.payload);
      applyPayload(this, this.payload);
    }
  }
};
