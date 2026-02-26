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
  <title>VoiceJournal — Record Your Answer</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --flame: #FF6B35;
      --flame-light: #FF8F5E;
      --ember: #E85D26;
      --gold: #C47F17;
      --plum: #4a2060;
      --glass-bg: rgba(255,255,255,0.08);
      --glass-border: rgba(255,255,255,0.13);
      --glass-glow: rgba(255,180,120,0.06);
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh;
      min-height: 100dvh;
      display: flex;
      flex-direction: column;
      align-items: center;
      color: #fff;
      overflow-x: hidden;
      background: #1c0f2e;
    }

    /* Layered atmospheric background */
    .bg {
      position: fixed;
      inset: 0;
      z-index: 0;
      background:
        radial-gradient(ellipse 120% 80% at 50% 0%, #3d1d5e 0%, transparent 60%),
        radial-gradient(ellipse 100% 60% at 20% 40%, rgba(200,80,50,0.35) 0%, transparent 55%),
        radial-gradient(ellipse 80% 50% at 80% 30%, rgba(180,100,40,0.25) 0%, transparent 50%),
        radial-gradient(ellipse 120% 60% at 50% 100%, rgba(240,160,60,0.3) 0%, transparent 50%),
        linear-gradient(170deg, #2a1545 0%, #3e1f5a 25%, #6d3560 45%, #b55a48 65%, #d98a45 80%, #e8b050 100%);
    }

    /* Subtle grain texture overlay */
    .bg::after {
      content: '';
      position: fixed;
      inset: 0;
      opacity: 0.035;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
      background-size: 200px;
      pointer-events: none;
    }

    .container {
      max-width: 440px;
      width: 100%;
      flex: 1;
      display: flex;
      flex-direction: column;
      padding: 56px 24px 24px;
      position: relative;
      z-index: 1;
    }

    /* Staggered entrance animation */
    .anim-up {
      opacity: 0;
      transform: translateY(18px);
      animation: fadeUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) forwards;
    }
    .anim-up:nth-child(1) { animation-delay: 0.1s; }
    .anim-up:nth-child(2) { animation-delay: 0.22s; }
    .anim-up:nth-child(3) { animation-delay: 0.36s; }
    .anim-up:nth-child(4) { animation-delay: 0.5s; }

    @keyframes fadeUp {
      to { opacity: 1; transform: translateY(0); }
    }

    /* Brand mark */
    .brand {
      text-align: center;
      margin-bottom: 44px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }

    .brand-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--flame);
      opacity: 0.7;
    }

    .brand-text {
      font-family: 'DM Sans', sans-serif;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 3px;
      text-transform: uppercase;
      color: rgba(255,255,255,0.4);
    }

    /* Greeting */
    .greeting-section {
      text-align: center;
      margin-bottom: 32px;
    }

    .greeting {
      font-family: 'DM Serif Display', Georgia, serif;
      font-size: 32px;
      font-weight: 400;
      color: #fff;
      margin-bottom: 8px;
      line-height: 1.2;
    }

    .from-line {
      font-size: 14px;
      color: rgba(255,255,255,0.5);
      font-weight: 400;
      letter-spacing: 0.2px;
    }

    .from-name {
      color: var(--flame-light);
      font-weight: 500;
    }

    /* Glass question card */
    .q-card {
      position: relative;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 24px;
      padding: 28px 24px;
      backdrop-filter: blur(24px);
      -webkit-backdrop-filter: blur(24px);
      margin-bottom: 40px;
      overflow: hidden;
    }

    .q-card::before {
      content: '';
      position: absolute;
      inset: 0;
      border-radius: 24px;
      background: linear-gradient(135deg, var(--glass-glow), transparent 60%);
      pointer-events: none;
    }

    .q-label {
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 2px;
      color: rgba(255,255,255,0.35);
      margin-bottom: 14px;
      font-weight: 600;
      position: relative;
    }

    .q-text {
      font-family: 'DM Serif Display', Georgia, serif;
      font-size: 22px;
      font-weight: 400;
      line-height: 1.4;
      color: rgba(255,255,255,0.95);
      position: relative;
    }

    /* Record section */
    .recorder {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
      padding: 8px 0 24px;
    }

    .timer {
      font-family: 'DM Sans', sans-serif;
      font-size: 48px;
      font-weight: 400;
      font-variant-numeric: tabular-nums;
      color: rgba(255,255,255,0.9);
      letter-spacing: 3px;
      height: 58px;
      opacity: 0;
      transition: opacity 0.4s ease;
    }

    .timer.visible { opacity: 1; }

    /* Record button with concentric rings */
    .rec-wrap {
      position: relative;
      width: 120px;
      height: 120px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .rec-ring {
      position: absolute;
      border-radius: 50%;
      border: 1px solid rgba(255,107,53,0.12);
      pointer-events: none;
    }

    .rec-ring-1 { width: 120px; height: 120px; }
    .rec-ring-2 {
      width: 148px;
      height: 148px;
      border-color: rgba(255,107,53,0.06);
      animation: breathe 4s ease-in-out infinite;
    }

    @keyframes breathe {
      0%, 100% { transform: scale(1); opacity: 1; }
      50% { transform: scale(1.04); opacity: 0.5; }
    }

    .rec-btn {
      width: 96px;
      height: 96px;
      border-radius: 50%;
      border: 3px solid var(--flame);
      background: transparent;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
      position: relative;
      z-index: 2;
      -webkit-tap-highlight-color: transparent;
      touch-action: manipulation;
    }

    .rec-btn:active { transform: scale(0.93); }

    .rec-btn .dot {
      width: 68px;
      height: 68px;
      border-radius: 50%;
      background: linear-gradient(145deg, var(--flame), var(--flame-light));
      transition: all 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
      box-shadow:
        0 4px 20px rgba(255,107,53,0.45),
        inset 0 1px 0 rgba(255,255,255,0.15);
    }

    .rec-btn.on { border-color: #ef4444; }

    .rec-btn.on .dot {
      width: 32px;
      height: 32px;
      border-radius: 10px;
      background: linear-gradient(145deg, #ef4444, #f87171);
      box-shadow: 0 4px 20px rgba(239,68,68,0.5);
    }

    .rec-btn.on ~ .rec-ring-1 { border-color: rgba(239,68,68,0.2); }
    .rec-btn.on ~ .rec-ring-2 {
      border-color: rgba(239,68,68,0.08);
      animation: pulse-ring 1.6s ease-out infinite;
    }

    @keyframes pulse-ring {
      0% { transform: scale(1); opacity: 0.6; }
      100% { transform: scale(1.25); opacity: 0; }
    }

    .hint {
      font-size: 14px;
      color: rgba(255,255,255,0.4);
      text-align: center;
      letter-spacing: 0.3px;
      transition: color 0.3s;
    }

    /* Review */
    .review {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 20px;
      padding: 16px 0;
    }
    .review.visible { display: flex; }

    .player-card {
      width: 100%;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 20px;
      padding: 20px;
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
    }

    .player-card audio {
      width: 100%;
      height: 44px;
      border-radius: 12px;
    }

    .actions {
      display: flex;
      gap: 12px;
      width: 100%;
    }

    .btn {
      flex: 1;
      padding: 16px 20px;
      border-radius: 16px;
      border: none;
      font-family: 'DM Sans', sans-serif;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
      -webkit-tap-highlight-color: transparent;
      touch-action: manipulation;
      letter-spacing: 0.2px;
    }

    .btn:active { transform: scale(0.97); }

    .btn-ghost {
      background: rgba(255,255,255,0.07);
      color: rgba(255,255,255,0.8);
      border: 1px solid rgba(255,255,255,0.12);
    }

    .btn-warm {
      background: linear-gradient(135deg, var(--flame), var(--ember));
      color: #fff;
      box-shadow: 0 6px 24px rgba(255,107,53,0.35);
    }

    .btn-warm:disabled { opacity: 0.5; cursor: not-allowed; }

    /* Uploading */
    .uploading {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 24px;
      padding: 48px 0;
    }
    .uploading.visible { display: flex; }

    .orbit {
      width: 48px;
      height: 48px;
      border: 2.5px solid rgba(255,255,255,0.1);
      border-top-color: var(--flame);
      border-radius: 50%;
      animation: spin 0.75s linear infinite;
    }

    @keyframes spin { to { transform: rotate(360deg); } }

    .uploading-label {
      font-size: 14px;
      color: rgba(255,255,255,0.5);
      letter-spacing: 0.3px;
    }

    /* Success */
    .success {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 20px;
      text-align: center;
      padding: 48px 0;
    }
    .success.visible { display: flex; }

    .check-wrap {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: linear-gradient(145deg, rgba(74,222,128,0.2), rgba(34,197,94,0.08));
      border: 1.5px solid rgba(74,222,128,0.25);
      display: flex;
      align-items: center;
      justify-content: center;
      animation: scaleIn 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
    }

    @keyframes scaleIn {
      0% { transform: scale(0.5); opacity: 0; }
      100% { transform: scale(1); opacity: 1; }
    }

    .check-wrap svg {
      width: 36px;
      height: 36px;
      stroke: #4ade80;
      stroke-width: 2.5;
      fill: none;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    .check-wrap svg path {
      stroke-dasharray: 40;
      stroke-dashoffset: 40;
      animation: drawCheck 0.4s 0.3s ease forwards;
    }

    @keyframes drawCheck {
      to { stroke-dashoffset: 0; }
    }

    .success h2 {
      font-family: 'DM Serif Display', Georgia, serif;
      font-size: 28px;
      font-weight: 400;
      color: #fff;
    }

    .success p {
      color: rgba(255,255,255,0.45);
      font-size: 15px;
      line-height: 1.6;
    }

    /* Error */
    .error-msg {
      display: none;
      color: #fca5a5;
      font-size: 13px;
      text-align: center;
      padding: 14px 16px;
      background: rgba(239,68,68,0.1);
      border: 1px solid rgba(239,68,68,0.15);
      border-radius: 14px;
      margin-top: 8px;
    }
    .error-msg.visible { display: block; }

    /* Notices */
    .notice {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 24px;
      text-align: center;
      padding: 40px 0;
    }
    .notice.visible { display: flex; }

    .notice-ico {
      font-size: 44px;
      line-height: 1;
    }

    .notice p {
      color: rgba(255,255,255,0.55);
      font-size: 15px;
      line-height: 1.7;
      max-width: 320px;
    }

    .safari-link {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 14px 28px;
      background: linear-gradient(135deg, var(--flame), var(--ember));
      color: #fff;
      font-family: 'DM Sans', sans-serif;
      font-size: 15px;
      font-weight: 600;
      border: none;
      border-radius: 16px;
      cursor: pointer;
      text-decoration: none;
      -webkit-tap-highlight-color: transparent;
      box-shadow: 0 6px 24px rgba(255,107,53,0.3);
    }

    .safari-link:active { transform: scale(0.97); }

    /* Footer */
    .foot {
      text-align: center;
      padding: 16px 20px 24px;
      position: relative;
      z-index: 1;
    }

    .foot span {
      font-size: 11px;
      color: rgba(255,255,255,0.18);
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
  <div class="bg"></div>

  <div class="container">
    <div class="brand anim-up">
      <span class="brand-dot"></span>
      <span class="brand-text">VoiceJournal</span>
      <span class="brand-dot"></span>
    </div>

    <div class="greeting-section anim-up">
      <div class="greeting">Hi ${personName},</div>
      <div class="from-line">A question from <span class="from-name">${requesterName}</span></div>
    </div>

    <div class="q-card anim-up">
      <div class="q-label">Question</div>
      <div class="q-text">${questionText}</div>
    </div>

    <!-- Unsupported browser -->
    <div class="notice" id="unsupportedSection">
      <div class="notice-ico">🎙️</div>
      <p>Your browser doesn't support recording. Please open this link in Safari to record your answer.</p>
      <a class="safari-link" id="safariLink" href="#">Open in Safari</a>
    </div>

    <!-- Record -->
    <div class="recorder anim-up" id="recorderSection">
      <div class="timer" id="timer">0:00</div>
      <div class="rec-wrap">
        <button class="rec-btn" id="recordBtn"><div class="dot"></div></button>
        <div class="rec-ring rec-ring-1"></div>
        <div class="rec-ring rec-ring-2"></div>
      </div>
      <div class="hint" id="hint">Tap to start recording</div>
    </div>

    <!-- Review -->
    <div class="review" id="reviewSection">
      <div class="player-card">
        <div id="audioPlayer"></div>
      </div>
      <div class="actions">
        <button class="btn btn-ghost" id="reRecordBtn">Re-record</button>
        <button class="btn btn-warm" id="submitBtn">Send recording</button>
      </div>
    </div>

    <!-- Uploading -->
    <div class="uploading" id="uploadingSection">
      <div class="orbit"></div>
      <div class="uploading-label">Sending your recording...</div>
    </div>

    <!-- Success -->
    <div class="success" id="successSection">
      <div class="check-wrap">
        <svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7"/></svg>
      </div>
      <h2>Thank you</h2>
      <p>Your voice has been saved.<br>${requesterName} will be notified.</p>
    </div>

    <!-- Permission denied -->
    <div class="notice" id="permissionSection">
      <div class="notice-ico">🔒</div>
      <p>Microphone access is needed to record your answer. Please enable it in your browser settings, then refresh this page.</p>
    </div>

    <div class="error-msg" id="errorMsg"></div>
  </div>

  <div class="foot"><span>Powered by VoiceJournal</span></div>

  <script>
    var LINK_TOKEN = '${linkToken}';
    var API_BASE = window.location.origin + '/v1';
    var mediaRecorder = null;
    var audioChunks = [];
    var audioBlob = null;
    var isRecording = false;
    var timerInterval = null;
    var startTime = 0;
    var duration = 0;
    var MAX_DURATION = 180;

    (function init() {
      var supported = !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
      if (!supported) {
        document.getElementById('recorderSection').style.display = 'none';
        document.getElementById('unsupportedSection').classList.add('visible');
        document.getElementById('safariLink').href = 'x-safari-' + window.location.href;
      }
      document.getElementById('recordBtn').addEventListener('click', toggleRecording);
      document.getElementById('recordBtn').addEventListener('touchend', function(e) {
        e.preventDefault();
        toggleRecording();
      });
      document.getElementById('reRecordBtn').addEventListener('click', reRecord);
      document.getElementById('submitBtn').addEventListener('click', submitRecording);
    })();

    function formatTime(s) {
      var m = Math.floor(s / 60);
      var sec = s % 60;
      return m + ':' + String(sec).padStart(2, '0');
    }

    async function toggleRecording() {
      if (isRecording) stopRecording();
      else await startRecording();
    }

    async function startRecording() {
      try {
        var stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        var types = ['audio/mp4','audio/webm;codecs=opus','audio/webm','audio/ogg;codecs=opus'];
        var mime = '';
        for (var i = 0; i < types.length; i++) {
          if (MediaRecorder.isTypeSupported(types[i])) { mime = types[i]; break; }
        }
        mediaRecorder = new MediaRecorder(stream, mime ? { mimeType: mime } : {});
        audioChunks = [];
        mediaRecorder.ondataavailable = function(e) { if (e.data.size > 0) audioChunks.push(e.data); };
        mediaRecorder.onstop = function() {
          stream.getTracks().forEach(function(t) { t.stop(); });
          audioBlob = new Blob(audioChunks, { type: mediaRecorder.mimeType || 'audio/mp4' });
          showReview();
        };
        mediaRecorder.start(1000);
        isRecording = true;
        startTime = Date.now();
        document.getElementById('recordBtn').classList.add('on');
        document.getElementById('hint').textContent = 'Tap to stop';
        document.getElementById('timer').classList.add('visible');
        timerInterval = setInterval(function() {
          duration = Math.floor((Date.now() - startTime) / 1000);
          document.getElementById('timer').textContent = formatTime(duration);
          if (duration >= MAX_DURATION) stopRecording();
        }, 250);
      } catch (err) {
        console.error('Mic error:', err);
        if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
          document.getElementById('recorderSection').style.display = 'none';
          document.getElementById('permissionSection').classList.add('visible');
        } else {
          showError('Could not access microphone: ' + (err.message || 'Unknown error'));
        }
      }
    }

    function stopRecording() {
      if (mediaRecorder && mediaRecorder.state !== 'inactive') mediaRecorder.stop();
      isRecording = false;
      clearInterval(timerInterval);
      document.getElementById('recordBtn').classList.remove('on');
    }

    function showReview() {
      document.getElementById('recorderSection').style.display = 'none';
      document.getElementById('reviewSection').classList.add('visible');
      var url = URL.createObjectURL(audioBlob);
      document.getElementById('audioPlayer').innerHTML = '<audio controls src="' + url + '" style="width:100%;height:44px;border-radius:12px;"></audio>';
    }

    function reRecord() {
      document.getElementById('reviewSection').classList.remove('visible');
      document.getElementById('recorderSection').style.display = 'flex';
      document.getElementById('timer').classList.remove('visible');
      document.getElementById('hint').textContent = 'Tap to start recording';
      document.getElementById('timer').textContent = '0:00';
      audioBlob = null;
      audioChunks = [];
      duration = 0;
      hideError();
    }

    async function submitRecording() {
      if (!audioBlob) return;
      document.getElementById('submitBtn').disabled = true;
      document.getElementById('reviewSection').classList.remove('visible');
      document.getElementById('uploadingSection').classList.add('visible');
      hideError();
      try {
        var fd = new FormData();
        var ext = audioBlob.type.includes('mp4') ? '.m4a' : audioBlob.type.includes('ogg') ? '.ogg' : '.webm';
        fd.append('audio', audioBlob, 'recording' + ext);
        fd.append('duration_seconds', String(duration));
        var resp = await fetch(API_BASE + '/record/' + LINK_TOKEN + '/upload', { method: 'POST', body: fd });
        if (!resp.ok) {
          var d = await resp.json().catch(function() { return {}; });
          throw new Error((d.error && d.error.message) || 'Upload failed');
        }
        document.getElementById('uploadingSection').classList.remove('visible');
        document.getElementById('successSection').classList.add('visible');
      } catch (err) {
        console.error('Upload error:', err);
        document.getElementById('uploadingSection').classList.remove('visible');
        document.getElementById('reviewSection').classList.add('visible');
        document.getElementById('submitBtn').disabled = false;
        showError(err.message || 'Upload failed. Please try again.');
      }
    }

    function showError(msg) {
      var el = document.getElementById('errorMsg');
      el.textContent = msg;
      el.classList.add('visible');
    }

    function hideError() {
      document.getElementById('errorMsg').classList.remove('visible');
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
  <title>VoiceJournal — Already Answered</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root { --flame: #FF6B35; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh;
      min-height: 100dvh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #fff;
      background: #1c0f2e;
      padding: 24px;
    }
    .bg {
      position: fixed;
      inset: 0;
      background:
        radial-gradient(ellipse 120% 80% at 50% 0%, #3d1d5e 0%, transparent 60%),
        radial-gradient(ellipse 100% 60% at 20% 40%, rgba(200,80,50,0.35) 0%, transparent 55%),
        radial-gradient(ellipse 120% 60% at 50% 100%, rgba(240,160,60,0.3) 0%, transparent 50%),
        linear-gradient(170deg, #2a1545 0%, #3e1f5a 25%, #6d3560 45%, #b55a48 65%, #d98a45 80%, #e8b050 100%);
    }
    .bg::after {
      content: '';
      position: fixed;
      inset: 0;
      opacity: 0.035;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
      background-size: 200px;
      pointer-events: none;
    }
    .content {
      position: relative;
      z-index: 1;
      text-align: center;
      animation: fadeUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) forwards;
      opacity: 0;
      transform: translateY(18px);
    }
    @keyframes fadeUp { to { opacity: 1; transform: translateY(0); } }
    .icon {
      width: 80px; height: 80px; border-radius: 50%;
      background: linear-gradient(145deg, rgba(74,222,128,0.2), rgba(34,197,94,0.08));
      border: 1.5px solid rgba(74,222,128,0.25);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 28px;
    }
    .icon svg { width: 36px; height: 36px; stroke: #4ade80; stroke-width: 2.5; fill: none; stroke-linecap: round; stroke-linejoin: round; }
    h1 { font-family: 'DM Serif Display', Georgia, serif; font-size: 28px; font-weight: 400; margin-bottom: 12px; }
    p { color: rgba(255,255,255,0.45); font-size: 15px; line-height: 1.6; max-width: 340px; }
    .foot { position: fixed; bottom: 24px; left: 0; right: 0; text-align: center; font-size: 11px; color: rgba(255,255,255,0.18); z-index: 1; }
  </style>
</head>
<body>
  <div class="bg"></div>
  <div class="content">
    <div class="icon"><svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7"/></svg></div>
    <h1>Already Answered</h1>
    <p>This question has already been answered. Thank you for sharing your story!</p>
  </div>
  <div class="foot">Powered by VoiceJournal</div>
</body>
</html>`;
}
