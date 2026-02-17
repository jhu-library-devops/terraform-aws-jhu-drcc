/**
 * Property 3: No hardcoded organization-specific values in resource attributes
 *
 * For any resource block across all modules, string literals in `name`,
 * `assume_role_policy`, `command`, or `image` attributes should not contain
 * organization-specific values (specific GitHub repository paths, hardcoded
 * S3 bucket names not derived from variables, hardcoded AWS account IDs,
 * or static IAM role names) unless those values are derived from input variables.
 *
 * **Validates: Requirements 4.1, 4.2, 4.3, 4.4**
 *
 * Feature: iac-blueprint-analysis, Property 3: No hardcoded organization-specific values in resource attributes
 */

import { describe, it, expect } from 'vitest';
import * as fc from 'fast-check';
import { readdirSync, readFileSync, statSync } from 'fs';
import { join, resolve, relative } from 'path';

const ROOT_DIR = resolve(__dirname, '..');
const MODULES_DIR = join(ROOT_DIR, 'modules');

/**
 * Organization-specific patterns that should NOT appear as hardcoded literals
 * in resource attributes. Each pattern includes a description for clear error messages.
 */
const ORG_SPECIFIC_PATTERNS: { pattern: RegExp; description: string; requirement: string }[] = [
  {
    pattern: /repo:jhu-sheridan-libraries\/[^${}]*/,
    description: 'Hardcoded JHU GitHub repository reference',
    requirement: '4.1',
  },
  {
    pattern: /s3:\/\/jhu-dspace-/,
    description: 'Hardcoded JHU S3 bucket name',
    requirement: '4.2',
  },
  {
    pattern: /\bname\s*=\s*"(GitHubActionsRole|GitHubActions-Test-Role|ecsEventsRole)"/,
    description: 'Hardcoded IAM role name',
    requirement: '4.3',
  },
  {
    pattern: /["']390157243417\.dkr\.ecr\./,
    description: 'Hardcoded AWS account ID in container image reference',
    requirement: '4.4',
  },
];

/**
 * Discover all .tf files across all module directories.
 */
function discoverTerraformFiles(): { filePath: string; relativePath: string }[] {
  const files: { filePath: string; relativePath: string }[] = [];

  function walkDir(dir: string) {
    for (const entry of readdirSync(dir)) {
      if (entry === '.terraform' || entry === 'node_modules') continue;
      const fullPath = join(dir, entry);
      if (statSync(fullPath).isDirectory()) {
        walkDir(fullPath);
      } else if (entry.endsWith('.tf')) {
        files.push({
          filePath: fullPath,
          relativePath: relative(ROOT_DIR, fullPath),
        });
      }
    }
  }

  walkDir(MODULES_DIR);
  return files;
}

describe('Property 3: No hardcoded organization-specific values in resource attributes', () => {
  const tfFiles = discoverTerraformFiles();

  it('discovers Terraform files in modules directory', () => {
    expect(tfFiles.length).toBeGreaterThan(0);
  });

  it('no .tf file contains hardcoded organization-specific values', () => {
    fc.assert(
      fc.property(
        fc.constantFrom(...tfFiles),
        fc.constantFrom(...ORG_SPECIFIC_PATTERNS),
        (file, orgPattern) => {
          const content = readFileSync(file.filePath, 'utf-8');
          const match = content.match(orgPattern.pattern);
          if (match) {
            throw new Error(
              `Found ${orgPattern.description} in ${file.relativePath}: "${match[0]}" ` +
              `(Requirement ${orgPattern.requirement})`
            );
          }
        }
      ),
      { numRuns: tfFiles.length * ORG_SPECIFIC_PATTERNS.length * 2 }
    );
  });
});
