
// State
const state = {
    currentMode: null, // 'challenge', 'fear', 'passive'
    targetInterval: 300, // seconds (5m)
    attemptCount: 1, // for challenge/fear
    repetitionCount: 1, // for passive

    // Session State
    currentAttemptIndex: 0, // 0-based
    attempts: [], // Array of { start, tap, error, etc. }
    passiveRunning: false,
    passiveTimerId: null,
    passiveStartTime: null,

    // Settings
    healthKitEnabled: true,
    soundEnabled: true
};

// DOM Elements
const screens = {
    home: document.getElementById('screen-home'),
    picker: document.getElementById('screen-picker'),
    config: document.getElementById('screen-config'),
    session: document.getElementById('screen-session'),
    progress: document.getElementById('screen-progress'),
    settings: document.getElementById('screen-settings')
};

// Picker Elements
const pickerMin = document.getElementById('picker-min');
const pickerSec = document.getElementById('picker-sec');

// Session Elements
const sessionChallengeContainer = document.getElementById('session-challenge-container');
const sessionPassiveContainer = document.getElementById('session-passive-container');
const challengeTargetDisplay = document.getElementById('challenge-target-display');
const challengeReady = document.getElementById('challenge-ready');
const challengeRunning = document.getElementById('challenge-running');
const challengeFeedback = document.getElementById('challenge-feedback');
const challengeSummary = document.getElementById('challenge-summary');
const challengeAttemptLabel = document.getElementById('challenge-attempt-label');
const feedbackMain = document.getElementById('feedback-main');
const feedbackSub = document.getElementById('feedback-sub');
const summaryMeanError = document.getElementById('summary-mean-error');
const summaryScore = document.getElementById('summary-score');
const summaryDoneBtn = document.getElementById('summary-done');

const passiveStatus = document.querySelector('.passive-status');
const passiveTimer = document.getElementById('passive-timer');
const passiveStopBtn = document.getElementById('passive-stop');

// Init
function init() {
    setupMenu();
    setupPicker();
    setupConfig();
    setupSessionInteractions();
}

// Navigation
function showScreen(screenName) {
    Object.values(screens).forEach(s => {
        s.classList.add('hidden');
        s.classList.remove('active');
    });
    screens[screenName].classList.remove('hidden');
    screens[screenName].classList.add('active');
}

// Helper: Format Time
function formatTime(seconds) {
    if (seconds < 60) {
        return `${seconds}s`;
    }
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}m ${s}s`;
}

function formatTimeLong(seconds) {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

// Menu
function setupMenu() {
    const buttons = document.querySelectorAll('.menu-item');
    buttons.forEach(btn => {
        btn.addEventListener('click', () => {
            const mode = btn.dataset.mode;
            if (['challenge', 'fear', 'passive'].includes(mode)) {
                state.currentMode = mode;
                showScreen('picker');

                // Restore last used or default to 5m 0s
                const currentM = Math.floor(state.targetInterval / 60);
                const currentS = state.targetInterval % 60;

                // Need to wait for display to unhide before scrolling works reliably in some browsers,
                // but in this simple environment it might be fine.
                setTimeout(() => {
                     scrollToValue(pickerMin, currentM);
                     scrollToValue(pickerSec, currentS);
                }, 10);

            } else if (mode === 'progress') {
                showScreen('progress');
            } else if (mode === 'settings') {
                showScreen('settings');
                setupSettings();
            }
        });
    });
}

// Picker Logic
function setupPicker() {
    // Clear existing
    pickerMin.innerHTML = '';
    pickerSec.innerHTML = '';

    pickerMin.innerHTML = '<div class="picker-item" style="height:50px;"></div>'; // Spacer
    for (let i = 0; i <= 120; i++) {
        const div = document.createElement('div');
        div.className = 'picker-item';
        div.textContent = i;
        div.dataset.val = i;
        pickerMin.appendChild(div);
    }
    pickerMin.innerHTML += '<div class="picker-item" style="height:50px;"></div>'; // Spacer

    pickerSec.innerHTML = '<div class="picker-item" style="height:50px;"></div>'; // Spacer
    for (let i = 0; i < 60; i++) {
        const div = document.createElement('div');
        div.className = 'picker-item';
        div.textContent = i;
        div.dataset.val = i;
        pickerSec.appendChild(div);
    }
    pickerSec.innerHTML += '<div class="picker-item" style="height:50px;"></div>'; // Spacer

    // Scroll listener
    pickerMin.addEventListener('scroll', () => highlightSelection(pickerMin));
    pickerSec.addEventListener('scroll', () => highlightSelection(pickerSec));

    // Initial scroll
    setTimeout(() => {
        pickerMin.scrollTop = 5 * 50;
        pickerSec.scrollTop = 0;
    }, 10);

    // Confirm button
    document.getElementById('picker-confirm').addEventListener('click', () => {
        const m = getSelectedValue(pickerMin);
        const s = getSelectedValue(pickerSec);
        state.targetInterval = (m * 60) + s;

        // Validate minimum interval (10s)
        if (state.targetInterval < 10) {
            alert("Minimum interval is 10 seconds");
            return;
        }

        // Go to config screen
        updateConfigUI();
        showScreen('config');
    });
}

function scrollToValue(container, value) {
    container.scrollTop = value * 50;
}

function getSelectedValue(container) {
    const itemHeight = 50;
    const index = Math.round(container.scrollTop / itemHeight);
    const items = container.querySelectorAll('.picker-item:not([style*="height:50px"])'); // exclude spacers
    if (items[index]) {
        return parseInt(items[index].dataset.val);
    }
    return 0;
}

function highlightSelection(container) {
    const itemHeight = 50;
    const index = Math.round(container.scrollTop / itemHeight);
    const items = container.querySelectorAll('.picker-item');

    items.forEach(item => item.classList.remove('selected'));
    const selectedIndex = index + 1;
    if (items[selectedIndex]) {
        items[selectedIndex].classList.add('selected');
    }
}


// Config Screen
function setupConfig() {
    const minus = document.getElementById('config-minus');
    const plus = document.getElementById('config-plus');
    const start = document.getElementById('config-start');

    minus.addEventListener('click', () => {
        if (state.currentMode === 'passive') {
             // Repetitions
             if (state.repetitionCount > 1) state.repetitionCount--;
        } else {
            // Attempts
            if (state.attemptCount > 1) state.attemptCount--;
        }
        updateConfigUI();
    });

    plus.addEventListener('click', () => {
        if (state.currentMode === 'passive') {
             state.repetitionCount++;
        } else {
            state.attemptCount++;
        }
        updateConfigUI();
    });

    start.addEventListener('click', () => {
        startSession();
    });
}

function updateConfigUI() {
    const title = document.getElementById('config-title');
    const value = document.getElementById('config-value');
    const label = document.getElementById('config-label');

    if (state.currentMode === 'passive') {
        title.textContent = 'Repetitions';
        value.textContent = state.repetitionCount;
        label.textContent = state.repetitionCount === 1 ? 'Repetition' : 'Repetitions';
    } else {
        // Challenge or Fear
        title.textContent = 'Attempts';
        value.textContent = state.attemptCount;
        label.textContent = state.attemptCount === 1 ? 'Attempt' : 'Attempts';
    }
}

// Settings Logic
function setupSettings() {
    const toggleHK = document.getElementById('toggle-healthkit');
    const toggleSound = document.getElementById('toggle-sound');

    // Init state
    if (state.healthKitEnabled) toggleHK.classList.add('active'); else toggleHK.classList.remove('active');
    if (state.soundEnabled) toggleSound.classList.add('active'); else toggleSound.classList.remove('active');

    toggleHK.onclick = () => {
        state.healthKitEnabled = !state.healthKitEnabled;
        toggleHK.classList.toggle('active');
        console.log(`HealthKit Enabled: ${state.healthKitEnabled}`);
    };

    toggleSound.onclick = () => {
        state.soundEnabled = !state.soundEnabled;
        toggleSound.classList.toggle('active');
        console.log(`Sound Enabled: ${state.soundEnabled}`);
    };
}

// --- Session Logic ---

function startSession() {
    showScreen('session');

    if (state.currentMode === 'passive') {
        startPassiveSession();
    } else {
        startChallengeSession(); // Handles both Challenge and Fear
    }
}

// Challenge / Fear Mode
function startChallengeSession() {
    sessionChallengeContainer.classList.remove('hidden');
    sessionPassiveContainer.classList.add('hidden');

    // Init State
    state.currentAttemptIndex = 0;
    state.attempts = [];

    // Show Ready Screen
    challengeTargetDisplay.textContent = formatTime(state.targetInterval);

    showChallengeState('ready');
}

function showChallengeState(s) {
    // Hide all
    challengeReady.classList.add('hidden');
    challengeRunning.classList.add('hidden');
    challengeFeedback.classList.add('hidden');
    challengeSummary.classList.add('hidden');

    if (s === 'ready') challengeReady.classList.remove('hidden');
    if (s === 'running') challengeRunning.classList.remove('hidden');
    if (s === 'feedback') challengeFeedback.classList.remove('hidden');
    if (s === 'summary') challengeSummary.classList.remove('hidden');
}

function setupSessionInteractions() {
    // Ready -> Start First Attempt
    challengeReady.addEventListener('click', () => {
        startAttempt();
    });

    // Running -> Tap (End Attempt)
    challengeRunning.addEventListener('click', () => {
        handleTap();
    });

    // Summary -> Done (Back to Home)
    summaryDoneBtn.addEventListener('click', () => {
        showScreen('home');
    });

    // Passive Stop
    passiveStopBtn.addEventListener('click', () => {
        endPassiveSession();
        showScreen('home');
    });
}

function startAttempt() {
    const attemptNum = state.currentAttemptIndex + 1;
    challengeAttemptLabel.textContent = `Attempt ${attemptNum} / ${state.attemptCount}`;

    showChallengeState('running');

    // Record Start Time
    state.currentAttemptStart = Date.now();
}

function handleTap() {
    const tapTime = Date.now();
    const elapsedMs = tapTime - state.currentAttemptStart;
    const elapsedSec = elapsedMs / 1000;

    const target = state.targetInterval;
    const signedError = elapsedSec - target;
    const absError = Math.abs(signedError);
    const percentError = signedError / target;

    // Store Attempt Data
    state.attempts.push({
        start: state.currentAttemptStart,
        tap: tapTime,
        elapsed: elapsedSec,
        signedError: signedError,
        absError: absError,
        percentError: percentError
    });

    showFeedback(signedError, absError, percentError);
}

function showFeedback(signedError, absError, percentError) {
    const isLate = signedError > 0;
    feedbackMain.textContent = isLate ? "Late" : "Early";
    feedbackSub.textContent = `by ${formatTime(Math.round(absError))}`;

    // Color Logic based on error zones
    // Green < 5%, Yellow < 15%, Red >= 15%
    const absPercent = Math.abs(percentError);
    let color = '#34c759'; // Green
    if (absPercent >= 0.15) color = '#ff3b30'; // Red
    else if (absPercent >= 0.05) color = '#ffcc00'; // Yellow

    feedbackMain.style.color = color;

    showChallengeState('feedback');

    // Fear Mode Check
    if (state.currentMode === 'fear' && absPercent >= 0.10) {
        playFearSound();
    }

    // Auto advance after 2 seconds
    setTimeout(() => {
        state.currentAttemptIndex++;
        if (state.currentAttemptIndex < state.attemptCount) {
            startAttempt();
        } else {
            calculateAndShowSummary();
        }
    }, 2000);
}

function playFearSound() {
    if (!state.soundEnabled) return;
    // Simple beep or buzzer simulation
    // In a real browser, we might use AudioContext.
    console.log("BZZZZT! Fear Mode Penalty!");
    // Visual feedback for demo? Flash screen red
    const originalBg = document.body.style.backgroundColor;
    document.getElementById('watch-screen').style.backgroundColor = 'red';
    setTimeout(() => {
        document.getElementById('watch-screen').style.backgroundColor = 'black';
    }, 500);
}

function calculateAndShowSummary() {
    // Calculate Metrics
    const totalAbsError = state.attempts.reduce((sum, a) => sum + a.absError, 0);
    const meanAbsError = totalAbsError / state.attempts.length;

    const totalAbsPercent = state.attempts.reduce((sum, a) => sum + Math.abs(a.percentError), 0);
    const meanAbsPercent = totalAbsPercent / state.attempts.length;

    // Acuity Score
    // E_full_scale = 0.50
    // acuity_raw = 1 - (E / 0.50)
    // acuity_clamped = max(0, min(1, acuity_raw))
    // Score = round(100 * acuity_clamped)

    const acuityRaw = 1 - (meanAbsPercent / 0.50);
    const acuityClamped = Math.max(0, Math.min(1, acuityRaw));
    const score = Math.round(100 * acuityClamped);

    // Update UI
    summaryMeanError.textContent = formatTime(Math.round(meanAbsError));
    summaryScore.textContent = score;

    // Log to "HealthKit"
    if (state.healthKitEnabled) {
        console.log("Logging to HealthKit (Mindful Session):", {
            mode: state.currentMode,
            interval: state.targetInterval,
            attempts: state.attempts.length,
            meanAbsError: meanAbsError,
            score: score
        });
    }

    showChallengeState('summary');
}

// Passive Mode
function startPassiveSession() {
    sessionChallengeContainer.classList.add('hidden');
    sessionPassiveContainer.classList.remove('hidden');

    state.passiveRunning = true;
    state.passiveStartTime = Date.now();
    updatePassiveTimer();

    state.passiveRepetitionsDone = 0;

    // Start Interval Loop
    schedulePassiveHaptic();
}

function updatePassiveTimer() {
    if (!state.passiveRunning) return;

    const now = Date.now();
    const elapsed = Math.floor((now - state.passiveStartTime) / 1000);
    passiveTimer.textContent = formatTimeLong(elapsed);

    requestAnimationFrame(updatePassiveTimer);
}

function schedulePassiveHaptic() {
    if (!state.passiveRunning) return;

    // In a real app, this would schedule local notifications or run in background.
    // Here we just use setTimeout for the next boundary.
    // We need to track how many intervals have passed.

    // Simple simulation: just set timeout for targetInterval

    state.passiveTimerId = setTimeout(() => {
        triggerHaptic();
        state.passiveRepetitionsDone++;
        if (state.passiveRepetitionsDone >= state.repetitionCount) {
            endPassiveSession();
            alert("Passive Session Complete");
            showScreen('home');
        } else {
            schedulePassiveHaptic(); // recurse
        }
    }, state.targetInterval * 1000);
}

function triggerHaptic() {
    console.log("HAPTIC FEEDBACK - Interval Reached");
    // Visual Pulse
    const screen = document.getElementById('watch-screen');
    screen.style.backgroundColor = '#333';
    setTimeout(() => {
        screen.style.backgroundColor = 'black';
    }, 200);
}

function endPassiveSession() {
    state.passiveRunning = false;
    if (state.passiveTimerId) clearTimeout(state.passiveTimerId);

    // Log to HealthKit
    if (state.healthKitEnabled) {
        const duration = Math.floor((Date.now() - state.passiveStartTime) / 1000);
        console.log("Logging to HealthKit (Passive):", {
            mode: 'passive',
            interval: state.targetInterval,
            repetitionCount: state.repetitionCount, // Note: this was the plan, but actual duration might differ if stopped early
            duration: duration
        });
    }
}

// Run
init();
