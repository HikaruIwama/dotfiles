import { spawnSync } from 'node:child_process';
import { readFileSync, realpathSync, existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

export function validateSkillLock(lock) {
  if (lock === null || typeof lock !== 'object' ||
      !Number.isInteger(lock.version) || lock.version < 3 ||
      lock.skills === null || typeof lock.skills !== 'object' || Array.isArray(lock.skills)) {
    throw new Error('Invalid global skills lockfile');
  }
  const agents = lock.lastSelectedAgents ?? ['universal'];
  if (!Array.isArray(agents) || agents.length === 0 ||
      agents.some((agent) => typeof agent !== 'string' || !/^[a-z][a-z0-9-]*$/.test(agent))) {
    throw new Error('Invalid lastSelectedAgents in global skills lockfile');
  }
  const entries = [];
  for (const [skill, entry] of Object.entries(lock.skills)) {
    if (typeof skill !== 'string' || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(skill)) {
      throw new Error(`Invalid skill name: ${skill}`);
    }
    if (entry === null || typeof entry !== 'object' ||
        typeof entry.sourceUrl !== 'string' || !entry.sourceUrl || entry.sourceUrl.startsWith('-')) {
      throw new Error(`Missing sourceUrl for ${skill}`);
    }
    if (entry.ref !== undefined && (typeof entry.ref !== 'string' || !entry.ref)) {
      throw new Error(`Invalid ref for ${skill}`);
    }
    entries.push([skill, entry]);
  }

  return { agents, entries };
}

export function installSkills(lock, run, shouldInstall = () => true) {
  const { agents, entries } = validateSkillLock(lock);
  const bySource = new Map();
  for (const [skill, entry] of entries) {
    if (!shouldInstall(skill, agents)) continue;
    const source = entry.ref ? `${entry.sourceUrl}#${entry.ref}` : entry.sourceUrl;
    const skills = bySource.get(source) ?? [];
    skills.push(skill);
    bySource.set(source, skills);
  }

  for (const [source, skills] of bySource) {
    const args = ['-y', 'skills', 'add', source];
    for (const skill of skills) args.push('--skill', skill);
    args.push('-g');
    for (const agent of agents) args.push('-a', agent);
    args.push('-y');
    if (run('npx', args) !== 0) {
      throw new Error(`Failed to install skills from ${source}`);
    }
  }
}

export function isSkillInstalled(skill, agents) {
  const shared = join(homedir(), '.agents', 'skills', skill);
  if (!existsSync(join(shared, 'SKILL.md'))) return false;
  if (!agents.includes('claude-code')) return true;
  const claude = join(homedir(), '.claude', 'skills', skill);
  try {
    return realpathSync(shared) === realpathSync(claude);
  } catch {
    return false;
  }
}

if (import.meta.main) {
  const [option, ...extra] = process.argv.slice(2);
  if (extra.length || (option && option !== '--missing-only')) {
    throw new Error('Usage: node scripts/install-external-skills.mjs [--missing-only]');
  }
  const lock = JSON.parse(readFileSync(new URL('../agents/.skill-lock.json', import.meta.url), 'utf8'));
  installSkills(lock, (command, args) => {
    const executable = process.platform === 'win32' ? process.execPath : command;
    const executableArgs = process.platform === 'win32'
      ? [join(dirname(process.execPath), 'node_modules', 'npm', 'bin', 'npx-cli.js'), ...args]
      : args;
    const result = spawnSync(executable, executableArgs, {
      stdio: 'inherit',
    });
    if (result.error) throw result.error;
    return result.status ?? 1;
  }, (skill, agents) => option !== '--missing-only' || !isSkillInstalled(skill, agents));
}
