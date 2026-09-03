// Regression test for configuration drift between the declared IaC (Terraform +
// azure.yaml) and the runtime environment variables used by the chaos
// engineering scripts. See: https://github.com/nkusakula/agentic-devops-demo/issues/16
//
// Run with: node --test tests/iac/configuration-drift.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

const mainTf = readFileSync(path.join(repoRoot, 'infra', 'terraform', 'main.tf'), 'utf8');
const azureYaml = readFileSync(path.join(repoRoot, 'azure.yaml'), 'utf8');
const chaosScript = readFileSync(path.join(repoRoot, 'sre', 'scripts', 'chaos-engineering.sh'), 'utf8');

const MANAGED_BACKEND_ENV_VARS = {
  MANAGEMENT_ENDPOINT_HEALTH_ENABLED: 'true',
  MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE: 'health,info',
};

for (const [name, value] of Object.entries(MANAGED_BACKEND_ENV_VARS)) {
  test(`Terraform declares ${name} matching the chaos rollback value`, () => {
    const envBlockPattern = new RegExp(
      `env\\s*{[^}]*name\\s*=\\s*"${name}"[^}]*value\\s*=\\s*"${value}"[^}]*}`,
      's'
    );
    assert.match(
      mainTf,
      envBlockPattern,
      `infra/terraform/main.tf must declare an env block for ${name} = "${value}"`
    );
  });

  test(`azure.yaml declares ${name} matching the chaos rollback value`, () => {
    const yamlPattern = new RegExp(`^\\s*${name}:\\s*"${value}"`, 'm');
    assert.match(
      azureYaml,
      yamlPattern,
      `azure.yaml must declare ${name}: "${value}" for the backend service`
    );
  });

  test(`chaos-engineering.sh health-check-disabled rollback restores ${name}=${value}`, () => {
    assert.match(
      chaosScript,
      new RegExp(`${name}=${value}`),
      `sre/scripts/chaos-engineering.sh rollback must restore ${name}=${value} so it matches declared IaC`
    );
  });
}
