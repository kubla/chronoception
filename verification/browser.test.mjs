import test from 'node:test';
import assert from 'node:assert/strict';
import { createSession, decodeHistory, duration, feedback, intervalLabel, record, recover, transition, upsert } from '../docs/preview/core.mjs';

const fresh = (attemptCount = 1) => createSession({ intervalSeconds: 300, attemptCount }, 'session-1', '2026-11-03T12:00:00Z');
const started = (count = 1) => transition(fresh(count), { type: 'start', atMilliseconds: 1000 });
const estimate = (session, seconds) => transition(session, { type: 'estimate', atMilliseconds: 1000 + seconds * 1000 });

test('early, exact and late feedback agree with native fixtures', () => {
  assert.equal(feedback(estimate(started(), 270).attempt), '30s early');
  assert.equal(feedback(estimate(started(), 300).attempt), 'On time');
  assert.equal(feedback(estimate(started(), 330).attempt), '30s late');
  assert.equal(feedback({ elapsedSeconds: 299.99, intervalSeconds: 300 }), '<0.1s early');
});
test('a duplicate estimate cannot create a second attempt', () => {
  const first = estimate(started(), 270);
  assert.equal(estimate(first, 271), first);
  assert.equal(first.attempts.length, 1);
});
test('completion requires an explicit advance', () => {
  const first = estimate(started(), 300);
  assert.equal(first.phase, 'feedback');
  assert.equal(transition(first, { type: 'advance', atMilliseconds: 302000 }).phase, 'completed');
});
test('three attempts require three estimates and advances', () => {
  let session = started(3);
  for (let index = 0; index < 3; index++) {
    session = transition(session, { type: 'estimate', atMilliseconds: 301000 + index * 300000 });
    assert.equal(session.attempts.length, index + 1);
    session = transition(session, { type: 'advance', atMilliseconds: 301000 + index * 300000 });
    assert.equal(session.phase, index === 2 ? 'completed' : 'estimating');
  }
});
test('cancel retains real attempts and terminal states ignore later input', () => {
  const cancelled = transition(estimate(started(3), 270), { type: 'cancel' });
  assert.equal(cancelled.attempts.length, 1);
  assert.equal(cancelled.phase, 'cancelled');
  assert.equal(estimate(cancelled, 300), cancelled);
  assert.equal(transition(cancelled, { type: 'advance', atMilliseconds: 400000 }), cancelled);
  assert.equal(transition(cancelled, { type: 'interrupt' }), cancelled);
});
test('cancelling before an estimate manufactures no observations', () => {
  assert.equal(transition(started(), { type: 'cancel' }).attempts.length, 0);
});
test('a backwards or invalid tick interrupts without a result', () => {
  for (const atMilliseconds of [0, NaN, Infinity]) {
    const session = transition(started(), { type: 'estimate', atMilliseconds });
    assert.equal(session.phase, 'interrupted');
    assert.equal(session.attempts.length, 0);
  }
});
test('upsert replaces a session rather than duplicating its history', () => {
  const history = upsert([record(started())], record(estimate(started(), 270)));
  assert.equal(history.length, 1);
  assert.equal(history[0].attempts.length, 1);
});
test('relaunch recovers active sessions as interrupted and preserves attempts', () => {
  const decoded = decodeHistory(JSON.stringify([record(estimate(started(), 270))]));
  const recovered = recover(decoded);
  assert.equal(recovered[0].status, 'interrupted');
  assert.equal(recovered[0].attempts.length, 1);
  assert.deepEqual(recover(recovered), recovered);
});
test('corrupt history and invalid domain values are rejected', () => {
  for (const raw of ['not json', '{}', '[{}]', JSON.stringify([{ ...record(started()), attempts: [{ intervalSeconds: 300, elapsedSeconds: -1 }] }])]) assert.throws(() => decodeHistory(raw));
  for (const intervalSeconds of [0, -1, NaN, 1.5]) assert.throws(() => createSession({ intervalSeconds, attemptCount: 1 }, 'id', 'date'));
});
test('formatting retains the native literal durations', () => {
  assert.equal(duration(0), '0s');
  assert.equal(duration(0.01), '<0.1s');
  assert.equal(duration(5.5), '5.5s');
  assert.equal(duration(65), '1m 5s');
  assert.equal(duration(300), '5 min');
});
test('interval labels agree with native integer-second labels', () => {
  assert.equal(intervalLabel(1), '1s');
  assert.equal(intervalLabel(30), '30s');
  assert.equal(intervalLabel(65), '1m 5s');
  assert.equal(intervalLabel(300), '5 min');
});

const trainingCore = await import('../docs/preview/core.mjs');
const training = () => trainingCore.startTraining({ intervalSeconds: 1, attemptCount: 3 }, 'training', '2026-11-04T12:00:00Z', 1000);
test('training repeats at fixed boundaries and finishes without generating estimates', () => {
  let value = training();
  assert.equal(trainingCore.pulseTraining(value, 1999), value);
  value = trainingCore.pulseTraining(value, 2100);
  assert.equal(value.completedIntervals, 1);
  assert.equal(value.nextCueMilliseconds, 3000);
  assert.equal(trainingCore.pulseTraining(value, 2100), value);
  value = trainingCore.pulseTraining(value, 3000);
  value = trainingCore.pulseTraining(value, 4000);
  assert.equal(value.phase, 'completed');
  assert.equal(value.completedIntervals, 3);
  assert.equal(trainingCore.pulseTraining(value, 5000), value);
  assert.equal(trainingCore.trainingRecord(value).status, 'completed');
  assert.equal('attempts' in trainingCore.trainingRecord(value), false);
});
test('late training interrupts without catching up fake cues', () => {
  const value = trainingCore.pulseTraining(training(), 4000);
  assert.equal(value.phase, 'interrupted');
  assert.equal(value.completedIntervals, 0);
});
test('cancelled and interrupted training ignore future pulses', () => {
  const first = trainingCore.pulseTraining(training(), 2000);
  for (const phase of ['cancelled', 'interrupted']) {
    const value = { ...first, phase };
    assert.equal(trainingCore.pulseTraining(value, 3000), value);
    assert.equal(value.completedIntervals, 1);
  }
});
test('training history round-trips independently and rejects invalid cue counts', () => {
  const record = trainingCore.trainingRecord(training());
  assert.deepEqual(trainingCore.decodeTrainingHistory(JSON.stringify([record])), [record]);
  for (const completedIntervals of [-1, 4, 0.5]) assert.throws(() => trainingCore.decodeTrainingHistory(JSON.stringify([{ ...record, completedIntervals }])));
});
test('calibration compares recent and previous samples within one interval', () => {
  const attempts = Array.from({ length: 10 }, (_, i) => ({ intervalSeconds: 10, elapsedSeconds: i + 1 }));
  const value = trainingCore.calibration([{ ...record(started()), plan: { intervalSeconds: 10, attemptCount: 10 }, attempts }]);
  assert.equal(value[0].recentError, 20);
  assert.equal(value[0].previousError, 70);
});
