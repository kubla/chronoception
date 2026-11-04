import { calibration, decodeTrainingHistory, startTraining, pulseTraining, trainingRecord, createSession, decodeHistory, duration, feedback, intervalLabel, record, recover, transition, upsert } from './core.mjs?v=b01957e13daf';





const screen = document.querySelector                ('#screen') ;
const deviceFrame = document.querySelector                ('#device') ;
const title = document.querySelector                 ('#app-title') ;
const storageMessage = document.querySelector                ('#storage-message') ;
const key = (device        ) => 'chronoception.preview.v1.' + device;
let device         = new URLSearchParams(location.search).get('device') === 'watch' ? 'watch' : 'phone';

function load(device        )          {
  const preview          = { mode: 'test', training: null, trainingRecords: [], trainingStorageBlocked: false, plan: { intervalSeconds: 300, attemptCount: 1 }, session: null, records: [], page: 'practice', storageBlocked: false, storageMessage: '' };
  try {
    const raw = localStorage.getItem(key(device));
    preview.records = raw === null ? [] : recover(decodeHistory(raw));
    if (preview.records.length) localStorage.setItem(key(device), JSON.stringify(preview.records));
  } catch {
    preview.storageBlocked = true;
    preview.storageMessage = 'Saved history could not be opened. It has been preserved. This preview will keep new results only until you close it.';
  }
  try {
    const raw = localStorage.getItem(key(device) + '.training');
    preview.trainingRecords = raw === null ? [] : decodeTrainingHistory(raw).map(item => item.status === 'active' ? { ...item, status: 'interrupted' } : item);
    if (preview.trainingRecords.length) localStorage.setItem(key(device) + '.training', JSON.stringify(preview.trainingRecords));
  } catch {
    preview.trainingStorageBlocked = true;
    preview.storageMessage = 'Training history could not be opened. It has been preserved.';
  }
  return preview;
}

const previews = { phone: load('phone'), watch: load('watch') };
const current = () => previews[device];
const label = intervalLabel;
const button = (action        , text        , style = 'primary') => `<button class="${style}" data-action="${action}">${text}</button>`;

function persist(preview         )       {
  if (preview.session) preview.records = upsert(preview.records, record(preview.session));
  if (preview.storageBlocked) return;
  try {
    localStorage.setItem(key(device), JSON.stringify(preview.records));
    preview.storageMessage = '';
  } catch {
    preview.storageMessage = 'This result could not be saved in your browser. It remains available in this tab.';
  }
}

function persistTraining(preview         , kind        )       {
  if (preview.training) {
    const item = trainingRecord(preview.training);
    preview.trainingRecords = [item, ...preview.trainingRecords.filter(previous => previous.id !== item.id)];
  }
  if (preview.trainingStorageBlocked) return;
  try { localStorage.setItem(key(kind) + '.training', JSON.stringify(preview.trainingRecords)); }
  catch { preview.storageMessage = 'Training could not be saved. It remains available in this tab.'; }
}

function interruptTraining(preview         , kind        )       {
  if (preview.training?.phase !== 'training') return;
  preview.training = { ...preview.training, phase: 'interrupted' };
  persistTraining(preview, kind);
}

function send(event       )       {
  const preview = current();
  if (preview.session === null) return;
  preview.session = transition(preview.session, event);
  persist(preview);
  render(true);
}

function configuration(preview         )         {
  return `<div class="configuration">
    <div class="segments modes" role="group" aria-label="Practice mode">${(['test', 'train']         ).map(mode => `<button data-mode="${mode}" aria-pressed="${preview.mode === mode}">${mode === 'test' ? 'Test yourself' : 'Train yourself'}</button>`).join('')}</div>
    <div class="phone-intro"><h2>Feel the interval.</h2><p class="secondary">${preview.mode === 'train' ? 'Learn the duration with a cue at every interval.' : 'Choose a duration. Mark it when it feels complete.'}</p></div>
    <button class="interval-card" data-action="interval" aria-label="Interval, ${label(preview.plan.intervalSeconds)}"><span class="eyebrow phone-only">INTERVAL</span><span>${label(preview.plan.intervalSeconds)} <span class="chevron" aria-hidden="true">⌄</span></span></button>
    <fieldset class="attempts"><legend>${preview.mode === 'train' ? 'Repetitions' : 'Attempts'}</legend><div class="segments">${[1, 3, 5].map(count => `<button data-count="${count}" aria-pressed="${count === preview.plan.attemptCount}" aria-label="${count} ${preview.mode === 'train' ? 'repetitions' : count === 1 ? 'attempt' : 'attempts'}">${count}</button>`).join('')}</div></fieldset>
    ${button('begin', 'Begin')}<p class="quiet phone-only">A practice in noticing time.</p></div>`;
}

function practice(preview         )         {
  const training = preview.training;
  if (training) {
    const active = training.phase === 'training';
    const headings = { training: 'Feel each interval.', completed: 'Training complete', cancelled: 'Training ended', interrupted: 'Training interrupted' };
    return `<div class="training"><h2>${headings[training.phase]}</h2><h3>${label(training.plan.intervalSeconds)}</h3><p class="cue-count" role="status">${training.completedIntervals} of ${training.plan.attemptCount} cues</p><p class="secondary">${active ? 'A visual cue marks each interval. Keep this tab visible.' : 'Cued intervals saved separately from estimates.'}</p>${training.phase === 'interrupted' ? '<p class="quiet">Training stopped when this tab was hidden or a cue was delayed.</p>' : ''}${active ? button('end-training', 'End training', 'text-button') : button('reset-training', 'Practice again')}${!active ? button('history', 'View history', 'text-button') : ''}</div>`;
  }
  const session = preview.session;
  if (session === null || session.phase === 'ready') return configuration(preview);
  if (session.phase === 'estimating') return `<div class="estimation"><div class="attempt-heading"><h2>${label(session.plan.intervalSeconds)}</h2><p class="secondary">Attempt ${session.attempts.length + 1} of ${session.plan.attemptCount}</p></div>${button('estimate', 'Now', 'mark-estimate')}<p class="secondary phone-only">Tap when the interval feels complete.</p>${button('cancel', 'End session', 'text-button')}</div>`;
  if (session.phase === 'feedback') return `<div class="feedback"><h2>${feedback(session.attempt)}</h2><dl class="measurements"><div><dt>Your estimate</dt><dd>${duration(session.attempt.elapsedSeconds)}</dd></div><div><dt>Interval</dt><dd>${label(session.plan.intervalSeconds)}</dd></div></dl>${button('advance', session.attempts.length === session.plan.attemptCount ? 'Finish' : 'Next attempt')}${session.attempts.length < session.plan.attemptCount ? button('cancel', 'End session', 'text-button') : ''}</div>`;
  const headings = { completed: 'Session complete', cancelled: 'Session ended', interrupted: 'Timing interrupted' };
  const count = session.attempts.length;
  return `<div class="finished"><div class="finish-mark phone-only" aria-hidden="true">◌</div><h2>${headings[session.phase]}</h2><p class="secondary">${count === 0 ? 'No estimates were recorded.' : `${count} ${preview.mode === 'train' ? 'repetitions' : count === 1 ? 'attempt' : 'attempts'} in your history.`}</p>${session.phase === 'interrupted' ? '<p class="quiet">Leaving this tab interrupted the session. Completed attempts are retained.</p>' : ''}${button('reset', 'Practice again')}${button('history', 'View history', 'text-button')}</div>`;
}

function history(preview         )         {
  const attempts = preview.records.flatMap(item => item.attempts);
  const mean = attempts.reduce((sum, item) => sum + Math.abs(item.elapsedSeconds - item.intervalSeconds) / item.intervalSeconds, 0) / attempts.length;
  return `<div class="history-page">${button('close', 'Done', 'sheet-done')}<h2>History</h2>${preview.records.length === 0 ? '<div class="empty"><span aria-hidden="true">◌</span><h3>No attempts yet</h3><p class="secondary">Your observations will appear here.</p></div>' : `<h3>${attempts.length} recorded ${attempts.length === 1 ? 'attempt' : 'attempts'}</h3>${attempts.length ? `<p>Mean absolute error: ${(mean * 100).toFixed(1)}%</p><p class="quiet">Completed attempts are retained when a session ends early.</p>` : ''}<div class="records">${preview.records.map(item => `<article class="record"><div class="record-heading"><h3>${label(item.plan.intervalSeconds)}</h3><span>${item.status[0].toUpperCase() + item.status.slice(1)}</span></div><time class="quiet">${new Date(item.startedAt).toLocaleString([], { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}</time>${item.attempts.length ? item.attempts.map((attempt, index) => `<div class="record-attempt"><span>Attempt ${index + 1}</span><span>${feedback(attempt)}</span></div>`).join('') : '<p class="secondary">No estimate recorded.</p>'}</article>`).join('')}</div>`}${calibration(preview.records).map(item => `<article class="calibration"><h3>${label(item.intervalSeconds)} calibration</h3><p>Latest ${item.recentCount}: ${item.recentError.toFixed(1)}% error</p><p class="quiet">${item.previousError === null ? 'Keep practicing to compare with earlier estimates.' : `Previous ${item.previousCount}: ${item.previousError.toFixed(1)}% error`}</p></article>`).join('')}
    ${preview.trainingRecords.length ? `<h3>Training</h3>${preview.trainingRecords.map(item => `<article class="record"><h3>Training · ${label(item.plan.intervalSeconds)}</h3><p>${item.completedIntervals} of ${item.plan.attemptCount} cued intervals</p><p>${item.status[0].toUpperCase() + item.status.slice(1)}</p><time class="quiet">${new Date(item.startedAt).toLocaleString()}</time></article>`).join('')}` : ''}<p class="quiet">${device === 'phone' ? 'iPhone' : 'Watch'} preview history · stored in this browser.</p></div>`;
}

function intervals()         {
  return `<div class="interval-page">${button('close', 'Done', 'sheet-done')}<h2>Interval</h2><div class="presets">${[30, 60, 180, 300, 600].map(seconds => `<button data-interval="${seconds}" aria-label="Choose ${label(seconds)}">${label(seconds)}</button>`).join('')}</div><form id="custom-interval"><h3>Custom interval</h3><div class="custom-fields"><label>Minutes<input name="minutes" type="number" min="0" max="120" step="1" value="0" inputmode="numeric" required></label><label>Seconds<input name="seconds" type="number" min="0" max="59" step="1" value="10" inputmode="numeric" required></label></div><p id="interval-error" class="quiet" role="status"></p><button class="primary" type="submit">Use interval</button></form></div>`;
}

function about()         {
  return `<div class="about-page">${button('close', 'Done', 'sheet-done')}<h2>About Chronoception</h2><p>Train with repeating interval cues, then test your sense of time without a countdown. Review calibration separately for each interval.</p><h3>Your practice, stored locally.</h3><p>This browser preview keeps observations on this browser, with separate phone and Watch histories. There is no account, server, advertising or analytics.</p><h3>A preview of the native apps.</h3><p>Leaving the tab interrupts a session. Browser timing does not establish device sleep or background behavior. Training uses visual cues in this preview, not haptics.</p><a href="privacy.html" target="_blank" rel="noopener">Native app privacy policy ↗</a><a href="https://github.com/kubla/chronoception/issues" target="_blank" rel="noopener">Support ↗</a></div>`;
}

function render(focus = false)       {
  const preview = current();
  deviceFrame.className = 'device ' + device;
  document.querySelectorAll                   ('[data-device]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.device === device)));
  document.querySelector('#device-caption') .textContent = (device === 'phone' ? 'iPhone' : 'Apple Watch') + ' · browser preview · no haptics';
  title.textContent = device === 'phone' ? 'Chronoception' : 'Practice';
  storageMessage.textContent = preview.storageMessage;
  storageMessage.hidden = preview.storageMessage === '';
  screen.innerHTML = preview.page === 'practice' ? practice(preview) : preview.page === 'history' ? history(preview) : preview.page === 'interval' ? intervals() : about();
  screen.scrollTop = 0;
  if (focus) screen.focus({ preventScroll: true });
}

function navigate(page      )       {
  if (page !== 'practice') interruptTraining(current(), device);
  current().page = page;
  render(true);
}

document.querySelector('#about') .addEventListener('click', () => navigate('about'));
document.querySelector('#history') .addEventListener('click', () => navigate('history'));
document.querySelectorAll                   ('[data-device]').forEach(button => button.addEventListener('click', () => {
  interruptTraining(current(), device);
  device = button.dataset.device          ;
  const url = new URL(location.href);
  url.searchParams.set('device', device);
  window.history.replaceState(null, '', url);
  render();
}));

screen.addEventListener('click', event => {
  const target = (event.target           ).closest                   ('button');
  if (target === null) return;
  const preview = current();
  if (target.dataset.mode) { preview.mode = target.dataset.mode                    ; render(); }
  if (target.dataset.count) {
    preview.plan.attemptCount = Number(target.dataset.count);
    render();
    screen.querySelector                   (`[data-count="${preview.plan.attemptCount}"]`) .focus();
  }
  if (target.dataset.interval) {
    preview.plan.intervalSeconds = Number(target.dataset.interval);
    navigate('practice');
  }
  const action = target.dataset.action;
  if (action === 'begin') {
    if (preview.mode === 'train') {
      preview.training = startTraining(preview.plan, crypto.randomUUID(), new Date().toISOString(), performance.now());
      persistTraining(preview, device);
      render(true);
    } else {
      preview.session = createSession(preview.plan, crypto.randomUUID(), new Date().toISOString());
      send({ type: 'start', atMilliseconds: performance.now() });
    }
  } else if (action === 'estimate' || action === 'advance') send({ type: action, atMilliseconds: performance.now() });
  else if (action === 'cancel') send({ type: 'cancel' });
  else if (action === 'end-training' && preview.training?.phase === 'training') {
    preview.training = { ...preview.training, phase: 'cancelled' };
    persistTraining(preview, device);
    render(true);
  }
  else if (action === 'reset-training') { preview.training = null; navigate('practice'); }
  else if (action === 'reset') { preview.session = null; navigate('practice'); }
  else if (action === 'close') navigate('practice');
  else if (action === 'interval' || action === 'history') navigate(action);
});

screen.addEventListener('submit', event => {
  event.preventDefault();
  const form = event.target                   ;
  const data = new FormData(form);
  const seconds = Number(data.get('minutes')) * 60 + Number(data.get('seconds'));
  if (seconds <= 0) { screen.querySelector('#interval-error') .textContent = 'Choose an interval longer than zero.'; return; }
  current().plan.intervalSeconds = seconds;
  navigate('practice');
});

document.addEventListener('visibilitychange', () => {
  if (!document.hidden) return;
  const selected = device;
  for (const kind of ['phone', 'watch']         ) {
    device = kind;
    const preview = current();
    interruptTraining(preview, kind);
    if (preview.session?.phase === 'estimating' || preview.session?.phase === 'feedback') {
      preview.session = transition(preview.session, { type: 'interrupt' });
      persist(preview);
    }
  }
  device = selected;
  render();
});

setInterval(() => {
  for (const kind of ['phone', 'watch']         ) {
    const preview = previews[kind];
    if (preview.training?.phase !== 'training') continue;
    if (document.hidden || kind !== device || preview.page !== 'practice') {
      interruptTraining(preview, kind);
      continue;
    }
    const before = preview.training;
    preview.training = pulseTraining(before, performance.now());
    if (preview.training === before) continue;
    persistTraining(preview, kind);
    if (kind === device && preview.page === 'practice') {
      render();
      screen.querySelector('.cue-count')?.animate([{ opacity: 0.2 }, { opacity: 1 }], { duration: matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 450 });
    }
  }
}, 40);
render();
