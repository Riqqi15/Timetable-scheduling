import assert from 'node:assert/strict';
import test from 'node:test';
import { resolveScheduleDirection } from '../src/domain/services/scheduleDirection';

const stops = [
  { sequence: 1, stationName: 'Matraman' },
  { sequence: 2, stationName: 'Manggarai' },
  { sequence: 3, stationName: 'Cikini' },
  { sequence: 4, stationName: 'Jakarta Kota' },
];

test('schedule direction uses the next stop and final destination', () => {
  assert.deepEqual(resolveScheduleDirection(2, stops), {
    nextStation: 'Cikini',
    destination: 'Jakarta Kota',
  });
});

test('schedule direction excludes a terminal stop', () => {
  assert.equal(resolveScheduleDirection(4, stops), null);
});

