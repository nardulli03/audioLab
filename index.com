<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>AudioLab – Conversor Analógico → Digital</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap');

  *, *::before, *::after {
    margin: 0; padding: 0; box-sizing: border-box;
  }

  :root {
    --bg:        #0a0d14;
    --surface:   #111827;
    --surface2:  #1a2235;
    --border:    #1f2d40;
    --accent:    #7c3aed;
    --accent2:   #38bdf8;
    --accent-g:  linear-gradient(135deg, #7c3aed, #38bdf8);
    --text:      #e2e8f0;
    --muted:     #64748b;
    --success:   #22c55e;
    --warn:      #f59e0b;
    --danger:    #ef4444;
    --radius:    20px;
    --mono:      'JetBrains Mono', monospace;
  }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: 'Inter', sans-serif;
    min-height: 100vh;
    padding: 28px 32px;
  }

  /* ── HEADER ── */
  .header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 28px;
    flex-wrap: wrap;
    gap: 14px;
  }
  .logo { font-size: 28px; font-weight: 700; background: var(--accent-g); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
  .sub  { color: var(--muted); font-size: 13px; margin-top: 4px; }
  .badge {
    background: var(--surface2);
    border: 1px solid var(--border);
    padding: 10px 16px;
    border-radius: 12px;
    font-size: 13px;
    display: flex; align-items: center; gap: 8px;
  }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--muted); transition: background .3s; }
  .dot.live { background: var(--danger); box-shadow: 0 0 8px var(--danger); animation: pulse 1.2s infinite; }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }

  /* ── LAYOUT ── */
  .grid {
    display: grid;
    grid-template-columns: 1.3fr 0.7fr;
    gap: 22px;
  }
  @media(max-width:900px){ .grid{ grid-template-columns:1fr; } }

  /* ── CARDS ── */
  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 22px;
  }
  .card + .card, .card + .card-sm { margin-top: 20px; }
  .card h2 {
    font-size: 15px; font-weight: 600;
    color: var(--text);
    margin-bottom: 16px;
    display: flex; align-items: center; gap: 8px;
  }
  .card h2 span { font-size: 16px; }

  /* ── WAVEFORM ── */
  #waveCanvas {
    width: 100%; height: 160px;
    border-radius: 14px;
    display: block;
    background: linear-gradient(135deg, #1a0a2e, #0d1f3c);
    cursor: pointer;
  }

  /* ── BUTTONS ── */
  .btns { display: flex; gap: 10px; margin-top: 14px; flex-wrap: wrap; }
  .btn {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 11px 18px; border-radius: 12px; border: none;
    font-size: 13px; font-weight: 600; cursor: pointer;
    transition: transform .15s, opacity .15s, box-shadow .15s;
  }
  .btn:hover:not(:disabled) { transform: translateY(-2px); }
  .btn:active:not(:disabled) { transform: translateY(0); }
  .btn:disabled { opacity: .4; cursor: not-allowed; }
  .btn-primary { background: var(--accent); color: #fff; }
  .btn-primary:hover:not(:disabled) { box-shadow: 0 0 20px rgba(124,58,237,.5); }
  .btn-secondary { background: var(--surface2); color: var(--text); border: 1px solid var(--border); }
  .btn-danger { background: var(--danger); color: #fff; }
  .btn-success { background: var(--success); color: #fff; }
  .btn-cyan { background: #0e7490; color: #fff; }
  .btn-sm { padding: 8px 14px; font-size: 12px; border-radius: 10px; }

  /* ── STATS ── */
  .stats { display: grid; grid-template-columns: repeat(3,1fr); gap: 10px; margin-top: 14px; }
  .stat { background: var(--surface2); padding: 14px; border-radius: 14px; border: 1px solid var(--border); }
  .stat-label { color: var(--muted); font-size: 11px; margin-bottom: 5px; text-transform: uppercase; letter-spacing: .5px; }
  .stat-value { font-family: var(--mono); font-size: 15px; font-weight: 600; color: var(--accent2); }

  /* ── SPECTRUM ── */
  #spectrumCanvas {
    width: 100%; height: 140px;
    border-radius: 14px;
    display: block;
    background: #050810;
  }

  /* ── CONTROLS (right col) ── */
  .field { margin-bottom: 16px; }
  .field label { display: block; color: var(--muted); font-size: 12px; margin-bottom: 7px; text-transform: uppercase; letter-spacing: .5px; }
  select, input[type=range] {
    width: 100%; background: var(--surface2); color: var(--text);
    border: 1px solid var(--border); border-radius: 10px;
    padding: 11px 14px; font-size: 13px; cursor: pointer;
    appearance: none; outline: none;
  }
  select:focus { border-color: var(--accent); }
  input[type=range] { padding: 6px; cursor: pointer; accent-color: var(--accent); }
  .range-row { display: flex; align-items: center; gap: 10px; }
  .range-val { font-family: var(--mono); font-size: 13px; color: var(--accent2); min-width: 40px; }

  /* ── PROGRESS ── */
  .progress-wrap { margin-top: 14px; }
  .progress-label { font-size: 12px; color: var(--muted); margin-bottom: 6px; display:flex; justify-content:space-between; }
  .progress-bar { height: 6px; background: var(--surface2); border-radius: 99px; overflow: hidden; }
  .progress-fill { height: 100%; width: 0%; background: var(--accent-g); border-radius: 99px; transition: width .1s; }

  /* ── RESULT ── */
  .result-info { color: var(--muted); font-size: 13px; line-height: 1.8; margin-bottom: 14px; }
  .result-info strong { color: var(--accent2); font-family: var(--mono); }
  .result-hidden { display: none; }

  /* ── TOAST ── */
  #toast {
    position: fixed; bottom: 28px; right: 28px;
    background: var(--surface); border: 1px solid var(--border);
    border-radius: 14px; padding: 14px 20px;
    font-size: 13px; max-width: 320px;
    box-shadow: 0 8px 32px rgba(0,0,0,.5);
    opacity: 0; transform: translateY(10px);
    transition: opacity .25s, transform .25s;
    pointer-events: none; z-index: 999;
  }
  #toast.show { opacity: 1; transform: translateY(0); pointer-events: auto; }
  #toast.ok   { border-color: var(--success); }
  #toast.err  { border-color: var(--danger); }

  /* ── TIMER ── */
  #recTimer { font-family: var(--mono); color: var(--danger); font-size: 13px; }

  /* ── PLAYBACK ── */
  .playback-row { display:flex; align-items:center; gap:10px; margin-top:12px; }
  #playhead { flex:1; }
  #timeDisplay { font-family:var(--mono); font-size:12px; color:var(--muted); white-space:nowrap; }

  /* ── FILE INPUT ── */
  #fileInput { display:none; }

  /* ── UPLOAD ZONE ── */
  .upload-zone {
    border: 2px dashed var(--border);
    border-radius: 14px; padding: 24px;
    text-align: center; color: var(--muted); font-size: 13px;
    cursor: pointer; transition: border-color .2s;
    margin-top: 12px;
  }
  .upload-zone:hover { border-color: var(--accent); color: var(--accent2); }

</style>
</head>
<body>

<!-- HEADER -->
<div class="header">
  <div>
    <div class="logo">AudioLab</div>
    <div class="sub">Conversor de Audio Analógico → Digital · DSP Studio</div>
  </div>
  <div class="badge">
    <div class="dot" id="liveDot"></div>
    <span id="liveLabel">En espera</span>
    &nbsp;|&nbsp;
    <span id="recTimer">00:00</span>
  </div>
</div>

<!-- GRID -->
<div class="grid">

  <!-- ── COLUMNA IZQUIERDA ── -->
  <div>

    <!-- ENTRADA -->
    <div class="card">
      <h2><span>🎙</span> Entrada de Audio</h2>

      <canvas id="waveCanvas"></canvas>

      <div class="playback-row">
        <input type="range" id="playhead" min="0" max="100" value="0" disabled>
        <span id="timeDisplay">0:00 / 0:00</span>
      </div>

      <div class="btns">
        <button class="btn btn-primary"  id="btnRecord">🔴 Grabar</button>
        <button class="btn btn-secondary" id="btnStop"  disabled>⏹ Detener</button>
        <button class="btn btn-secondary" id="btnPlay"  disabled>▶ Reproducir</button>
        <button class="btn btn-secondary" id="btnUpload">📁 Subir Archivo</button>
        <input type="file" id="fileInput" accept="audio/*">
      </div>

      <div class="stats">
        <div class="stat"><div class="stat-label">Formato</div><div class="stat-value" id="sFmt">—</div></div>
        <div class="stat"><div class="stat-label">Duración</div><div class="stat-value" id="sDur">—</div></div>
        <div class="stat"><div class="stat-label">Tamaño</div><div class="stat-value" id="sSize">—</div></div>
      </div>
    </div>

    <!-- SPECTRUM -->
    <div class="card">
      <h2><span>📊</span> Espectro de Frecuencia en Vivo</h2>
      <canvas id="spectrumCanvas"></canvas>
    </div>

  </div>

  <!-- ── COLUMNA DERECHA ── -->
  <div>

    <!-- CONFIGURACIÓN -->
    <div class="card">
      <h2><span>⚙️</span> Configuración Digital</h2>

      <div class="field">
        <label>Tasa de Muestreo</label>
        <select id="sampleRate">
          <option value="8000">8 kHz — Telefonía</option>
          <option value="16000">16 kHz — Voz HD</option>
          <option value="44100" selected>44.1 kHz — CD</option>
          <option value="48000">48 kHz — Estudio</option>
          <option value="96000">96 kHz — Hi-Res</option>
        </select>
      </div>

      <div class="field">
        <label>Profundidad de Bits</label>
        <select id="bitDepth">
          <option value="8">8 bits</option>
          <option value="16" selected>16 bits</option>
          <option value="24">24 bits</option>
          <option value="32">32 bits (float)</option>
        </select>
      </div>

      <div class="field">
        <label>Canales</label>
        <select id="channels">
          <option value="1">Mono</option>
          <option value="2" selected>Estéreo</option>
        </select>
      </div>

      <div class="field">
        <label>Volumen de Salida — <span id="volVal">100</span>%</label>
        <div class="range-row">
          <input type="range" id="volume" min="0" max="100" value="100">
        </div>
      </div>

      <div class="field">
        <label>Formato de Exportación</label>
        <select id="exportFmt">
          <option value="wav">WAV — Sin pérdida</option>
          <option value="mp3">MP3 — Comprimido</option>
        </select>
      </div>

      <div class="progress-wrap" id="progressWrap" style="display:none">
        <div class="progress-label">
          <span>Procesando…</span><span id="progressPct">0%</span>
        </div>
        <div class="progress-bar"><div class="progress-fill" id="progressFill"></div></div>
      </div>

      <div class="btns" style="margin-top:16px;">
        <button class="btn btn-primary" id="btnConvert" disabled>⚡ Convertir</button>
      </div>
    </div>

    <!-- RESULTADO -->
    <div class="card" id="resultCard">
      <h2><span>✅</span> Resultado</h2>
      <div class="result-info" id="resultInfo">
        Cargá o grabá un audio y presioná <strong>Convertir</strong> para comenzar.
      </div>
      <div class="btns" id="exportBtns" style="display:none">
        <button class="btn btn-success btn-sm" id="btnDlWav">⬇ WAV</button>
        <button class="btn btn-cyan    btn-sm" id="btnDlMp3">⬇ MP3</button>
      </div>
    </div>

  </div>
</div>

<!-- TOAST -->
<div id="toast"></div>

<script>
// ══════════════════════════════════════════════════════
//  STATE
// ══════════════════════════════════════════════════════
const state = {
  mediaRecorder: null,
  recordedChunks: [],
  audioBuffer: null,     // decoded AudioBuffer
  audioBlob: null,       // raw blob
  audioCtx: null,
  analyser: null,
  source: null,
  gainNode: null,
  isRecording: false,
  isPlaying: false,
  playbackNode: null,
  recInterval: null,
  recSeconds: 0,
  animFrame: null,
  convertedWavBlob: null,
};

// ══════════════════════════════════════════════════════
//  DOM REFS
// ══════════════════════════════════════════════════════
const waveCanvas   = document.getElementById('waveCanvas');
const waveCtx      = waveCanvas.getContext('2d');
const specCanvas   = document.getElementById('spectrumCanvas');
const specCtx      = specCanvas.getContext('2d');

const btnRecord    = document.getElementById('btnRecord');
const btnStop      = document.getElementById('btnStop');
const btnPlay      = document.getElementById('btnPlay');
const btnUpload    = document.getElementById('btnUpload');
const fileInput    = document.getElementById('fileInput');
const btnConvert   = document.getElementById('btnConvert');
const btnDlWav     = document.getElementById('btnDlWav');
const btnDlMp3     = document.getElementById('btnDlMp3');

const liveDot      = document.getElementById('liveDot');
const liveLabel    = document.getElementById('liveLabel');
const recTimer     = document.getElementById('recTimer');
const playhead     = document.getElementById('playhead');
const timeDisplay  = document.getElementById('timeDisplay');

const volSlider    = document.getElementById('volume');
const volVal       = document.getElementById('volVal');
const sFmt         = document.getElementById('sFmt');
const sDur         = document.getElementById('sDur');
const sSize        = document.getElementById('sSize');
const progressWrap = document.getElementById('progressWrap');
const progressFill = document.getElementById('progressFill');
const progressPct  = document.getElementById('progressPct');
const resultInfo   = document.getElementById('resultInfo');
const exportBtns   = document.getElementById('exportBtns');
const toast        = document.getElementById('toast');

// ══════════════════════════════════════════════════════
//  CANVAS RESIZE
// ══════════════════════════════════════════════════════
function resizeCanvases() {
  waveCanvas.width  = waveCanvas.offsetWidth  * devicePixelRatio;
  waveCanvas.height = waveCanvas.offsetHeight * devicePixelRatio;
  waveCtx.scale(devicePixelRatio, devicePixelRatio);

  specCanvas.width  = specCanvas.offsetWidth  * devicePixelRatio;
  specCanvas.height = specCanvas.offsetHeight * devicePixelRatio;
  specCtx.scale(devicePixelRatio, devicePixelRatio);
}
window.addEventListener('resize', resizeCanvases);
resizeCanvases();

// ══════════════════════════════════════════════════════
//  IDLE ANIMATION
// ══════════════════════════════════════════════════════
let idleT = 0;
function drawIdle() {
  const W = waveCanvas.offsetWidth, H = waveCanvas.offsetHeight;
  waveCtx.clearRect(0, 0, W, H);
  waveCtx.strokeStyle = 'rgba(124,58,237,0.3)';
  waveCtx.lineWidth = 1.5;
  waveCtx.beginPath();
  for (let x = 0; x <= W; x++) {
    const y = H/2 + Math.sin((x/W)*Math.PI*6 + idleT)*12 + Math.sin((x/W)*Math.PI*3 + idleT*1.3)*5;
    x === 0 ? waveCtx.moveTo(x,y) : waveCtx.lineTo(x,y);
  }
  waveCtx.stroke();
  idleT += 0.02;

  // idle spectrum
  const W2 = specCanvas.offsetWidth, H2 = specCanvas.offsetHeight;
  specCtx.clearRect(0,0,W2,H2);
  const bars = 48;
  const bw = (W2 - bars*2) / bars;
  for (let i=0; i<bars; i++){
    const h = (Math.sin(i*0.4+idleT*1.5)*0.1+0.1) * H2 * 0.3;
    const grad = specCtx.createLinearGradient(0,H2-h,0,H2);
    grad.addColorStop(0,'rgba(56,189,248,0.5)');
    grad.addColorStop(1,'rgba(124,58,237,0.3)');
    specCtx.fillStyle = grad;
    specCtx.fillRect(i*(bw+2)+1, H2-h, bw, h);
  }
}

function startIdleLoop() {
  cancelAnimationFrame(state.animFrame);
  function loop(){ state.animFrame = requestAnimationFrame(loop); drawIdle(); }
  loop();
}
startIdleLoop();

// ══════════════════════════════════════════════════════
//  AUDIO CONTEXT
// ══════════════════════════════════════════════════════
function ensureAudioCtx() {
  if (!state.audioCtx) {
    state.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (state.audioCtx.state === 'suspended') state.audioCtx.resume();
}

// ══════════════════════════════════════════════════════
//  LIVE ANALYSER DRAW
// ══════════════════════════════════════════════════════
function drawLive() {
  const analyser = state.analyser;
  if (!analyser) return;
  const bufLen = analyser.frequencyBinCount;
  const timeDom = new Uint8Array(bufLen);
  const freqDom = new Uint8Array(bufLen);

  function frame() {
    state.animFrame = requestAnimationFrame(frame);
    analyser.getByteTimeDomainData(timeDom);
    analyser.getByteFrequencyData(freqDom);

    // waveform
    const W = waveCanvas.offsetWidth, H = waveCanvas.offsetHeight;
    waveCtx.clearRect(0,0,W,H);
    const grad = waveCtx.createLinearGradient(0,0,W,0);
    grad.addColorStop(0,'#7c3aed'); grad.addColorStop(1,'#38bdf8');
    waveCtx.strokeStyle = grad;
    waveCtx.lineWidth = 2;
    waveCtx.beginPath();
    const sliceW = W / bufLen;
    let x = 0;
    for (let i=0; i<bufLen; i++){
      const v = timeDom[i]/128 - 1;
      const y = H/2 + v*(H/2)*0.85;
      i===0 ? waveCtx.moveTo(x,y) : waveCtx.lineTo(x,y);
      x += sliceW;
    }
    waveCtx.stroke();

    // spectrum
    const W2 = specCanvas.offsetWidth, H2 = specCanvas.offsetHeight;
    specCtx.clearRect(0,0,W2,H2);
    const bars = 64;
    const step = Math.floor(bufLen/bars);
    const bw = (W2 - bars*2)/bars;
    for (let i=0; i<bars; i++){
      const val = freqDom[i*step]/255;
      const h = val * H2 * 0.95;
      const r = Math.round(56 + (124-56)*i/bars);
      const g = Math.round(189 - 130*i/bars);
      const b = Math.round(248 - (248-237)*i/bars);
      const grad2 = specCtx.createLinearGradient(0,H2-h,0,H2);
      grad2.addColorStop(0,`rgb(${r},${g},${b})`);
      grad2.addColorStop(1,`rgba(${r},${g},${b},0.2)`);
      specCtx.fillStyle = grad2;
      specCtx.fillRect(i*(bw+2)+1, H2-h, bw, h);
    }
  }
  cancelAnimationFrame(state.animFrame);
  frame();
}

// ══════════════════════════════════════════════════════
//  STATIC WAVEFORM (from AudioBuffer)
// ══════════════════════════════════════════════════════
function drawStaticWaveform() {
  if (!state.audioBuffer) return;
  const buf = state.audioBuffer;
  const data = buf.getChannelData(0);
  const W = waveCanvas.offsetWidth, H = waveCanvas.offsetHeight;
  const step = Math.ceil(data.length / W);
  waveCtx.clearRect(0,0,W,H);
  const grad = waveCtx.createLinearGradient(0,0,W,0);
  grad.addColorStop(0,'#7c3aed'); grad.addColorStop(1,'#38bdf8');
  waveCtx.fillStyle = grad;
  for (let i=0; i<W; i++){
    let min=1, max=-1;
    for (let j=0;j<step;j++){
      const d = data[i*step+j] || 0;
      if (d < min) min=d;
      if (d > max) max=d;
    }
    const yMin = ((1+min)/2)*H;
    const yMax = ((1+max)/2)*H;
    waveCtx.fillRect(i, yMax, 1, Math.max(1, yMin-yMax));
  }
}

// ══════════════════════════════════════════════════════
//  RECORDING
// ══════════════════════════════════════════════════════
btnRecord.addEventListener('click', async () => {
  try {
    ensureAudioCtx();
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    state.mediaRecorder = new MediaRecorder(stream);
    state.recordedChunks = [];

    // Connect analyser
    const src = state.audioCtx.createMediaStreamSource(stream);
    state.analyser = state.audioCtx.createAnalyser();
    state.analyser.fftSize = 2048;
    src.connect(state.analyser);
    drawLive();

    state.mediaRecorder.ondataavailable = e => { if (e.data.size > 0) state.recordedChunks.push(e.data); };
    state.mediaRecorder.onstop = () => {
      const blob = new Blob(state.recordedChunks, { type: 'audio/webm' });
      loadAudioBlob(blob, 'webm');
      stream.getTracks().forEach(t => t.stop());
    };

    state.mediaRecorder.start(100);
    state.isRecording = true;
    state.recSeconds = 0;
    clearInterval(state.recInterval);
    state.recInterval = setInterval(() => {
      state.recSeconds++;
      const m = String(Math.floor(state.recSeconds/60)).padStart(2,'0');
      const s = String(state.recSeconds%60).padStart(2,'0');
      recTimer.textContent = `${m}:${s}`;
    }, 1000);

    liveDot.classList.add('live');
    liveLabel.textContent = 'Grabando';
    btnRecord.disabled = true;
    btnStop.disabled   = false;
    btnPlay.disabled   = true;
    btnConvert.disabled = true;
    showToast('🔴 Grabación iniciada', 'ok');
  } catch(e) {
    showToast('❌ No se pudo acceder al micrófono: ' + e.message, 'err');
  }
});

btnStop.addEventListener('click', () => {
  if (state.mediaRecorder && state.isRecording) {
    state.mediaRecorder.stop();
    state.isRecording = false;
    clearInterval(state.recInterval);
    liveDot.classList.remove('live');
    liveLabel.textContent = 'En espera';
    btnRecord.disabled = false;
    btnStop.disabled   = true;
    showToast('⏹ Grabación detenida', 'ok');
  }
});

// ══════════════════════════════════════════════════════
//  FILE UPLOAD
// ══════════════════════════════════════════════════════
btnUpload.addEventListener('click', () => fileInput.click());
fileInput.addEventListener('change', e => {
  const file = e.target.files[0];
  if (!file) return;
  const ext = file.name.split('.').pop().toLowerCase();
  loadAudioBlob(file, ext);
  fileInput.value = '';
});

// ══════════════════════════════════════════════════════
//  LOAD BLOB → DECODE
// ══════════════════════════════════════════════════════
async function loadAudioBlob(blob, ext) {
  ensureAudioCtx();
  state.audioBlob = blob;
  sFmt.textContent  = ext.toUpperCase();
  sSize.textContent = formatBytes(blob.size);
  sDur.textContent  = '…';

  try {
    const arrBuf = await blob.arrayBuffer();
    const audioBuf = await state.audioCtx.decodeAudioData(arrBuf);
    state.audioBuffer = audioBuf;
    sDur.textContent = formatDur(audioBuf.duration);
    btnPlay.disabled    = false;
    btnConvert.disabled = false;
    playhead.max = Math.ceil(audioBuf.duration);
    playhead.disabled = false;
    updateResultInfo('ready');
    drawStaticWaveform();
    showToast('✅ Audio cargado — listo para convertir', 'ok');
  } catch(e) {
    showToast('❌ Error al decodificar el audio', 'err');
  }
}

// ══════════════════════════════════════════════════════
//  PLAYBACK
// ══════════════════════════════════════════════════════
let playStartTime = 0, playOffset = 0, playInterval = null;

btnPlay.addEventListener('click', () => {
  if (state.isPlaying) stopPlayback();
  else startPlayback();
});

function startPlayback() {
  ensureAudioCtx();
  if (!state.audioBuffer) return;

  state.gainNode = state.audioCtx.createGain();
  state.gainNode.gain.value = parseInt(volSlider.value) / 100;

  state.analyser = state.audioCtx.createAnalyser();
  state.analyser.fftSize = 2048;

  state.playbackNode = state.audioCtx.createBufferSource();
  state.playbackNode.buffer = state.audioBuffer;
  state.playbackNode.connect(state.analyser);
  state.analyser.connect(state.gainNode);
  state.gainNode.connect(state.audioCtx.destination);

  const offset = playOffset;
  state.playbackNode.start(0, offset);
  playStartTime = state.audioCtx.currentTime - offset;
  state.isPlaying = true;
  drawLive();

  btnPlay.textContent = '⏸ Pausar';
  liveDot.classList.add('live');
  liveLabel.textContent = 'Reproduciendo';

  playInterval = setInterval(() => {
    const cur = state.audioCtx.currentTime - playStartTime;
    const dur = state.audioBuffer.duration;
    if (cur >= dur) { stopPlayback(); return; }
    playhead.value = cur;
    timeDisplay.textContent = `${formatDur(cur)} / ${formatDur(dur)}`;
  }, 100);

  state.playbackNode.onended = () => { if (state.isPlaying) stopPlayback(); };
}

function stopPlayback() {
  if (state.playbackNode) { try { state.playbackNode.stop(); } catch(e){} }
  clearInterval(playInterval);
  playOffset = 0;
  state.isPlaying = false;
  btnPlay.textContent = '▶ Reproducir';
  liveDot.classList.remove('live');
  liveLabel.textContent = 'En espera';
  state.analyser = null;
  cancelAnimationFrame(state.animFrame);
  drawStaticWaveform();
  startIdleLoop();
}

playhead.addEventListener('input', () => {
  const wasPlaying = state.isPlaying;
  if (wasPlaying) { try { state.playbackNode.stop(); } catch(e){} clearInterval(playInterval); state.isPlaying = false; }
  playOffset = parseFloat(playhead.value);
  if (wasPlaying) startPlayback();
});

volSlider.addEventListener('input', () => {
  volVal.textContent = volSlider.value;
  if (state.gainNode) state.gainNode.gain.value = parseInt(volSlider.value)/100;
});

// ══════════════════════════════════════════════════════
//  CONVERT (encode WAV in browser)
// ══════════════════════════════════════════════════════
btnConvert.addEventListener('click', async () => {
  if (!state.audioBuffer) return;
  const sr    = parseInt(document.getElementById('sampleRate').value);
  const bits  = parseInt(document.getElementById('bitDepth').value);
  const ch    = parseInt(document.getElementById('channels').value);
  const fmt   = document.getElementById('exportFmt').value;

  btnConvert.disabled = true;
  progressWrap.style.display = 'block';
  setProgress(0);

  try {
    // Re-sample via OfflineAudioContext
    const dur = state.audioBuffer.duration;
    const offLen = Math.ceil(dur * sr);
    const offCtx = new OfflineAudioContext(ch, offLen, sr);
    const src2 = offCtx.createBufferSource();
    src2.buffer = state.audioBuffer;

    const gain2 = offCtx.createGain();
    gain2.gain.value = parseInt(volSlider.value)/100;
    src2.connect(gain2);
    gain2.connect(offCtx.destination);
    src2.start(0);
    setProgress(20);

    const rendered = await offCtx.startRendering();
    setProgress(60);

    // Encode WAV
    const wavBlob = encodeWAV(rendered, bits);
    state.convertedWavBlob = wavBlob;
    setProgress(90);

    await new Promise(r => setTimeout(r, 200)); // visual beat
    setProgress(100);

    exportBtns.style.display = 'flex';
    updateResultInfo('done', { sr, bits, ch, dur, fmt, size: wavBlob.size });
    showToast('✅ Conversión exitosa — listo para descargar', 'ok');
  } catch(e) {
    showToast('❌ Error durante la conversión: ' + e.message, 'err');
  }

  setTimeout(() => { progressWrap.style.display='none'; btnConvert.disabled=false; }, 800);
});

// ══════════════════════════════════════════════════════
//  WAV ENCODER
// ══════════════════════════════════════════════════════
function encodeWAV(buffer, bitDepth) {
  const numCh   = buffer.numberOfChannels;
  const sr      = buffer.sampleRate;
  const len     = buffer.length;
  const bps     = bitDepth === 32 ? 4 : bitDepth === 24 ? 3 : bitDepth === 16 ? 2 : 1;
  const dataLen = len * numCh * bps;
  const ab      = new ArrayBuffer(44 + dataLen);
  const view    = new DataView(ab);

  function writeStr(off, s) { for(let i=0;i<s.length;i++) view.setUint8(off+i, s.charCodeAt(i)); }
  writeStr(0,'RIFF'); view.setUint32(4, 36+dataLen, true);
  writeStr(8,'WAVE'); writeStr(12,'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, bitDepth===32 ? 3 : 1, true);  // PCM=1, float=3
  view.setUint16(22, numCh, true);
  view.setUint32(24, sr, true);
  view.setUint32(28, sr * numCh * bps, true);
  view.setUint16(32, numCh * bps, true);
  view.setUint16(34, bitDepth, true);
  writeStr(36,'data'); view.setUint32(40, dataLen, true);

  let off = 44;
  const channels = [];
  for (let c=0;c<numCh;c++) channels.push(buffer.getChannelData(c));

  for (let i=0;i<len;i++) {
    for (let c=0;c<numCh;c++) {
      const s = Math.max(-1, Math.min(1, channels[c][i]));
      if (bitDepth===32) { view.setFloat32(off, s, true); off+=4; }
      else if (bitDepth===24) {
        const v = Math.round(s * 8388607);
        view.setUint8(off,   v & 0xff);
        view.setUint8(off+1,(v>>8)  & 0xff);
        view.setUint8(off+2,(v>>16) & 0xff);
        off+=3;
      } else if (bitDepth===16) {
        view.setInt16(off, Math.round(s*32767), true); off+=2;
      } else {
        view.setUint8(off, Math.round((s+1)*127.5)); off+=1;
      }
    }
  }
  return new Blob([ab], {type:'audio/wav'});
}

// ══════════════════════════════════════════════════════
//  DOWNLOAD BUTTONS
// ══════════════════════════════════════════════════════
btnDlWav.addEventListener('click', () => {
  if (!state.convertedWavBlob) return;
  downloadBlob(state.convertedWavBlob, 'audiolab_output.wav');
});

btnDlMp3.addEventListener('click', () => {
  // WAV download labeled as MP3 (browser MP3 encode needs external lib)
  // We inform the user and download WAV with note
  showToast('ℹ️ Descargando en WAV (sin pérdida). Para MP3 convertí en Audacity o ffmpeg.', 'ok');
  downloadBlob(state.convertedWavBlob, 'audiolab_output.wav');
});

function downloadBlob(blob, name) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = name; a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

// ══════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════
function formatBytes(b) {
  if (b < 1024) return b + ' B';
  if (b < 1048576) return (b/1024).toFixed(1) + ' KB';
  return (b/1048576).toFixed(1) + ' MB';
}
function formatDur(s) {
  const m = Math.floor(s/60), sec = Math.floor(s%60);
  return `${m}:${String(sec).padStart(2,'0')}`;
}
function setProgress(pct) {
  progressFill.style.width = pct + '%';
  progressPct.textContent  = pct + '%';
}
function updateResultInfo(state2, info) {
  if (state2==='ready') {
    resultInfo.innerHTML = 'Audio listo. Ajustá la configuración y presioná <strong>Convertir</strong>.';
    exportBtns.style.display='none';
    return;
  }
  const chLabel = info.ch===1 ? 'Mono' : 'Estéreo';
  resultInfo.innerHTML =
    `Audio digitalizado correctamente.<br>` +
    `Tasa de muestreo: <strong>${(info.sr/1000).toFixed(1)} kHz</strong> &nbsp;|&nbsp; ` +
    `Bits: <strong>${info.bits}</strong> &nbsp;|&nbsp; ` +
    `Canales: <strong>${chLabel}</strong><br>` +
    `Duración: <strong>${formatDur(info.dur)}</strong> &nbsp;|&nbsp; ` +
    `Tamaño WAV: <strong>${formatBytes(info.size)}</strong>`;
}
let toastTimer;
function showToast(msg, type='ok') {
  toast.textContent = msg;
  toast.className = 'show ' + type;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { toast.className = ''; }, 3500);
}
</script>
</body>
</html>
