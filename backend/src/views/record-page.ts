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
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VoiceJournal — Record Your Answer</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      color: #fff;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 24px 16px;
    }

    .container {
      max-width: 480px;
      width: 100%;
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    .logo {
      text-align: center;
      margin-bottom: 32px;
      opacity: 0.7;
      font-size: 14px;
      letter-spacing: 1px;
      text-transform: uppercase;
    }

    .greeting {
      text-align: center;
      margin-bottom: 8px;
      font-size: 16px;
      color: rgba(255,255,255,0.7);
    }

    .requester {
      text-align: center;
      margin-bottom: 32px;
      font-size: 14px;
      color: rgba(255,255,255,0.5);
    }

    .question-card {
      background: rgba(255,255,255,0.08);
      border: 1px solid rgba(255,255,255,0.12);
      border-radius: 16px;
      padding: 24px;
      margin-bottom: 32px;
      backdrop-filter: blur(10px);
    }

    .question-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: rgba(255,255,255,0.5);
      margin-bottom: 12px;
    }

    .question-text {
      font-size: 22px;
      font-weight: 600;
      line-height: 1.4;
      color: #fff;
    }

    .recorder {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 24px;
    }

    .timer {
      font-size: 48px;
      font-weight: 300;
      font-variant-numeric: tabular-nums;
      color: rgba(255,255,255,0.9);
      display: none;
    }

    .timer.visible { display: block; }

    .record-btn {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      border: 3px solid #FF6B35;
      background: transparent;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s ease;
      position: relative;
    }

    .record-btn:hover { transform: scale(1.05); }

    .record-btn .inner {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: #FF6B35;
      transition: all 0.2s ease;
    }

    .record-btn.recording .inner {
      width: 28px;
      height: 28px;
      border-radius: 6px;
      background: #ff4444;
    }

    .record-btn.recording {
      border-color: #ff4444;
      animation: pulse 1.5s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% { box-shadow: 0 0 0 0 rgba(255, 68, 68, 0.4); }
      50% { box-shadow: 0 0 0 12px rgba(255, 68, 68, 0); }
    }

    .hint {
      font-size: 14px;
      color: rgba(255,255,255,0.5);
      text-align: center;
    }

    /* Review state */
    .review { display: none; flex-direction: column; align-items: center; gap: 20px; }
    .review.visible { display: flex; }

    .review-actions {
      display: flex;
      gap: 16px;
      width: 100%;
      max-width: 320px;
    }

    .btn {
      flex: 1;
      padding: 14px 24px;
      border-radius: 12px;
      border: none;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .btn:hover { transform: translateY(-1px); }
    .btn:active { transform: translateY(0); }

    .btn-secondary {
      background: rgba(255,255,255,0.1);
      color: #fff;
      border: 1px solid rgba(255,255,255,0.2);
    }

    .btn-primary {
      background: #FF6B35;
      color: #fff;
    }

    .btn-primary:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .audio-player {
      width: 100%;
      max-width: 320px;
    }

    .audio-player audio {
      width: 100%;
      border-radius: 8px;
    }

    /* Upload state */
    .uploading {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 16px;
    }

    .uploading.visible { display: flex; }

    .spinner {
      width: 40px;
      height: 40px;
      border: 3px solid rgba(255,255,255,0.2);
      border-top-color: #FF6B35;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin { to { transform: rotate(360deg); } }

    /* Success state */
    .success {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      text-align: center;
    }

    .success.visible { display: flex; }

    .success-icon {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: rgba(34, 197, 94, 0.2);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 32px;
    }

    .success h2 {
      font-size: 24px;
      font-weight: 600;
    }

    .success p {
      color: rgba(255,255,255,0.6);
      font-size: 16px;
    }

    /* Error state */
    .error-msg {
      display: none;
      color: #ff6b6b;
      font-size: 14px;
      text-align: center;
      padding: 12px;
      background: rgba(255, 107, 107, 0.1);
      border-radius: 8px;
      margin-top: 12px;
    }

    .error-msg.visible { display: block; }

    /* Permission denied */
    .permission-denied {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      text-align: center;
      padding: 24px;
    }

    .permission-denied.visible { display: flex; }

    .permission-denied p {
      color: rgba(255,255,255,0.7);
      font-size: 16px;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">VoiceJournal</div>

    <div class="greeting">Hi ${personName},</div>
    <div class="requester">${requesterName} asked you a question</div>

    <div class="question-card">
      <div class="question-label">Question</div>
      <div class="question-text">${questionText}</div>
    </div>

    <!-- Record state -->
    <div class="recorder" id="recorderSection">
      <div class="timer" id="timer">0:00</div>
      <button class="record-btn" id="recordBtn" onclick="toggleRecording()">
        <div class="inner"></div>
      </button>
      <div class="hint" id="hint">Tap to start recording</div>
    </div>

    <!-- Review state -->
    <div class="review" id="reviewSection">
      <div class="audio-player" id="audioPlayer"></div>
      <div class="review-actions">
        <button class="btn btn-secondary" onclick="reRecord()">Re-record</button>
        <button class="btn btn-primary" id="submitBtn" onclick="submitRecording()">Submit</button>
      </div>
    </div>

    <!-- Uploading state -->
    <div class="uploading" id="uploadingSection">
      <div class="spinner"></div>
      <div>Uploading your recording...</div>
    </div>

    <!-- Success state -->
    <div class="success" id="successSection">
      <div class="success-icon">✓</div>
      <h2>Thank you!</h2>
      <p>Your recording has been saved. ${requesterName} will be notified.</p>
    </div>

    <!-- Permission denied -->
    <div class="permission-denied" id="permissionSection">
      <div style="font-size: 48px;">🎤</div>
      <p>Microphone access is required to record your answer. Please allow microphone access in your browser settings and refresh the page.</p>
    </div>

    <!-- Error message -->
    <div class="error-msg" id="errorMsg"></div>
  </div>

  <script>
    const LINK_TOKEN = '${linkToken}';
    const API_BASE = window.location.origin + '/v1';

    let mediaRecorder = null;
    let audioChunks = [];
    let audioBlob = null;
    let isRecording = false;
    let timerInterval = null;
    let startTime = 0;
    let duration = 0;
    const MAX_DURATION = 180; // 3 minutes

    function formatTime(seconds) {
      const m = Math.floor(seconds / 60);
      const s = seconds % 60;
      return m + ':' + String(s).padStart(2, '0');
    }

    async function toggleRecording() {
      if (isRecording) {
        stopRecording();
      } else {
        await startRecording();
      }
    }

    async function startRecording() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

        // Determine best supported format
        const mimeTypes = [
          'audio/webm;codecs=opus',
          'audio/webm',
          'audio/mp4',
          'audio/ogg;codecs=opus',
        ];
        let mimeType = '';
        for (const type of mimeTypes) {
          if (MediaRecorder.isTypeSupported(type)) {
            mimeType = type;
            break;
          }
        }

        mediaRecorder = new MediaRecorder(stream, mimeType ? { mimeType } : {});
        audioChunks = [];

        mediaRecorder.ondataavailable = (e) => {
          if (e.data.size > 0) audioChunks.push(e.data);
        };

        mediaRecorder.onstop = () => {
          stream.getTracks().forEach(t => t.stop());
          const type = mediaRecorder.mimeType || 'audio/webm';
          audioBlob = new Blob(audioChunks, { type });
          showReview();
        };

        mediaRecorder.start(1000); // Collect data every second
        isRecording = true;
        startTime = Date.now();

        document.getElementById('recordBtn').classList.add('recording');
        document.getElementById('hint').textContent = 'Tap to stop';
        document.getElementById('timer').classList.add('visible');

        timerInterval = setInterval(() => {
          duration = Math.floor((Date.now() - startTime) / 1000);
          document.getElementById('timer').textContent = formatTime(duration);

          if (duration >= MAX_DURATION) {
            stopRecording();
          }
        }, 250);

      } catch (err) {
        console.error('Mic error:', err);
        if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
          document.getElementById('recorderSection').style.display = 'none';
          document.getElementById('permissionSection').classList.add('visible');
        } else {
          showError('Could not access microphone. Please try a different browser.');
        }
      }
    }

    function stopRecording() {
      if (mediaRecorder && mediaRecorder.state !== 'inactive') {
        mediaRecorder.stop();
      }
      isRecording = false;
      clearInterval(timerInterval);
      document.getElementById('recordBtn').classList.remove('recording');
    }

    function showReview() {
      document.getElementById('recorderSection').style.display = 'none';
      document.getElementById('reviewSection').classList.add('visible');

      const audioUrl = URL.createObjectURL(audioBlob);
      const playerDiv = document.getElementById('audioPlayer');
      playerDiv.innerHTML = '<audio controls src="' + audioUrl + '"></audio>';
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
        const formData = new FormData();
        const ext = audioBlob.type.includes('mp4') ? '.m4a'
                  : audioBlob.type.includes('ogg') ? '.ogg'
                  : '.webm';
        formData.append('audio', audioBlob, 'recording' + ext);
        formData.append('duration_seconds', String(duration));

        const resp = await fetch(API_BASE + '/record/' + LINK_TOKEN + '/upload', {
          method: 'POST',
          body: formData,
        });

        if (!resp.ok) {
          const data = await resp.json().catch(() => ({}));
          throw new Error(data.error?.message || 'Upload failed');
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
      const el = document.getElementById('errorMsg');
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
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      color: #fff;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px 16px;
      text-align: center;
    }
    .icon { font-size: 64px; margin-bottom: 24px; }
    h1 { font-size: 24px; margin-bottom: 12px; }
    p { color: rgba(255,255,255,0.6); font-size: 16px; line-height: 1.5; max-width: 400px; }
  </style>
</head>
<body>
  <div class="icon">✅</div>
  <h1>Already Answered</h1>
  <p>This question has already been answered. Thank you for your response!</p>
</body>
</html>`;
}
