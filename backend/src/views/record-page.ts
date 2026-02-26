import type { RecordingPageData } from '../services/recordings.service.js';

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export function renderRecordingPage(data: RecordingPageData, linkToken: string): string {
  const personName = escapeHtml(data.person_name);
  const requesterName = escapeHtml(data.requester_name);
  const questionText = escapeHtml(data.question_text);
  const journalTitle = escapeHtml(data.journal_title);

  if (data.already_answered) {
    return renderAlreadyAnsweredPage(personName, requesterName, questionText);
  }

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>VoiceJournal</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
  <style>
    /* ===== Reset ===== */
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

    /* ===== Variables ===== */
    :root {
      --flame: #FF6B35;
      --flame-soft: #FF8F5E;
      --ember: #E85D26;
      --red: #ef4444;
      --red-light: #f87171;
      --green: #4ade80;
    }

    /* ===== Background ===== */
    body {
      font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh;
      min-height: 100dvh;
      color: #fff;
      overflow-x: hidden;
      background: #1c0f2e;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }

    .bg {
      position: fixed; inset: 0; z-index: 0;
      background:
        radial-gradient(ellipse 120% 80% at 50% 0%, #3d1d5e 0%, transparent 60%),
        radial-gradient(ellipse 100% 60% at 20% 40%, rgba(200,80,50,0.35) 0%, transparent 55%),
        radial-gradient(ellipse 80% 50% at 80% 30%, rgba(180,100,40,0.25) 0%, transparent 50%),
        radial-gradient(ellipse 120% 60% at 50% 100%, rgba(240,160,60,0.3) 0%, transparent 50%),
        linear-gradient(170deg, #2a1545 0%, #3e1f5a 25%, #6d3560 45%, #b55a48 65%, #d98a45 80%, #e8b050 100%);
    }

    .bg::after {
      content: ''; position: fixed; inset: 0;
      opacity: 0.03; pointer-events: none;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
      background-size: 200px;
    }

    /* ===== Ambient orbs ===== */
    .orbs { position: fixed; inset: 0; z-index: 0; overflow: hidden; pointer-events: none; }
    .orb {
      position: absolute; border-radius: 50%;
      filter: blur(90px); will-change: transform;
    }
    .orb-1 {
      width: 380px; height: 380px;
      background: radial-gradient(circle, rgba(100,50,150,0.45), transparent 70%);
      top: -8%; left: -8%;
      animation: drift1 20s ease-in-out infinite alternate;
    }
    .orb-2 {
      width: 320px; height: 320px;
      background: radial-gradient(circle, rgba(210,90,50,0.35), transparent 70%);
      top: 35%; right: -12%;
      animation: drift2 26s ease-in-out infinite alternate;
    }
    .orb-3 {
      width: 400px; height: 400px;
      background: radial-gradient(circle, rgba(225,165,55,0.30), transparent 70%);
      bottom: -6%; left: 15%;
      animation: drift3 22s ease-in-out infinite alternate;
    }
    @keyframes drift1 {
      0% { transform: translate(0, 0) scale(1); }
      100% { transform: translate(50px, 35px) scale(1.08); }
    }
    @keyframes drift2 {
      0% { transform: translate(0, 0) scale(1); }
      100% { transform: translate(-40px, -25px) scale(1.05); }
    }
    @keyframes drift3 {
      0% { transform: translate(0, 0) scale(1); }
      100% { transform: translate(35px, -40px) scale(1.06); }
    }

    /* ===== Page layout ===== */
    .page {
      position: relative; z-index: 1;
      min-height: 100vh; min-height: 100dvh;
      display: flex; flex-direction: column; align-items: center;
      padding: 48px 20px 20px;
    }

    /* ===== Brand ===== */
    .brand {
      display: flex; align-items: center; justify-content: center; gap: 8px;
      margin-bottom: 28px;
    }
    .brand-dot { width: 5px; height: 5px; border-radius: 50%; background: var(--flame); opacity: 0.55; }
    .brand-name {
      font-size: 11px; font-weight: 600;
      letter-spacing: 2.5px; text-transform: uppercase;
      color: rgba(255,255,255,0.30);
    }

    /* ===== Stack: vertically centered, nudged above midpoint ===== */
    .stack-wrap {
      flex: 1; display: flex; align-items: center;
      width: 100%; max-width: 400px;
      padding-bottom: 56px;
    }
    .stack {
      width: 100%;
      display: flex; flex-direction: column; gap: 12px;
    }

    /* ===== Entrance animation ===== */
    .enter { opacity: 0; transform: translateY(16px); animation: enter 0.65s cubic-bezier(0.23,1,0.32,1) forwards; }
    .enter-d1 { animation-delay: 0.08s; }
    .enter-d2 { animation-delay: 0.2s; }
    @keyframes enter { to { opacity: 1; transform: translateY(0); } }

    /* ===== Glass material ===== */
    .glass {
      position: relative;
      background: rgba(255,255,255,0.08);
      border: 1px solid rgba(255,255,255,0.18);
      border-radius: 28px;
      backdrop-filter: blur(24px);
      -webkit-backdrop-filter: blur(24px);
      box-shadow: 0 20px 60px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.12);
      overflow: hidden;
    }
    .glass::after {
      content: ''; position: absolute; inset: 0; border-radius: inherit;
      opacity: 0.025; pointer-events: none;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 128 128' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='1.2' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
      background-size: 100px;
    }

    /* ===== Main card: greeting + question ===== */
    .main-card { padding: 28px 24px; }

    .greeting {
      font-family: 'DM Serif Display', Georgia, serif;
      font-size: 30px; font-weight: 400; line-height: 1.2;
      color: #fff; margin-bottom: 6px; text-align: center;
    }
    .from {
      font-size: 14px; font-weight: 400; color: rgba(255,255,255,0.40);
      letter-spacing: 0.1px; text-align: center;
    }
    .from-name { color: var(--flame-soft); font-weight: 500; }

    .card-divider {
      height: 1px; margin: 20px 0;
      background: linear-gradient(90deg, transparent, rgba(255,255,255,0.12) 20%, rgba(255,255,255,0.12) 80%, transparent);
    }

    .question {
      font-family: 'DM Serif Display', Georgia, serif;
      font-size: 20px; font-weight: 400; line-height: 1.45;
      color: rgba(255,255,255,0.92);
    }

    /* ===== Action module (second glass card) ===== */
    .action-card {
      padding: 24px;
      display: flex; flex-direction: column; align-items: center;
    }
    .action-card.hidden { display: none; }

    /* Recorder floats without glass — open and fluid */
    #recMod { padding: 20px 24px 12px; }

    /* ===== Record button ===== */
    .rec-wrap {
      position: relative;
      width: 112px; height: 112px;
      display: flex; align-items: center; justify-content: center;
    }
    .rec-ring {
      position: absolute; border-radius: 50%;
      border: 1px solid rgba(255,107,53,0.15);
      pointer-events: none;
    }
    .ring-1 { width: 112px; height: 112px; }
    .ring-2 {
      width: 140px; height: 140px;
      border-color: rgba(255,107,53,0.08);
      animation: breathe 3.5s ease-in-out infinite;
    }
    @keyframes breathe {
      0%, 100% { transform: scale(1); opacity: 1; }
      50% { transform: scale(1.05); opacity: 0.4; }
    }

    .rec-btn {
      width: 88px; height: 88px; border-radius: 50%;
      border: 2.5px solid var(--flame);
      background: transparent; cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      position: relative; z-index: 2;
      transition: all 0.35s cubic-bezier(0.34,1.56,0.64,1);
      -webkit-tap-highlight-color: transparent;
      touch-action: manipulation;
    }
    .rec-btn:active { transform: scale(0.93); }

    .rec-dot {
      width: 60px; height: 60px; border-radius: 50%;
      background: linear-gradient(145deg, var(--flame), var(--flame-soft));
      box-shadow: 0 4px 20px rgba(255,107,53,0.4), inset 0 1px 0 rgba(255,255,255,0.12);
      transition: all 0.35s cubic-bezier(0.34,1.56,0.64,1);
    }

    /* Recording state */
    .rec-btn.on { border-color: var(--red); }
    .rec-btn.on .rec-dot {
      width: 28px; height: 28px; border-radius: 8px;
      background: linear-gradient(145deg, var(--red), var(--red-light));
      box-shadow: 0 4px 20px rgba(239,68,68,0.45);
    }
    .rec-btn.on ~ .ring-1 { border-color: rgba(239,68,68,0.2); }
    .rec-btn.on ~ .ring-2 {
      border-color: rgba(239,68,68,0.1);
      animation: pulse 1.8s ease-out infinite;
    }
    @keyframes pulse {
      0% { transform: scale(1); opacity: 0.5; }
      100% { transform: scale(1.3); opacity: 0; }
    }

    /* ===== Timer ===== */
    .timer {
      font-size: 44px; font-weight: 400;
      font-variant-numeric: tabular-nums;
      letter-spacing: 2px;
      color: rgba(255,255,255,0.85);
      margin-bottom: 12px;
      display: none;
    }
    .timer.show { display: block; }

    /* ===== Level meter ===== */
    .meter {
      display: flex; align-items: flex-end; justify-content: center;
      gap: 2px; height: 36px; width: 100%; max-width: 220px;
      margin-bottom: 16px;
      opacity: 0; transition: opacity 0.35s ease;
    }
    .meter.active { opacity: 1; }
    .m-bar {
      flex: 1; max-width: 4px; min-height: 3px;
      border-radius: 2px;
      background: linear-gradient(0deg, var(--flame), var(--flame-soft));
      opacity: 0.65;
    }

    /* ===== Hint ===== */
    .hint {
      font-size: 13px; font-weight: 500;
      color: rgba(255,255,255,0.55);
      margin-top: 12px;
      letter-spacing: 0.2px;
    }

    /* ===== Custom audio player ===== */
    .player {
      display: flex; align-items: center; gap: 12px;
      width: 100%; margin-bottom: 20px;
    }
    .play-btn {
      width: 44px; height: 44px; border-radius: 50%;
      border: none; cursor: pointer; flex-shrink: 0;
      background: var(--flame);
      box-shadow: 0 4px 16px rgba(255,107,53,0.35);
      display: flex; align-items: center; justify-content: center;
      -webkit-tap-highlight-color: transparent;
      touch-action: manipulation;
      transition: transform 0.15s ease, box-shadow 0.15s ease;
    }
    .play-btn:active { transform: scale(0.92); box-shadow: 0 2px 8px rgba(255,107,53,0.3); }
    .play-btn svg { width: 16px; height: 16px; fill: #fff; }
    .play-btn .ico-pause { display: none; }
    .play-btn.playing .ico-play { display: none; }
    .play-btn.playing .ico-pause { display: block; }

    .p-time {
      font-size: 13px; font-weight: 500;
      font-variant-numeric: tabular-nums;
      color: rgba(255,255,255,0.45);
      flex-shrink: 0; min-width: 30px;
    }

    .p-track {
      flex: 1; height: 4px; border-radius: 2px;
      background: rgba(255,255,255,0.12);
      position: relative; cursor: pointer;
      -webkit-tap-highlight-color: transparent;
    }
    .p-fill {
      position: absolute; left: 0; top: 0;
      height: 100%; border-radius: 2px;
      background: var(--flame);
      width: 0%; pointer-events: none;
    }
    .p-knob {
      position: absolute; top: 50%;
      width: 14px; height: 14px; border-radius: 50%;
      background: #fff;
      box-shadow: 0 1px 6px rgba(0,0,0,0.25);
      transform: translate(-50%, -50%);
      left: 0%; pointer-events: none;
      transition: transform 0.1s ease;
    }
    .p-track:active .p-knob { transform: translate(-50%, -50%) scale(1.3); }

    /* ===== Button system ===== */
    .actions { display: flex; gap: 12px; width: 100%; }

    .btn {
      flex: 1; height: 52px;
      border-radius: 999px; border: none;
      font-family: 'DM Sans', sans-serif;
      font-size: 15px; font-weight: 600;
      cursor: pointer; letter-spacing: 0.2px;
      display: flex; align-items: center; justify-content: center;
      -webkit-tap-highlight-color: transparent;
      touch-action: manipulation;
      transition: transform 0.15s ease, box-shadow 0.15s ease, opacity 0.15s ease;
    }
    .btn:active { transform: scale(0.97); }

    .btn-secondary {
      background: rgba(255,255,255,0.07);
      border: 1px solid rgba(255,255,255,0.15);
      color: rgba(255,255,255,0.75);
    }
    .btn-secondary:active { background: rgba(255,255,255,0.12); }

    .btn-primary {
      background: linear-gradient(135deg, var(--flame), var(--ember));
      color: #fff;
      box-shadow: 0 6px 24px rgba(255,107,53,0.35);
    }
    .btn-primary:active { box-shadow: 0 3px 12px rgba(255,107,53,0.3); }
    .btn-primary:disabled { opacity: 0.45; cursor: not-allowed; transform: none; }

    /* ===== Spinner ===== */
    .spinner {
      width: 40px; height: 40px;
      border: 2.5px solid rgba(255,255,255,0.1);
      border-top-color: var(--flame);
      border-radius: 50%;
      animation: spin 0.7s linear infinite;
      margin-bottom: 16px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    .upload-label {
      font-size: 14px; font-weight: 400;
      color: rgba(255,255,255,0.40);
      letter-spacing: 0.2px;
    }

    /* ===== Success screen ===== */
    .success-screen {
      position: fixed; inset: 0; z-index: 10;
      display: none; flex-direction: column;
      align-items: center; justify-content: center;
      padding: 24px;
    }
    .success-screen.show {
      display: flex;
      animation: fadeIn 0.4s ease forwards;
    }
    @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

    .check-circle {
      width: 80px; height: 80px; border-radius: 50%;
      background: linear-gradient(145deg, rgba(74,222,128,0.18), rgba(34,197,94,0.06));
      border: 1.5px solid rgba(74,222,128,0.25);
      display: flex; align-items: center; justify-content: center;
      margin-bottom: 24px;
      animation: scaleIn 0.5s 0.1s cubic-bezier(0.34,1.56,0.64,1) both;
    }
    @keyframes scaleIn { from { transform: scale(0.5); opacity: 0; } to { transform: scale(1); opacity: 1; } }

    .check-circle svg {
      width: 36px; height: 36px;
      stroke: var(--green); stroke-width: 2.5;
      fill: none; stroke-linecap: round; stroke-linejoin: round;
    }
    .check-circle svg path {
      stroke-dasharray: 40; stroke-dashoffset: 40;
      animation: draw 0.4s 0.4s ease forwards;
    }
    @keyframes draw { to { stroke-dashoffset: 0; } }

    .success-title {
      font-family: 'DM Serif Display', Georgia, serif;
      font-size: 28px; font-weight: 400;
      margin-bottom: 10px;
      animation: scaleIn 0.5s 0.2s cubic-bezier(0.34,1.56,0.64,1) both;
    }
    .success-text {
      font-size: 15px; line-height: 1.6;
      color: rgba(255,255,255,0.40);
      text-align: center;
      animation: scaleIn 0.5s 0.3s cubic-bezier(0.34,1.56,0.64,1) both;
    }

    /* ===== Notice modules ===== */
    .notice-icon { font-size: 36px; line-height: 1; margin-bottom: 16px; }
    .notice-text {
      font-size: 14px; line-height: 1.7;
      color: rgba(255,255,255,0.50);
      text-align: center; max-width: 280px;
      margin-bottom: 20px;
    }

    /* ===== Error toast ===== */
    .error-toast {
      display: none; width: 100%; max-width: 400px;
      margin-top: 12px;
      font-size: 13px; color: #fca5a5;
      text-align: center;
      padding: 14px 20px;
      background: rgba(239,68,68,0.10);
      border: 1px solid rgba(239,68,68,0.18);
      border-radius: 999px;
    }
    .error-toast.show { display: block; }

    /* ===== Footer ===== */
    .foot {
      text-align: center; padding: 20px;
      position: relative; z-index: 1;
    }
    .foot span {
      font-size: 11px; font-weight: 500;
      color: rgba(255,255,255,0.35);
      letter-spacing: 0.3px;
    }

    .success-foot {
      position: absolute; bottom: 24px; left: 0; right: 0;
      text-align: center;
    }
    .success-foot span {
      font-size: 11px; color: rgba(255,255,255,0.14); letter-spacing: 0.3px;
    }
  </style>
</head>
<body>
  <div class="bg"></div>
  <div class="orbs"><div class="orb orb-1"></div><div class="orb orb-2"></div><div class="orb orb-3"></div></div>

  <div class="page" id="page">
    <div class="brand enter">
      <span class="brand-dot"></span>
      <span class="brand-name">VoiceJournal</span>
      <span class="brand-dot"></span>
    </div>

    <div class="stack-wrap">
      <div class="stack">
        <!-- Main card -->
        <div class="glass main-card enter enter-d1">
          <div class="greeting">Hi ${personName},</div>
          <div class="from">A question from <span class="from-name">${requesterName}</span></div>
          <div class="card-divider"></div>
          <div class="question">${questionText}</div>
        </div>

        <!-- Action: idle / recording -->
        <div class="action-card enter enter-d2" id="recMod">
          <div class="timer" id="timer">0:00</div>
          <div class="meter" id="meter"></div>
          <div class="rec-wrap">
            <button class="rec-btn" id="recBtn"><div class="rec-dot"></div></button>
            <div class="rec-ring ring-1"></div>
            <div class="rec-ring ring-2"></div>
          </div>
          <div class="hint" id="recHint">Tap to record</div>
        </div>

        <!-- Action: review -->
        <div class="glass action-card hidden" id="reviewMod">
          <div class="player">
            <button class="play-btn" id="playBtn">
              <svg class="ico-play" viewBox="0 0 24 24"><polygon points="8,5 20,12 8,19"/></svg>
              <svg class="ico-pause" viewBox="0 0 24 24"><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>
            </button>
            <span class="p-time" id="curTime">0:00</span>
            <div class="p-track" id="pTrack">
              <div class="p-fill" id="pFill"></div>
              <div class="p-knob" id="pKnob"></div>
            </div>
            <span class="p-time" id="totTime">0:00</span>
          </div>
          <div class="actions">
            <button class="btn btn-secondary" id="reRecBtn">Re-record</button>
            <button class="btn btn-primary" id="sendBtn">Send recording</button>
          </div>
        </div>

        <!-- Action: uploading -->
        <div class="glass action-card hidden" id="uploadMod">
          <div class="spinner"></div>
          <div class="upload-label">Sending your story&hellip;</div>
        </div>

        <!-- Action: unsupported browser -->
        <div class="glass action-card hidden" id="unsupportedMod">
          <div class="notice-icon">&#x1F399;&#xFE0F;</div>
          <p class="notice-text">Your browser doesn&rsquo;t support recording. Open this link in Safari to record your answer.</p>
          <a class="btn btn-primary" id="safariLink" href="#" style="flex:none;width:auto;padding:0 28px;text-decoration:none;">Open in Safari</a>
        </div>

        <!-- Action: permission denied -->
        <div class="glass action-card hidden" id="permMod">
          <div class="notice-icon">&#x1F512;</div>
          <p class="notice-text">Microphone access is needed to record your answer. Enable it in your browser settings, then refresh this page.</p>
        </div>

        <!-- Error toast -->
        <div class="error-toast" id="errorToast"></div>
      </div>
    </div>

    <div class="foot"><span>Powered by VoiceJournal</span></div>
  </div>

  <!-- Success overlay -->
  <div class="success-screen" id="successScreen">
    <div class="check-circle">
      <svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7"/></svg>
    </div>
    <div class="success-title">Thank you</div>
    <div class="success-text">Your story has been saved.<br>${requesterName} will be notified.</div>
    <div class="success-foot"><span>Powered by VoiceJournal</span></div>
  </div>

  <script>
    /* ===== Constants ===== */
    var LINK_TOKEN = '${linkToken}';
    var API_BASE = window.location.origin + '/v1';
    var MAX_DURATION = 180;
    var NUM_BARS = 28;

    /* ===== State ===== */
    var mediaRecorder = null;
    var audioChunks = [];
    var audioBlob = null;
    var audioEl = null;
    var isRecording = false;
    var timerInterval = null;
    var startTime = 0;
    var duration = 0;
    var audioCtx = null;
    var analyser = null;
    var dataArray = null;
    var bars = [];
    var smoothed = [];
    var animId = null;
    var isPlaying = false;
    var isSeeking = false;

    /* ===== Init ===== */
    (function init() {
      var supported = !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);

      if (!supported) {
        hide('recMod');
        show('unsupportedMod');
        var link = document.getElementById('safariLink');
        if (link) link.href = 'x-safari-' + window.location.href;
        return;
      }

      /* Build meter bars */
      var meter = document.getElementById('meter');
      for (var i = 0; i < NUM_BARS; i++) {
        var bar = document.createElement('div');
        bar.className = 'm-bar';
        bar.style.height = '3px';
        meter.appendChild(bar);
        bars.push(bar);
        smoothed.push(0);
      }

      /* Event listeners */
      var recBtn = document.getElementById('recBtn');
      recBtn.addEventListener('click', toggleRecording);
      recBtn.addEventListener('touchend', function(e) { e.preventDefault(); toggleRecording(); });

      document.getElementById('reRecBtn').addEventListener('click', reRecord);
      document.getElementById('sendBtn').addEventListener('click', submitRecording);
      document.getElementById('playBtn').addEventListener('click', togglePlay);

      /* Progress bar seeking */
      var track = document.getElementById('pTrack');
      track.addEventListener('click', seek);
      track.addEventListener('touchstart', function(e) { isSeeking = true; seekTouch(e); }, { passive: true });
      track.addEventListener('touchmove', function(e) { if (isSeeking) seekTouch(e); }, { passive: true });
      track.addEventListener('touchend', function() { isSeeking = false; });
    })();

    /* ===== Recording ===== */
    async function toggleRecording() {
      if (isRecording) stopRecording();
      else await startRecording();
    }

    async function startRecording() {
      try {
        var stream = await navigator.mediaDevices.getUserMedia({ audio: true });

        var types = ['audio/mp4', 'audio/webm;codecs=opus', 'audio/webm', 'audio/ogg;codecs=opus'];
        var mime = '';
        for (var i = 0; i < types.length; i++) {
          if (MediaRecorder.isTypeSupported(types[i])) { mime = types[i]; break; }
        }

        mediaRecorder = new MediaRecorder(stream, mime ? { mimeType: mime } : {});
        audioChunks = [];

        mediaRecorder.ondataavailable = function(e) {
          if (e.data.size > 0) audioChunks.push(e.data);
        };

        mediaRecorder.onstop = function() {
          stream.getTracks().forEach(function(t) { t.stop(); });
          audioBlob = new Blob(audioChunks, { type: mediaRecorder.mimeType || 'audio/mp4' });
          stopMeter();
          showModule('reviewMod');
          initPlayer();
        };

        mediaRecorder.start(1000);
        isRecording = true;
        startTime = Date.now();
        duration = 0;

        document.getElementById('recBtn').classList.add('on');
        document.getElementById('recHint').textContent = 'Tap to stop';
        document.getElementById('timer').classList.add('show');
        document.getElementById('timer').textContent = '0:00';

        timerInterval = setInterval(function() {
          duration = Math.floor((Date.now() - startTime) / 1000);
          document.getElementById('timer').textContent = fmtTime(duration);
          if (duration >= MAX_DURATION) stopRecording();
        }, 250);

        startMeter(stream);
      } catch (err) {
        console.error('Mic error:', err);
        if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
          hide('recMod');
          show('permMod');
        } else {
          showError('Could not access microphone: ' + (err.message || 'Unknown error'));
        }
      }
    }

    function stopRecording() {
      if (mediaRecorder && mediaRecorder.state !== 'inactive') mediaRecorder.stop();
      isRecording = false;
      clearInterval(timerInterval);
      document.getElementById('recBtn').classList.remove('on');
    }

    /* ===== Level meter ===== */
    function startMeter(stream) {
      try {
        var AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return;
        audioCtx = new AC();
        analyser = audioCtx.createAnalyser();
        analyser.fftSize = 64;
        var source = audioCtx.createMediaStreamSource(stream);
        source.connect(analyser);
        dataArray = new Uint8Array(analyser.frequencyBinCount);
        document.getElementById('meter').classList.add('active');
        updateMeter();
      } catch (e) { /* meter is optional enhancement */ }
    }

    function updateMeter() {
      if (!isRecording) return;
      analyser.getByteFrequencyData(dataArray);
      var binCount = dataArray.length;
      for (var i = 0; i < NUM_BARS; i++) {
        var idx = Math.floor(i * binCount / NUM_BARS);
        var raw = (dataArray[idx] || 0) / 255;
        smoothed[i] = smoothed[i] * 0.65 + raw * 0.35;
        bars[i].style.height = Math.max(3, smoothed[i] * 36) + 'px';
      }
      animId = requestAnimationFrame(updateMeter);
    }

    function stopMeter() {
      if (animId) cancelAnimationFrame(animId);
      document.getElementById('meter').classList.remove('active');
      if (audioCtx) { try { audioCtx.close(); } catch(e) {} audioCtx = null; }
      for (var i = 0; i < NUM_BARS; i++) {
        smoothed[i] = 0;
        if (bars[i]) bars[i].style.height = '3px';
      }
    }

    /* ===== Custom audio player ===== */
    function initPlayer() {
      if (audioEl) { audioEl.pause(); audioEl = null; }
      audioEl = new Audio();
      audioEl.src = URL.createObjectURL(audioBlob);
      isPlaying = false;
      document.getElementById('playBtn').classList.remove('playing');
      document.getElementById('curTime').textContent = '0:00';
      document.getElementById('pFill').style.width = '0%';
      document.getElementById('pKnob').style.left = '0%';

      audioEl.addEventListener('loadedmetadata', function() {
        var d = Math.floor(audioEl.duration);
        if (isNaN(d)) d = duration;
        document.getElementById('totTime').textContent = fmtTime(d);
      });

      audioEl.addEventListener('timeupdate', function() {
        if (isSeeking) return;
        var cur = audioEl.currentTime;
        var tot = audioEl.duration || 1;
        var pct = (cur / tot) * 100;
        document.getElementById('curTime').textContent = fmtTime(Math.floor(cur));
        document.getElementById('pFill').style.width = pct + '%';
        document.getElementById('pKnob').style.left = pct + '%';
      });

      audioEl.addEventListener('ended', function() {
        isPlaying = false;
        document.getElementById('playBtn').classList.remove('playing');
        document.getElementById('pFill').style.width = '0%';
        document.getElementById('pKnob').style.left = '0%';
        document.getElementById('curTime').textContent = '0:00';
      });

      /* Set total time from recording duration as fallback */
      document.getElementById('totTime').textContent = fmtTime(duration);
    }

    function togglePlay() {
      if (!audioEl) return;
      if (isPlaying) {
        audioEl.pause();
        isPlaying = false;
        document.getElementById('playBtn').classList.remove('playing');
      } else {
        audioEl.play();
        isPlaying = true;
        document.getElementById('playBtn').classList.add('playing');
      }
    }

    function seek(e) {
      if (!audioEl || !audioEl.duration) return;
      var rect = document.getElementById('pTrack').getBoundingClientRect();
      var pct = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
      audioEl.currentTime = pct * audioEl.duration;
    }

    function seekTouch(e) {
      if (!audioEl || !audioEl.duration || !e.touches[0]) return;
      var rect = document.getElementById('pTrack').getBoundingClientRect();
      var pct = Math.max(0, Math.min(1, (e.touches[0].clientX - rect.left) / rect.width));
      audioEl.currentTime = pct * audioEl.duration;
      document.getElementById('pFill').style.width = (pct * 100) + '%';
      document.getElementById('pKnob').style.left = (pct * 100) + '%';
    }

    /* ===== Re-record ===== */
    function reRecord() {
      if (audioEl) { audioEl.pause(); audioEl = null; }
      isPlaying = false;
      audioBlob = null;
      audioChunks = [];
      duration = 0;
      hideError();
      showModule('recMod');
      document.getElementById('timer').classList.remove('show');
      document.getElementById('recHint').textContent = 'Tap to record';
      document.getElementById('timer').textContent = '0:00';
    }

    /* ===== Upload ===== */
    async function submitRecording() {
      if (!audioBlob) return;
      document.getElementById('sendBtn').disabled = true;
      showModule('uploadMod');
      hideError();

      try {
        var fd = new FormData();
        var ext = audioBlob.type.indexOf('mp4') !== -1 ? '.m4a' : audioBlob.type.indexOf('ogg') !== -1 ? '.ogg' : '.webm';
        fd.append('audio', audioBlob, 'recording' + ext);
        fd.append('duration_seconds', String(duration));

        var resp = await fetch(API_BASE + '/record/' + LINK_TOKEN + '/upload', { method: 'POST', body: fd });
        if (!resp.ok) {
          var d = await resp.json().catch(function() { return {}; });
          throw new Error((d.error && d.error.message) || 'Upload failed');
        }

        document.getElementById('page').style.display = 'none';
        document.getElementById('successScreen').classList.add('show');
      } catch (err) {
        console.error('Upload error:', err);
        showModule('reviewMod');
        document.getElementById('sendBtn').disabled = false;
        showError(err.message || 'Upload failed. Please try again.');
      }
    }

    /* ===== Module visibility helpers ===== */
    var modules = ['recMod', 'reviewMod', 'uploadMod', 'unsupportedMod', 'permMod'];

    function showModule(id) {
      for (var i = 0; i < modules.length; i++) {
        var el = document.getElementById(modules[i]);
        if (modules[i] === id) el.classList.remove('hidden');
        else el.classList.add('hidden');
      }
    }

    function show(id) { document.getElementById(id).classList.remove('hidden'); }
    function hide(id) { document.getElementById(id).classList.add('hidden'); }

    /* ===== Error ===== */
    function showError(msg) {
      var el = document.getElementById('errorToast');
      el.textContent = msg;
      el.classList.add('show');
    }
    function hideError() {
      document.getElementById('errorToast').classList.remove('show');
    }

    /* ===== Utils ===== */
    function fmtTime(s) {
      var m = Math.floor(s / 60);
      var sec = s % 60;
      return m + ':' + (sec < 10 ? '0' : '') + sec;
    }
  </script>
</body>
</html>`;
}

function renderAlreadyAnsweredPage(personName: string, requesterName: string, questionText: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VoiceJournal</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:opsz,wght@9..40,400;9..40,500&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }
    :root { --green: #4ade80; }
    body {
      font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh; min-height: 100dvh;
      display: flex; flex-direction: column;
      align-items: center; justify-content: center;
      color: #fff; background: #1c0f2e; padding: 24px;
      -webkit-font-smoothing: antialiased;
    }
    .bg {
      position: fixed; inset: 0; z-index: 0;
      background:
        radial-gradient(ellipse 120% 80% at 50% 0%, #3d1d5e 0%, transparent 60%),
        radial-gradient(ellipse 100% 60% at 20% 40%, rgba(200,80,50,0.35) 0%, transparent 55%),
        radial-gradient(ellipse 120% 60% at 50% 100%, rgba(240,160,60,0.3) 0%, transparent 50%),
        linear-gradient(170deg, #2a1545 0%, #3e1f5a 25%, #6d3560 45%, #b55a48 65%, #d98a45 80%, #e8b050 100%);
    }
    .bg::after {
      content: ''; position: fixed; inset: 0;
      opacity: 0.03; pointer-events: none;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
      background-size: 200px;
    }
    .wrap {
      position: relative; z-index: 1; text-align: center;
      max-width: 360px;
      opacity: 0; transform: translateY(16px);
      animation: up 0.65s 0.1s cubic-bezier(0.23,1,0.32,1) forwards;
    }
    @keyframes up { to { opacity: 1; transform: translateY(0); } }
    .icon {
      width: 80px; height: 80px; border-radius: 50%;
      background: linear-gradient(145deg, rgba(74,222,128,0.18), rgba(34,197,94,0.06));
      border: 1.5px solid rgba(74,222,128,0.25);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 24px;
    }
    .icon svg {
      width: 36px; height: 36px;
      stroke: var(--green); stroke-width: 2.5;
      fill: none; stroke-linecap: round; stroke-linejoin: round;
    }
    h1 {
      font-family: 'DM Serif Display', Georgia, serif;
      font-size: 28px; font-weight: 400; margin-bottom: 10px;
    }
    p {
      font-size: 15px; line-height: 1.6;
      color: rgba(255,255,255,0.40);
    }
    .foot {
      position: fixed; bottom: 24px; left: 0; right: 0;
      text-align: center; z-index: 1;
    }
    .foot span { font-size: 11px; color: rgba(255,255,255,0.14); letter-spacing: 0.3px; }
  </style>
</head>
<body>
  <div class="bg"></div>
  <div class="wrap">
    <div class="icon"><svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7"/></svg></div>
    <h1>Already Answered</h1>
    <p>This question has already been answered.<br>Thank you for sharing your story!</p>
  </div>
  <div class="foot"><span>Powered by VoiceJournal</span></div>
</body>
</html>`;
}
