/**
 * Property 1: External ARN inputs have no corresponding resource blocks
 *
 * For any variable in any module whose name ends with `_arn` and whose description
 * references an external resource, there should be no unconditional `resource` block
 * in the same module that creates that resource type. Conditional resources gated by
 * a `create_*` variable (count = 0 by default) are acceptable.
 *
 * **Validates: Requirements 1.1, 1.2**
 *
 * Feature: iac-blueprint-analysis, Property 1: External ARN inputs have no corresponding resource blocks
 */

import { describe, it, expect } from 'vitest';
import * as fc from 'fast-check';
import { readdirSync, readFileSync, statSync } from 'fs';
import { join, resolve, relative } from 'path';

const ROOT_DIR = resolve(__dirname, '..');
const MODULES_DIR = join(ROOT_DIR, 'modules');

/**
 * Map of ARN variable name patterns to the AWS resource type they reference.
 * These are known external dependency ARN inputs per the design doc.
 */
const EXTERNAL_ARN_MAPPINGS: { variablePattern: RegExp; resourceType: string; description: string; requirement: string }[] = [
  {
    variablePattern: /^ssl_certificate_arn$/,
    resourceType: 'aws_acm_certificate',
    description: 'SSL certificate (ACM)',
    requirement: '1.1',
  },
  {
    variablePattern: /^trusted_ip_set_arn$/,
    resourceType: 'aws_wafv2_ip_set',
    description: 'WAF trusted IP set',
    requirement: '1.2',
  },
];

interface ModuleInfo {
  name: string;
  dir: string;
  tfFiles: { filePath: string; relativePath: string }[];
}

/**
 * Discover all modules and their .tf files.
 */
function discoverModules(): ModuleInfo[] {
  const modules: ModuleInfo[] = [];
  for (const entry of readdirSync(MODULES_DIR)) {
    const moduleDir = join(MODULES_DIR, entry);
    if (!statSync(moduleDir).isDirectory() || entry === '.terraform') continue;

    const tfFiles: { filePath: string; relativePath: string }[] = [];
    function walkDir(dir: string) {
      for (const f of readdirSync(dir)) {
        if (f === '.terraform' || f === 'node_modules') continue;
        const fullPath = join(dir, f);
        if (statSync(fullPath).isDirectory()) {
          walkDir(fullPath);
        } else if (f.endsWith('.tf')) {
          tfFiles.push({ filePath: fullPath, relativePath: relative(ROOT_DIR, fullPath) });
        }
      }
    }
    walkDir(moduleDir);
    modules.push({ name: entry, dir: moduleDir, tfFiles });
  }
  return modules;
}

/**
 * Check if a module has a variable matching the given pattern.
 */
function moduleHasVariable(mod: ModuleInfo, pattern: RegExp): boolean {
  for (const tf of mod.tfFiles) {
    const content = readFileSync(tf.filePath, 'utf-8');
    const varRegex = /variable\s+"([^"]+)"/g;
    let match;
    while ((match = varRegex.exec(content)) !== null) {
      if (pattern.test(match[1])) return true;
    }
  }
  return false;
}

/**
 * Find unconditional resource blocks of a given type in a module.
 * A resource is "unconditional" if it has no `count` argument.
 */
function findUnconditionalResources(mod: ModuleInfo, resourceType: string): string[] {
  const violations: string[] = [];
  for (const tf of mod.tfFiles) {
    const content = readFileSync(tf.filePath, 'utf-8');
    // Match resource blocks of the given type
    const resourceRegex = new RegExp(
      `resource\\s+"${resourceType.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}"\\s+"([^"]+)"\\s*\\{([^}]*(?:\\{[^}]*\\}[^}]*)*)\\}`,
      'gs'
    );
    let match;
    while ((match = resourceRegex.exec(content)) !== null) {
      const resourceName = match[1];
      const resourceBody = match[2];
      // Check if the resource has a count argument (conditional creation)
      if (!/\bcount\s*=/.test(resourceBody)) {
        violations.push(`${tf.relativePath}: resource "${resourceType}" "${resourceName}" is unconditional`);
      }
    }
  }
  return violations;
}

describe('Property 1: External ARN inputs have no corresponding resource blocks', () => {
  const modules = discoverModules();

  it('discovers modules', () => {
    expect(modules.length).toBeGreaterThan(0);
  });

  it('external ARN inputs have no unconditional corresponding resource blocks in the same module', () => {
    fc.assert(
      fc.property(
        fc.constantFrom(...modules),
        fc.constantFrom(...EXTERNAL_ARN_MAPPINGS),
        (mod, mapping) => {
          // Only check modules that actually have this ARN variable
          if (!moduleHasVariable(mod, mapping.variablePattern)) return;

          const violations = findUnconditionalResources(mod, mapping.resourceType);
          if (violations.length > 0) {
            throw new Error(
              `Module "${mod.name}" has variable matching "${mapping.variablePattern}" ` +
              `(${mapping.description}, Requirement ${mapping.requirement}) but also has ` +
              `unconditional resource blocks of type "${mapping.resourceType}":\n` +
              violations.join('\n')
            );
          }
        }
      ),
      { numRuns: modules.length * EXTERNAL_ARN_MAPPINGS.length * 3 }
    );
  });
});
