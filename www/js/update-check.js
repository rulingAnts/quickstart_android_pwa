// Periodically check for new versions via Service Worker updates
(function(){
  if (!('serviceWorker' in navigator)) return;

  function ensureBanner(){
    let el = document.getElementById('update-banner');
    if (el) return el;
    el = document.createElement('div');
    el.id = 'update-banner';
    el.style.cssText = 'position:fixed;left:16px;right:16px;bottom:16px;z-index:9999;background:#323232;color:#fff;padding:12px 16px;border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,.3);display:flex;align-items:center;justify-content:space-between;gap:12px;';
    const msg = document.createElement('div');
    msg.textContent = 'A new version is available.';
    const btnRow = document.createElement('div');
    btnRow.style.display = 'flex';
    btnRow.style.gap = '8px';
    const later = document.createElement('button');
    later.textContent = 'Later';
    later.style.cssText = 'background:transparent;border:1px solid #888;color:#fff;padding:6px 10px;border-radius:6px;cursor:pointer;';
    const reload = document.createElement('button');
    reload.textContent = 'Reload';
    reload.style.cssText = 'background:#4caf50;border:0;color:#fff;padding:6px 12px;border-radius:6px;cursor:pointer;';
    later.addEventListener('click', ()=>{ el.style.display='none'; });
    reload.addEventListener('click', ()=>{ try{ window.location.reload(); }catch(e){} });
    btnRow.appendChild(later); btnRow.appendChild(reload);
    el.appendChild(msg); el.appendChild(btnRow);
    document.body.appendChild(el);
    return el;
  }

  function showBanner(){
    try { ensureBanner().style.display = 'flex'; Log && Log.i && Log.i('Update banner shown'); } catch(e){}
  }

  (async function run(){
    try {
      const reg = await navigator.serviceWorker.ready;
      // Check immediately on ready
      try { await reg.update(); Log && Log.d && Log.d('SW update check complete'); } catch(e) { Log && Log.w && Log.w('SW update check failed', e); }

      // Listen for updatefound
      reg.addEventListener('updatefound', function(){
        const nw = reg.installing;
        if (!nw) return;
        nw.addEventListener('statechange', function(){
          if (nw.state === 'installed' && navigator.serviceWorker.controller) {
            // New content installed; show notice
            showBanner();
            // Try to activate immediately if SW chooses not to skipWaiting
            try { reg.waiting && reg.waiting.postMessage({ type:'SKIP_WAITING' }); } catch(e){}
          }
        });
      });

      // Also react when controller changes (new SW took control); optional auto reload
      navigator.serviceWorker.addEventListener('controllerchange', function(){
        // If page stays open long, suggest reload once activated
        showBanner();
      });

      // Periodic checks (every 30 minutes)
      setInterval(async ()=>{
        try { await reg.update(); Log && Log.d && Log.d('Periodic SW update check complete'); } catch(e) { Log && Log.w && Log.w('Periodic update check failed', e); }
      }, 30 * 60 * 1000);
    } catch (e) {
      // No SW ready; ignore
      Log && Log.w && Log.w('Service worker not ready for update checks', e);
    }
  })();
})();
