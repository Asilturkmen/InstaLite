// Akıştaki Reels gönderilerini veri düzeyinde çıkarır. Instagram akışı, ekrana yakın birkaç gönderiyi
// tutan ölçüye dayalı bir listeyle çizer; gönderiyi CSS ile gizlemek bu hesabı bozar (liste sürekli
// büyür, sonunda başa sıçrar). Bu yüzden Reels, liste onları hiç görmeden veriden atılır.
//
// İlk sayfa HTML'e gömülü JSON'dan, sonrakiler XHR ile gelir; ikisi de JSON.parse'tan geçer.
// Bu betik sayfa betiklerinden önce çalışmalı.
(function () {
  const FEED_KEY = 'xdt_api__v1__feed__timeline__connection';
  const parse = JSON.parse;

  function isReel(node) {
    const media = node && node.media;
    return !!media && media.product_type === 'clips';
  }

  // Çıkarılan Reels sayısı; geliştirme ölçümleri (DebugBridge) bunu raporlar.
  globalThis.__instaLiteRemovedReels = 0;

  function filterConnection(connection) {
    if (!connection || !Array.isArray(connection.edges)) return;
    const before = connection.edges.length;
    connection.edges = connection.edges.filter((edge) => !isReel(edge && edge.node));
    globalThis.__instaLiteRemovedReels += before - connection.edges.length;
  }

  // Akış bağlantısı Relay yüklerinin içinde farklı derinliklerde olabilir.
  function visit(value, depth) {
    if (!value || typeof value !== 'object' || depth > 40) return;
    if (Array.isArray(value)) {
      for (const item of value) visit(item, depth + 1);
      return;
    }
    for (const key of Object.keys(value)) {
      if (key === FEED_KEY) filterConnection(value[key]);
      else visit(value[key], depth + 1);
    }
  }

  JSON.parse = function (text, reviver) {
    const value = parse.apply(this, arguments);
    if (typeof text === 'string' && text.length > 200 && text.includes(FEED_KEY)) {
      try {
        visit(value, 0);
      } catch {}
    }
    return value;
  };
})();
