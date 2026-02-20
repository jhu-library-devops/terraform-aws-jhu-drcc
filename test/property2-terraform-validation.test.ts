/**
 * Property 2: Terraform validation passes for all modules
 *
 * For any module directory, running `tofu validate` (after `tofu init`)
 * should produce zero errors. This covers undeclared variables, undeclared
 * locals, duplicate declarations, and missing required attributes.
 *
 * **Validates: Requirements 4.5, 4.6, 4.7, 4.8**
 *
 * Feature: iac-blueprint-analysis, Property 2: Terraform validation passes for all modules
 */

import { describe, it, expect } from 'vitest';
import * as fc from 'fast-check';
import { execSync } from 'child_process';
import { readdirSync, statSync, existsSync } from 'fs';
import { join, resolve } from 'path';

const ROOT_DIR = resolve(__dirname, '..');
const MODULES_DIR = join(ROOT_DIR, 'modules');

/**
 * Discover all module directories that contain .tf files.
 */
function discoverModuleDirectories(): string[] {
  const dirs: string[] = [];
  for (const entry of readdirSync(MODULES_DIR)) {
    const fullPath = join(MODULES_DIR, entry);
    if (!statSync(fullPath).isDirectory()) continue;
    const hasTfFiles = readdirSync(fullPath).some((f) => f.endsWith('.tf'));
    if (hasTfFiles) dirs.push(fullPath);
  }
  return dirs;
}

/**
 * Run `tofu init -backend=false` then `tofu validate` in the given directory.
 * Returns { success: boolean, output: string }.
 */
function tofuValidate(moduleDir: string): { success: boolean; output: string } {
  try {
    execSync('tofu init -backend=false -no-color', {
      cwd: moduleDir,
      stdio: 'pipe',
      timeout: 60000,
    });
  } catch (e: any) {
    return {
      success: false,
      output: `tofu init failed:\n${e.stderr?.toString() ?? e.message}`,
    };
  }

  try {
    const out = execSync('tofu validate -no-color', {
      cwd: moduleDir,
      stdio: 'pipe',
      timeout: 30000,
    });
    return { success: true, output: out.toString() };
  } catch (e: any) {
    return {
      success: false,
      output: e.stderr?.toString() ?? e.stdout?.toString() ?? e.message,
    };
  }
}

describe('Property 2: Terraform validation passes for all modules', () => {
  const moduleDirs = discoverModuleDirectories();

  // Sanity check: we expect at least the 3 known modules
  it('discovers at least 3 module directories', () => {
    expect(moduleDirs.length).toBeGreaterThanOrEqual(3);
  });

  it('tofu validate succeeds for every module directory', () => {
    fc.assert(
      fc.property(
        fc.constantFrom(...moduleDirs),
        (moduleDir: string) => {
          const result = tofuValidate(moduleDir);
          if (!result.success) {
            throw new Error(
              `tofu validate failed for ${moduleDir}:\n${result.output}`
            );
          }
        }
      ),
      { numRuns: moduleDirs.length * 3 }
    );
  });
});
