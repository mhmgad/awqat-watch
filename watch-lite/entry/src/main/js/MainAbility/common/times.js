function emptyRows() {
  return [
    { name: 'Fajr', clock: '--:--', hi: 'idle' },
    { name: 'Dhuhr', clock: '--:--', hi: 'idle' },
    { name: 'Asr', clock: '--:--', hi: 'idle' },
    { name: 'Maghrib', clock: '--:--', hi: 'idle' },
    { name: 'Isha', clock: '--:--', hi: 'idle' }
  ];
}

export function emptyTable() {
  return {
    mosque: 'Open Awqat on phone',
    nextName: '—',
    nextClock: '--:--',
    countdown: '--:--:--',
    status: 'Waiting for phone',
    rows: emptyRows(),
    payload: null
  };
}

export function parsePayload(text) {
  if (!text) {
    return null;
  }
  try {
    var data = JSON.parse(text);
    if (!data || data.v !== 1) {
      return null;
    }
    return data;
  } catch (err) {
    return null;
  }
}

function pad(value) {
  return value < 10 ? '0' + value : '' + value;
}

function todayKey(now) {
  return now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate());
}

function minutesOf(clock) {
  if (!clock || clock.indexOf(':') < 0) {
    return -1;
  }
  var parts = clock.split(':');
  var hours = parseInt(parts[0], 10);
  var mins = parseInt(parts[1], 10);
  if (isNaN(hours) || isNaN(mins)) {
    return -1;
  }
  return hours * 60 + mins;
}

function namesFor(now, payload) {
  if (now.getDay() === 5 && payload.j) {
    return [
      { key: 'f', name: 'Fajr' },
      { key: 'j', name: 'Jumua' },
      { key: 'a', name: 'Asr' },
      { key: 'm', name: 'Maghrib' },
      { key: 'i', name: 'Isha' }
    ];
  }
  return [
    { key: 'f', name: 'Fajr' },
    { key: 'h', name: 'Dhuhr' },
    { key: 'a', name: 'Asr' },
    { key: 'm', name: 'Maghrib' },
    { key: 'i', name: 'Isha' }
  ];
}

function nextPrayer(now, payload) {
  var list = namesFor(now, payload);
  var nowMin = now.getHours() * 60 + now.getMinutes();
  var i;
  for (i = 0; i < list.length; i++) {
    var clock = payload[list[i].key] || '--:--';
    var at = minutesOf(clock);
    if (at >= 0 && at > nowMin) {
      return {
        index: i,
        name: list[i].name,
        clock: clock,
        minutes: at,
        tomorrow: false
      };
    }
  }
  var fajr = payload.f || '00:00';
  return {
    index: 0,
    name: 'Fajr',
    clock: fajr,
    minutes: minutesOf(fajr),
    tomorrow: true
  };
}

export function formatCountdown(now, payload) {
  var next = nextPrayer(now, payload);
  if (next.minutes < 0) {
    return '--:--:--';
  }
  var target = new Date(now.getTime());
  var hours = Math.floor(next.minutes / 60);
  var mins = next.minutes % 60;
  target.setHours(hours, mins, 0, 0);
  if (next.tomorrow || target.getTime() <= now.getTime()) {
    target.setDate(target.getDate() + 1);
  }
  var diff = Math.floor((target.getTime() - now.getTime()) / 1000);
  if (diff < 0) {
    diff = 0;
  }
  var h = Math.floor(diff / 3600);
  var m = Math.floor((diff % 3600) / 60);
  var s = diff % 60;
  return pad(h) + ':' + pad(m) + ':' + pad(s);
}

export function applyPayload(page, payload) {
  if (!payload) {
    return;
  }
  var now = new Date();
  var list = namesFor(now, payload);
  var next = nextPrayer(now, payload);
  var rows = [];
  var i;
  for (i = 0; i < list.length; i++) {
    rows.push({
      name: list[i].name,
      clock: payload[list[i].key] || '--:--',
      hi: i === next.index && !next.tomorrow ? 'next' : 'idle'
    });
  }
  page.payload = payload;
  page.mosque = payload.n || payload.s || 'MAWAQIT';
  page.nextName = next.name;
  page.nextClock = next.clock;
  page.countdown = formatCountdown(now, payload);
  page.rows = rows;
  if (payload.d && payload.d !== todayKey(now)) {
    page.status = 'Phone times for ' + payload.d;
  } else {
    page.status = 'MAWAQIT';
  }
}
