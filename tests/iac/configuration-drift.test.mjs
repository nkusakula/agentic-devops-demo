import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const root = new URL('../..', import.meta.url);

async function read(path) {
  return readFile(new URL(path, root), 'utf8');
}

test('health endpoint settings are declared and monitored as backend baseline', async () => {
  const [terraform, azureYaml, chaosScript, driftPolicy] = await Promise.all([
    read('infra/terraform/main.tf'),
    read('azure.yaml'),
    read('sre/scripts/chaos-engineering.sh'),
    read('sre/sre-config/tasks/config-drift.yaml'),
  ]);

  for (const content of [terraform, azureYaml]) {
    assert.match(content, /MANAGEMENT_ENDPOINT_HEALTH_ENABLED[\s\S]*?true/);
    assert.match(content, /MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE[\s\S]*?health,info/);
  }

  assert.match(chaosScript, /HEALTH_ENDPOINT_ENABLED_BASELINE="true"/);
  assert.match(chaosScript, /HEALTH_ENDPOINTS_WEB_EXPOSURE_INCLUDE_BASELINE="health,info"/);
  assert.match(driftPolicy, /Report any non-secret backend environment variable not declared/);
});
