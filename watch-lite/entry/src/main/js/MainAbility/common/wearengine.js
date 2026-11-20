// Development stub with the Wear Engine JS surface.
// For a real FIT 3 install, replace this file with Huawei's
// WearEngine-LiteWearable SDK (wearengine.js) from:
// https://developer.huawei.com/consumer/en/doc/connectivity-Library/litewearable-sdk-cn-0000001705004353

function P2pClient() {
  this.pkg = '';
  this.finger = '';
}

P2pClient.prototype.setPeerPkgName = function (name) {
  this.pkg = name;
};

P2pClient.prototype.setPeerFingerPrint = function (finger) {
  this.finger = finger;
};

P2pClient.prototype.registerReceiver = function (receiver) {
  if (receiver && receiver.onSuccess) {
    receiver.onSuccess();
  }
};

P2pClient.prototype.unregisterReceiver = function (callback) {
  if (callback && callback.onSuccess) {
    callback.onSuccess();
  }
};

P2pClient.prototype.send = function (message, sendCallback) {
  if (sendCallback && sendCallback.onFailure) {
    sendCallback.onFailure();
  }
};

P2pClient.prototype.ping = function (callback) {
  if (callback && callback.onFailure) {
    callback.onFailure();
  }
};

function Builder() {
  this.text = '';
}

Builder.prototype.setDescription = function (text) {
  this.text = text;
};

function Message() {
  this.builder = null;
}

export { P2pClient, Message, Builder };
