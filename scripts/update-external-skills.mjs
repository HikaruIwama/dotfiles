import { spawnSync } from 'node:child_process';
import { isDeepStrictEqual } from 'node:util';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';
import { installSkills, isSkillInstalled, validateSkillLock } from './install-external-skills.mjs';

export function updateExternalSkills(lock, stateHome, run, isInstalled = isSkillInstalled) {
  validateSkillLock(lock);
  const statePath = join(stateHome, 'skills', '.skill-lock.json');
  const localLock = existsSync(statePath) ? JSON.parse(readFileSync(statePath, 'utf8')) : null;
  if (localLock) validateSkillLock(localLock);
  const changedSources = new Set();
  const skills = {};
  for (const [skill, entry] of Object.entries(lock.skills)) {
    const installedEntry = localLock?.skills[skill];
    if (!installedEntry) {
      skills[skill] = entry;
    } else if (installedEntry.sourceUrl !== entry.sourceUrl ||
               installedEntry.ref !== entry.ref ||
               installedEntry.sourceType !== entry.sourceType) {
      skills[skill] = installedEntry;
      changedSources.add(skill);
    } else {
      skills[skill] = installedEntry;
    }
  }
  const nextLock = { ...lock, skills };
  if (!localLock || !isDeepStrictEqual(localLock, nextLock)) {
    mkdirSync(join(stateHome, 'skills'), { recursive: true });
    writeFileSync(statePath, JSON.stringify(nextLock, null, 2));
  }
  const env = { ...process.env, XDG_STATE_HOME: stateHome };
  installSkills(lock, (command, args) => run(command, args, env),
    (skill, agents) => changedSources.has(skill) || !isInstalled(skill, agents));
  if (run('npx', ['-y', 'skills', 'update', '-g', '-y'], env) !== 0) {
    throw new Error('Failed to update external skills');
  }
}

if (import.meta.main) {
  const lock = JSON.parse(readFileSync(new URL('../agents/.skill-lock.json', import.meta.url), 'utf8'));
  const stateHome = join(process.env.XDG_STATE_HOME || join(homedir(), '.local', 'state'), 'dotfiles');
  updateExternalSkills(lock, stateHome, (command, args, env) => {
    const executable = process.platform === 'win32' ? process.execPath : command;
    const executableArgs = process.platform === 'win32'
      ? [join(dirname(process.execPath), 'node_modules', 'npm', 'bin', 'npx-cli.js'), ...args]
      : args;
    const result = spawnSync(executable, executableArgs, { stdio: 'inherit', env });
    if (result.error) throw result.error;
    return result.status ?? 1;
  });
}
