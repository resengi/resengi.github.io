(function () {
  var wrapper = document.getElementById('charts-frame-wrapper');
  if (!wrapper) return;

  var booted = false;
  var revealed = false;
  var failureTimer = null;
  var iframe = null;

  function showLoadFailure() {
    if (failureTimer) { clearTimeout(failureTimer); failureTimer = null; }
    wrapper.innerHTML =
      '<div class="charts-load-failed">' +
        '<p>Charts couldn&rsquo;t load right now. ' +
        'The raw data is still available in the table above and via the CSV link.</p>' +
      '</div>';
  }

  function revealIframe(heightPx) {
    if (revealed) return;
    revealed = true;
    if (failureTimer) { clearTimeout(failureTimer); failureTimer = null; }
    iframe.style.height = heightPx + 'px';
    iframe.classList.remove('charts-frame-hidden');
    var spinner = wrapper.querySelector('.iframe-spinner');
    if (spinner) spinner.remove();
  }

  // Listen for messages from the Flutter iframe. The iframe posts
  // `{type: 'resengi-charts-ready', height: N}` once its grid has
  // laid out, or `{type: 'resengi-charts-error'}` if data loading
  // failed. We validate the source iframe, the origin, and the
  // message shape before acting on anything.
  function handleMessage(event) {
    if (!iframe || event.source !== iframe.contentWindow) return;
    if (event.origin !== window.location.origin) return;
    var data = event.data;
    if (!data || typeof data !== 'object') return;

    if (data.type === 'resengi-charts-error') {
      showLoadFailure();
      return;
    }
    if (data.type === 'resengi-charts-ready'
        && typeof data.height === 'number'
        && isFinite(data.height)
        && data.height > 0) {
      if (!revealed) {
        revealIframe(data.height);
      } else {
        // Subsequent messages (e.g. from a window resize inside
        // the iframe) just update the height.
        iframe.style.height = data.height + 'px';
      }
    }
  }

  function bootCharts() {
    if (booted) return;
    booted = true;

    window.addEventListener('message', handleMessage);

    iframe = document.createElement('iframe');
    iframe.src = '/flutter-charts/';
    iframe.className = 'charts-frame charts-frame-hidden';
    iframe.title = 'Resengi financial charts';
    iframe.loading = 'lazy';
    // Iframes commonly fire `load` with an error document rather
    // than firing `error` on URL failures, so the 8s timer below
    // is the authoritative failure detector. We don't clear that
    // timer on `load`. Clear it on the `ready` postMessage,
    // which means the iframe actually rendered charts.
    iframe.addEventListener('error', showLoadFailure);

    // Append alongside the spinner. The hidden class absolutely-
    // positions the iframe over the wrapper while it loads, so it
    // doesn't push layout around and the spinner remains visible.
    wrapper.appendChild(iframe);

    // If we don't hear from the iframe within 8s, show fallback.
    failureTimer = setTimeout(function () {
      showLoadFailure();
    }, 8000);
  }

  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          bootCharts();
          observer.disconnect();
        }
      });
    }, { rootMargin: '200px' });
    observer.observe(wrapper);
  } else {
    bootCharts();
  }
})();