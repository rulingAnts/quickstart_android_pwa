// Tiny logger with level control via localStorage('logLevel') or URL (?log=debug)
(function(){
  const levels = { debug: 0, info: 1, warn: 2, error: 3, silent: 4 };
  function getParam(name){
    const m = new URLSearchParams(window.location.search).get(name);
    return m && m.toLowerCase();
  }
  const urlLevel = getParam('log');
  const storedLevel = (localStorage.getItem('logLevel')||'').toLowerCase();
  let level = levels[(urlLevel||storedLevel||'info')] ?? levels.info;

  function ts(){
    try { return new Date().toISOString(); } catch { return '' }
  }
  function out(threshold, method, args){
    if (level <= threshold && console && typeof console[method] === 'function') {
      console[method](`[${ts()}] [${method.toUpperCase()}]`, ...args);
    }
  }
  window.Log = {
    setLevel(l){ level = levels[l] ?? level; localStorage.setItem('logLevel', l); },
    d(){ out(levels.debug, 'debug', arguments); },
    i(){ out(levels.info, 'info', arguments); },
    w(){ out(levels.warn, 'warn', arguments); },
    e(){ out(levels.error, 'error', arguments); }
  };
})();
