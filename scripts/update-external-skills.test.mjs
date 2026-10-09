import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { updateExternalSkills } from './update-external-skills.mjs';

test('seeds local state, restores missing skills, and checks for updates without changing the source lock', () => {
  const dir = mkdtempSync(join(tmpdir(), 'dotfiles-skills-'));
  try {
    const lock = {
      version: 3,
      lastSelectedAgents: ['codex'],
      skills: { alpha: {
        sourceUrl: 'https://github.com/example/skills.git',
        skillPath: 'skills/alpha/SKILL.md',
        skillFolderHash: 'old-hash',
      } },
    };
    const original = structuredClone(lock);
    const calls = [];
    const run = (command, args, env) => {
      calls.push({ command, args, stateHome: env.XDG_STATE_HOME });
      return 0;
    };

    updateExternalSkills(lock, dir, run, () => false);

    assert.deepEqual(lock, original);
    assert.deepEqual(JSON.parse(readFileSync(join(dir, 'skills', '.skill-lock.json'), 'utf8')), lock);
    assert.deepEqual(calls, [
      { command: 'npx', args: ['-y', 'skills', 'add', 'https://github.com/example/skills.git', '--skill', 'alpha', '-g', '-a', 'codex', '-y'], stateHome: dir },
      { command: 'npx', args: ['-y', 'skills', 'update', '-g', '-y'], stateHome: dir },
    ]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('keeps the locally updated hash and moved skill path across bootstrap runs', () => {
  const dir = mkdtempSync(join(tmpdir(), 'dotfiles-skills-'));
  try {
    const lock = { version: 3, skills: { alpha: {
      sourceUrl: 'https://github.com/example/skills.git',
      skillPath: 'skills/alpha/SKILL.md',
      skillFolderHash: 'repo-hash',
    } } };
    const localLock = structuredClone(lock);
    localLock.skills.alpha.skillFolderHash = 'updated-hash';
    localLock.skills.alpha.skillPath = 'new/location/SKILL.md';
    const statePath = join(dir, 'skills', '.skill-lock.json');
    mkdirSync(join(dir, 'skills'));
    writeFileSync(statePath, JSON.stringify(localLock));
    const calls = [];

    updateExternalSkills(lock, dir, (_command, args) => { calls.push(args); return 0; }, () => true);

    assert.deepEqual(calls, [['-y', 'skills', 'update', '-g', '-y']]);
    assert.deepEqual(JSON.parse(readFileSync(statePath, 'utf8')), localLock);
    assert.equal(lock.skills.alpha.skillFolderHash, 'repo-hash');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('reinstalls a skill when its recorded source changes', () => {
  const dir = mkdtempSync(join(tmpdir(), 'dotfiles-skills-'));
  try {
    const oldSource = 'https://github.com/example/old.git';
    const newSource = 'https://github.com/example/new.git';
    const lock = { version: 3, skills: { alpha: { sourceUrl: newSource, skillPath: 'SKILL.md', skillFolderHash: 'new-hash' } } };
    const localLock = { version: 3, skills: { alpha: { sourceUrl: oldSource, skillPath: 'SKILL.md', skillFolderHash: 'old-hash' } } };
    const statePath = join(dir, 'skills', '.skill-lock.json');
    mkdirSync(join(dir, 'skills'));
    writeFileSync(statePath, JSON.stringify(localLock));
    const calls = [];

    assert.throws(() => updateExternalSkills(lock, dir, (_command, args) => {
      calls.push(args);
      return 1;
    }, () => true), /new\.git/);
    assert.equal(calls.length, 1);
    assert.equal(calls[0][3], newSource);
    assert.deepEqual(JSON.parse(readFileSync(statePath, 'utf8')), localLock);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
