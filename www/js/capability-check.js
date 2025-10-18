// Stricter capability check with caching
(function(){
  const CACHE_KEY = 'capabilityCheck.v1';
  const CACHE_TTL_MS = 1000 * 60 * 60 * 24 * 7; // 7 days

  async function basicSupport(){
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return { ok:false, reason:'No AudioContext' };
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) return { ok:false, reason:'No getUserMedia' };
    if (!("MediaRecorder" in window)) return { ok:false, reason:'No MediaRecorder' };
    const a = document.createElement('audio');
    const wav = typeof a.canPlayType === 'function' && (a.canPlayType('audio/wav; codecs="1"') || a.canPlayType('audio/wav'));
    if (!wav) return { ok:false, reason:'No WAV playback hint' };
    return { ok:true };
  }

  async function strictProbe(){
    // Create a 1kHz tone for ~50ms in-memory, then encode to 16-bit WAV and validate header
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    const ctx = new AudioCtx({ sampleRate: 44100 });
    const sr = ctx.sampleRate;
    const duration = 0.05; // 50ms
    const frames = Math.floor(sr * duration);
    const buf = ctx.createBuffer(1, frames, sr);
    const data = buf.getChannelData(0);
    for (let i=0;i<frames;i++){ data[i] = Math.sin(2*Math.PI*1000*(i/sr)); }

    // Minimal 16-bit PCM WAV writer
    function writeStr(view, off, str){ for (let i=0;i<str.length;i++) view.setUint8(off+i, str.charCodeAt(i)); }
    function f32toI16PCM(view, off, input){
      for (let i=0;i<input.length;i++, off+=2){
        const s = Math.max(-1, Math.min(1, input[i]));
        view.setInt16(off, s<0 ? s*0x8000 : s*0x7FFF, true);
      }
    }
    const bitDepth = 16, numCh = 1, bytesPerSample = bitDepth/8, blockAlign = numCh*bytesPerSample;
    const dataLen = data.length * bytesPerSample;
    const totalLen = 44 + dataLen;
    const ab = new ArrayBuffer(totalLen);
    const view = new DataView(ab);
    writeStr(view,0,'RIFF');
    view.setUint32(4, 36+dataLen, true);
    writeStr(view,8,'WAVE');
    writeStr(view,12,'fmt ');
    view.setUint32(16,16,true);
    view.setUint16(20,1,true);
    view.setUint16(22,numCh,true);
    view.setUint32(24,sr,true);
    view.setUint32(28,sr*blockAlign,true);
    view.setUint16(32,blockAlign,true);
    view.setUint16(34,bitDepth,true);
    writeStr(view,36,'data');
    view.setUint32(40,dataLen,true);
    f32toI16PCM(view,44,data);

    // Validate header markers and bit depth
    const riff = String.fromCharCode(view.getUint8(0),view.getUint8(1),view.getUint8(2),view.getUint8(3));
    const wave = String.fromCharCode(view.getUint8(8),view.getUint8(9),view.getUint8(10),view.getUint8(11));
    const fmt  = String.fromCharCode(view.getUint8(12),view.getUint8(13),view.getUint8(14),view.getUint8(15));
    const bps  = view.getUint16(34,true);
    if (riff!=='RIFF' || wave!=='WAVE' || fmt!=='fmt ' || bps!==16){
      return { ok:false, reason:'Invalid WAV header/bit depth' };
    }

    // Try creating a Blob and object URL (browser may throw if unsupported)
    try {
      const blob = new Blob([ab], { type:'audio/wav' });
      const url = URL.createObjectURL(blob);
      URL.revokeObjectURL(url);
    } catch (e){
      return { ok:false, reason:'Blob/URL unsupported for WAV' };
    }

    return { ok:true };
  }

  async function compute(){
    const basic = await basicSupport();
    if (!basic.ok) return { ok:false, reason:basic.reason };
    try {
      const strict = await strictProbe();
      if (!strict.ok) return { ok:false, reason:strict.reason };
      return { ok:true };
    } catch (e){
      return { ok:false, reason: e && e.message || 'Strict probe failed' };
    }
  }

  async function checkWithCache(){
    try {
      const raw = localStorage.getItem(CACHE_KEY);
      if (raw){
        const parsed = JSON.parse(raw);
        if (Date.now() - (parsed.ts||0) < CACHE_TTL_MS){
          return parsed.result;
        }
      }
    } catch (e){ /* ignore cache parse errors */ }
    const result = await compute();
    try { localStorage.setItem(CACHE_KEY, JSON.stringify({ ts:Date.now(), result })); } catch (e){}
    return result;
  }

  function clearCache(){
    try { localStorage.removeItem(CACHE_KEY); } catch (e){}
  }

  window.CapabilityCheck = { checkWithCache, clearCache };
})();
