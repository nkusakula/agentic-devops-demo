import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const terraform = readFileSync(new URL('../../infra/terraform/main.tf', import.meta.url), 'utf8');
const azd = readFileSync(new URL('../../azure.yaml', import.meta.url), 'utf8');
const driftTask = readFileSync(
  new URL('../../sre/sre-config/tasks/config-drift.yaml', import.meta.url),
  'utf8',
);

const settings = [
  ['MANAGEMENT_ENDPOINT_HEALTH_ENABLED', 'true'],
  ['MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE', 'health,info'],
];

test('management endpoint settings are declared in Terraform and azd', () => {
  for (const [name, value] of settings) {
    assert.match(terraform, new RegExp(`name\\s*=\\s*"${name}"[\\s\\S]*?value\\s*=\\s*"${value}"`));
    assert.match(azd, new RegExp(`${name}:\\s*"${value}"`));
    assert.match(driftTask, new RegExp(`${name} should be: ${value}`));
  }
});
