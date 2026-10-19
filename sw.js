/* عامل الخدمة: يخلّي الصفحة تفتح من غير نت بعد أول مرة.
   لو عدّلت index.html ارفع رقم VERSION عشان الموبايلات تاخد النسخة الجديدة. */
var VERSION = "expo-v2.0.0";
var SHELL = [
  "./", "./index.html", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.2/dist/umd/supabase.js"
];

self.addEventListener("install", function (e) {
  e.waitUntil(caches.open(VERSION).then(function (c) {
    return Promise.all(SHELL.map(function (u) { return c.add(u).catch(function () {}); }));
  }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener("activate", function (e) {
  e.waitUntil(caches.keys().then(function (keys) {
    return Promise.all(keys.filter(function (k) { return k !== VERSION; }).map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});

self.addEventListener("fetch", function (e) {
  var req = e.request;
  if (req.method !== "GET") return;
  var url = new URL(req.url);
  if (/supabase\.(co|in)$/.test(url.hostname)) return;          // البيانات دايمًا من السيرفر مباشرة

  // صفحات الموقع نفسه: من النت الأول (عشان التحديثات)، ولو مفيش نت من الكاش
  if (url.origin === self.location.origin) {
    e.respondWith(fetch(req).then(function (res) {
      if (res.ok) { var copy = res.clone(); caches.open(VERSION).then(function (c) { c.put(req, copy); }); }
      return res;
    }).catch(function () {
      return caches.match(req, { ignoreSearch: true }).then(function (r) {
        return r || (req.mode === "navigate" ? caches.match("./index.html") : Response.error());
      });
    }));
    return;
  }

  // المكتبة والخطوط: من الكاش لو موجودة، وتتحدث في الخلفية
  if (/(cdn\.jsdelivr\.net|fonts\.googleapis\.com|fonts\.gstatic\.com)$/.test(url.hostname)) {
    e.respondWith(caches.open(VERSION).then(function (c) {
      return c.match(req).then(function (hit) {
        var net = fetch(req).then(function (res) { if (res.ok || res.type === "opaque") c.put(req, res.clone()); return res; })
          .catch(function () { return hit || Response.error(); });
        return hit || net;
      });
    }));
  }
});
