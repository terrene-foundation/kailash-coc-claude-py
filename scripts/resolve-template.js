#!/usr/bin/env node
/**
 * Standalone template resolver — finds or fetches the COC USE template
 * for the current project.
 *
 * Usage: node scripts/resolve-template.js [project-dir]
 * Output: JSON { path, source, fresh } or { error }
 * Exit:   0 on success, 1 on error
 */

const { resolveTemplate } = require("./hooks/lib/template-resolver");

const cwd = process.argv[2] || process.cwd();
const result = resolveTemplate(cwd);

console.log(JSON.stringify(result, null, 2));
process.exit(result.error ? 1 : 0);
