













export function createSession(plan      , id        , startedAt        )          {
  if (!Number.isInteger(plan.intervalSeconds) || plan.intervalSeconds <= 0 ||
      !Number.isInteger(plan.attemptCount) || plan.attemptCount <= 0) throw new RangeError('Positive interval and attempt count required');
  return { id, startedAt, plan: { ...plan }, attempts: [], phase: 'ready' };
}

export function transition(session         , event       )          {
  if (event.type === 'cancel' && ['ready', 'estimating', 'feedback'].includes(session.phase)) return { ...session, phase: 'cancelled' };
  if (event.type === 'interrupt' && ['estimating', 'feedback'].includes(session.phase)) return { ...session, phase: 'interrupted' };
  if (session.phase === 'ready' && event.type === 'start') return { ...session, phase: 'estimating', startMilliseconds: event.atMilliseconds };
  if (session.phase === 'estimating' && event.type === 'estimate') {
    const elapsedSeconds = (event.atMilliseconds - session.startMilliseconds) / 1000;
    if (!Number.isFinite(elapsedSeconds) || elapsedSeconds < 0) return { ...session, phase: 'interrupted' };
    const attempt = { elapsedSeconds, intervalSeconds: session.plan.intervalSeconds };
    return { ...session, phase: 'feedback', attempt, attempts: [...session.attempts, attempt] };
  }
  if (session.phase === 'feedback' && event.type === 'advance') {
    return session.attempts.length === session.plan.attemptCount
      ? { ...session, phase: 'completed' }
      : { ...session, phase: 'estimating', startMilliseconds: event.atMilliseconds };
  }
  return session;
}

export function duration(seconds        )         {
  if (seconds === 0) return '0s';
  if (seconds < 0.1) return '<0.1s';
  if (seconds < 10) return seconds.toFixed(1) + 's';
  const rounded = Math.round(seconds);
  if (rounded < 60) return rounded + 's';
  const minutes = Math.floor(rounded / 60), remainder = rounded % 60;
  return remainder === 0 ? minutes + ' min' : minutes + 'm ' + remainder + 's';
}

export function intervalLabel(seconds        )         {
  const minutes = Math.floor(seconds / 60), remainder = seconds % 60;
  if (minutes === 0) return remainder + 's';
  return remainder === 0 ? minutes + ' min' : minutes + 'm ' + remainder + 's';
}

export function feedback(attempt         )         {
  const error = attempt.elapsedSeconds - attempt.intervalSeconds;
  return error === 0 ? 'On time' : duration(Math.abs(error)) + (error < 0 ? ' early' : ' late');
}

export function record(session         )         {
  const { id, startedAt, plan, attempts, phase } = session;
  const status = phase === 'completed' || phase === 'cancelled' || phase === 'interrupted' ? phase : 'active';
  return { id, startedAt, plan, attempts, status };
}

export function upsert(records          , item        )           {
  return [item, ...records.filter(previous => previous.id !== item.id)];
}

export function recover(records          )           {
  return records.map(item => item.status === 'active' ? { ...item, status: 'interrupted' } : item);
}

export function decodeHistory(raw        )           {
  const value          = JSON.parse(raw);
  const positiveInteger = (number         )                   => typeof number === 'number' && Number.isInteger(number) && number > 0;
  function isAttempt(value         )                   {
    return typeof value === 'object' && value !== null && 'elapsedSeconds' in value && 'intervalSeconds' in value &&
      typeof value.elapsedSeconds === 'number' && Number.isFinite(value.elapsedSeconds) && value.elapsedSeconds >= 0 && positiveInteger(value.intervalSeconds);
  }
  function isRecord(value         )                  {
    if (typeof value !== 'object' || value === null) return false;
    return 'id' in value && typeof value.id === 'string' && 'startedAt' in value && typeof value.startedAt === 'string' &&
      Number.isFinite(Date.parse(value.startedAt)) && 'status' in value && typeof value.status === 'string' &&
      ['active', 'completed', 'cancelled', 'interrupted'].includes(value.status) &&
      'plan' in value && typeof value.plan === 'object' && value.plan !== null &&
      'intervalSeconds' in value.plan && positiveInteger(value.plan.intervalSeconds) && 'attemptCount' in value.plan && positiveInteger(value.plan.attemptCount) &&
      'attempts' in value && Array.isArray(value.attempts) && value.attempts.every(isAttempt) && value.attempts.length <= value.plan.attemptCount;
  }
  if (!Array.isArray(value) || !value.every(isRecord)) throw new TypeError('Unreadable practice history');
  return value;
}






export function startTraining(plan      , id        , startedAt        , atMilliseconds        )           {
  const session = createSession(plan, id, startedAt);
  return { id, startedAt, plan: session.plan, completedIntervals: 0, phase: 'training', nextCueMilliseconds: atMilliseconds + plan.intervalSeconds * 1000 };
}

export function pulseTraining(training          , atMilliseconds        )           {
  if (training.phase !== 'training' || atMilliseconds < training.nextCueMilliseconds) return training;
  if (atMilliseconds - training.nextCueMilliseconds > 500) return { ...training, phase: 'interrupted' };
  const completedIntervals = training.completedIntervals + 1;
  return completedIntervals === training.plan.attemptCount
    ? { ...training, completedIntervals, phase: 'completed' }
    : { ...training, completedIntervals, nextCueMilliseconds: training.nextCueMilliseconds + training.plan.intervalSeconds * 1000 };
}

export function trainingRecord(training          )                 {
  return { id: training.id, startedAt: training.startedAt, plan: training.plan, completedIntervals: training.completedIntervals, status: training.phase === 'training' ? 'active' : training.phase };
}

export function decodeTrainingHistory(raw        )                   {
  const value          = JSON.parse(raw);
  if (!Array.isArray(value)) throw new TypeError('Unreadable training history');
  for (const item of value) {
    decodeHistory(JSON.stringify([{ ...item, attempts: [] }]));
    if (!Number.isInteger(item.completedIntervals) || item.completedIntervals < 0 || item.completedIntervals > item.plan.attemptCount) throw new TypeError('Invalid cue count');
  }
  return value;
}

export function calibration(records          )                                                                                                                               {
  const attempts = [...records].sort((a, b) => Date.parse(b.startedAt) - Date.parse(a.startedAt)).flatMap(item => [...item.attempts].reverse());
  const mean = (items           ) => items.reduce((sum, item) => sum + Math.abs(item.elapsedSeconds - item.intervalSeconds) / item.intervalSeconds * 100, 0) / items.length;
  return [...new Set(attempts.map(item => item.intervalSeconds))].sort((a, b) => a - b).map(intervalSeconds => {
    const matching = attempts.filter(item => item.intervalSeconds === intervalSeconds);
    const recent = matching.slice(0, 5), previous = matching.slice(5, 10);
    return { intervalSeconds, recentCount: recent.length, recentError: mean(recent), previousCount: previous.length, previousError: previous.length ? mean(previous) : null };
  });
}
