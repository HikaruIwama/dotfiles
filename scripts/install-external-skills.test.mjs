import assert from 'node:assert/strict';
import test from 'node:test';
import { installSkills } from './install-external-skills.mjs';

test('restores each source for agents selected in the lockfile', () => {
  const calls = [];
  installSkills(
    {
      version: 3,
      lastSelectedAgents: ['codex', 'opencode', 'claude-code'],
      skills: {
        'find-skills': { sourceUrl: 'https://github.com/vercel-labs/skills.git' },
        alpha: { sourceUrl: 'https://github.com/example/kit.git' },
        beta: { sourceUrl: 'https://github.com/example/kit.git' },
      },
    },
    (command, args) => {
      calls.push([command, args]);
      return 0;
    },
  );

  assert.deepEqual(calls, [
    ['npx', ['-y', 'skills', 'add', 'https://github.com/vercel-labs/skills.git', '--skill', 'find-skills', '-g', '-a', 'codex', '-a', 'opencode', '-a', 'claude-code', '-y']],
    ['npx', ['-y', 'skills', 'add', 'https://github.com/example/kit.git', '--skill', 'alpha', '--skill', 'beta', '-g', '-a', 'codex', '-a', 'opencode', '-a', 'claude-code', '-y']],
  ]);
});

test('stops when an installation fails', () => {
  let calls = 0;
  assert.throws(
    () => installSkills(
      { version: 3, skills: {
        alpha: { sourceUrl: 'https://github.com/example/one.git' },
        beta: { sourceUrl: 'https://github.com/example/two.git' },
      } },
      () => {
        calls++;
        return 1;
      },
    ),
    /example\/one/,
  );
  assert.equal(calls, 1);
});

test('rejects invalid entries before installing anything', () => {
  let calls = 0;
  const run = () => {
    calls++;
    return 0;
  };
  assert.throws(
    () => installSkills({ version: 3, skills: {
      alpha: { sourceUrl: 'https://github.com/example/valid.git' },
      beta: { sourceUrl: '' },
    } }, run),
    /beta/,
  );
  assert.throws(
    () => installSkills({ version: 3, skills: {
      alpha: { sourceUrl: 'https://github.com/example/valid.git' },
      'bad;skill': { sourceUrl: 'https://github.com/example/other.git' },
    } }, run),
    /bad;skill/,
  );
  assert.equal(calls, 0);
});

test('rejects invalid selected agents before installing anything', () => {
  let calls = 0;
  assert.throws(
    () => installSkills({ version: 3, lastSelectedAgents: ['codex', '--copy'], skills: {
      alpha: { sourceUrl: 'https://github.com/example/kit.git' },
    } }, () => { calls++; return 0; }),
    /lastSelectedAgents/,
  );
  assert.equal(calls, 0);
});

test('keeps a recorded source ref when restoring', () => {
  const calls = [];
  installSkills(
    { version: 3, skills: {
      alpha: { sourceUrl: 'https://github.com/example/kit.git', ref: 'v1.2.3' },
    } },
    (command, args) => {
      calls.push([command, args]);
      return 0;
    },
  );
  assert.equal(calls[0][1][3], 'https://github.com/example/kit.git#v1.2.3');
});

test('installs only missing skills when requested', () => {
  const calls = [];
  installSkills(
    { version: 3, lastSelectedAgents: ['codex', 'claude-code'], skills: {
      alpha: { sourceUrl: 'https://github.com/example/kit.git' },
      beta: { sourceUrl: 'https://github.com/example/kit.git' },
    } },
    (command, args) => {
      calls.push([command, args]);
      return 0;
    },
    (skill) => skill === 'beta',
  );
  assert.deepEqual(calls, [
    ['npx', ['-y', 'skills', 'add', 'https://github.com/example/kit.git', '--skill', 'beta', '-g', '-a', 'codex', '-a', 'claude-code', '-y']],
  ]);
});

test('does nothing when every skill is already installed', () => {
  let calls = 0;
  installSkills(
    { version: 3, skills: {
      alpha: { sourceUrl: 'https://github.com/example/kit.git' },
    } },
    () => { calls++; return 0; },
    () => false,
  );
  assert.equal(calls, 0);
});
