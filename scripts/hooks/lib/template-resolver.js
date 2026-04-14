/**
 * Resolve a COC USE template to a local path.
 *
 * Resolution order:
 *   1. Local sibling directory (../kailash-coc-claude-py/)
 *   2. Known parent layouts (~/repos/loom/<template>/)
 *   3. Cache directory (~/.cache/kailash-coc/<template>/)
 *   4. Shallow clone from GitHub to cache (--depth 1)
 *
 * On cache hit, fetches latest from origin/main before returning.
 */

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const CACHE_DIR = path.join(
  process.env.HOME || process.env.USERPROFILE,
  ".cache",
  "kailash-coc",
);

const KNOWN_TEMPLATES = {
  "kailash-coc-claude-py": "terrene-foundation/kailash-coc-claude-py",
  "kailash-coc-claude-rs": "terrene-foundation/kailash-coc-claude-rs",
  "kailash-coc-claude-rb": "terrene-foundation/kailash-coc-claude-rb",
  "kailash-coc-claude-prism": "terrene-foundation/kailash-coc-claude-prism",
};

/**
 * Resolve the USE template for a downstream project.
 * @param {string} cwd - project root directory
 * @returns {{ path: string, source: string, fresh: boolean } | { error: string }}
 */
function resolveTemplate(cwd) {
  const versionPath = path.join(cwd, ".claude", "VERSION");
  if (!fs.existsSync(versionPath)) {
    return {
      error:
        "No .claude/VERSION file found. Run a session first to auto-create it.",
    };
  }

  let version;
  try {
    version = JSON.parse(fs.readFileSync(versionPath, "utf8"));
  } catch (e) {
    return { error: `Failed to parse .claude/VERSION: ${e.message}` };
  }

  const upstream = version.upstream || {};
  const templateName = upstream.template;
  const templateRepo = upstream.template_repo;

  if (!templateName || templateName === "unknown") {
    return {
      error:
        'No upstream.template in .claude/VERSION (or set to "unknown"). ' +
        "Set it to the template name, e.g.: " +
        '"template": "kailash-coc-claude-py"',
    };
  }

  // 1. Check local sibling directory
  const siblingPath = findLocalSibling(cwd, templateName);
  if (siblingPath) {
    return { path: siblingPath, source: "local", fresh: true };
  }

  // 2. Check cache — update if found
  const cachePath = path.join(CACHE_DIR, templateName);
  if (fs.existsSync(path.join(cachePath, ".claude"))) {
    const updated = updateCachedClone(cachePath);
    return { path: cachePath, source: "cache", fresh: updated };
  }

  // 3. Resolve repo slug and clone to cache
  const repoSlug = templateRepo || KNOWN_TEMPLATES[templateName];
  if (!repoSlug) {
    return {
      error:
        `Cannot resolve template "${templateName}". ` +
        `Add "template_repo" to upstream in .claude/VERSION with the GitHub slug ` +
        `(e.g., "terrene-foundation/kailash-coc-claude-py").`,
    };
  }

  const cloned = cloneToCache(repoSlug, cachePath);
  if (cloned) {
    return { path: cachePath, source: "cloned", fresh: true };
  }

  return {
    error:
      `Failed to clone template from github.com/${repoSlug}. ` +
      `Check network connectivity and repo access permissions.`,
  };
}

/**
 * Search for the template as a local directory.
 * Checks sibling dirs and common repo layouts.
 */
function findLocalSibling(cwd, templateName) {
  const candidates = [];

  // Direct sibling: ../kailash-coc-claude-py/
  candidates.push(path.join(path.dirname(cwd), templateName));

  // Common monorepo layout: parent contains loom/ which contains template
  const parent = path.dirname(cwd);
  candidates.push(path.join(parent, "loom", templateName));

  // ~/repos/loom/<template>/
  const home = process.env.HOME || process.env.USERPROFILE;
  candidates.push(path.join(home, "repos", "loom", templateName));
  candidates.push(path.join(home, "repos", templateName));

  for (const candidate of candidates) {
    if (fs.existsSync(path.join(candidate, ".claude")) && candidate !== cwd) {
      return candidate;
    }
  }

  return null;
}

/**
 * Fetch latest from origin/main in an existing cached clone.
 */
function updateCachedClone(cachePath) {
  try {
    execFileSync(
      "git",
      ["-C", cachePath, "fetch", "--depth", "1", "origin", "main"],
      { timeout: 15000, stdio: ["pipe", "pipe", "pipe"] },
    );
    execFileSync("git", ["-C", cachePath, "reset", "--hard", "origin/main"], {
      timeout: 10000,
      stdio: ["pipe", "pipe", "pipe"],
    });
    return true;
  } catch (e) {
    console.error(`[TEMPLATE] Cache update failed: ${e.message}`);
    return false;
  }
}

/**
 * Shallow clone a template repo to the cache directory.
 */
function cloneToCache(repoSlug, cachePath) {
  const httpsUrl = `https://github.com/${repoSlug}.git`;
  const sshUrl = `git@github.com:${repoSlug}.git`;
  const cloneArgs = [
    "clone",
    "--depth",
    "1",
    "--single-branch",
    "--branch",
    "main",
  ];

  fs.mkdirSync(path.dirname(cachePath), { recursive: true });

  try {
    execFileSync("git", [...cloneArgs, httpsUrl, cachePath], {
      timeout: 30000,
      stdio: ["pipe", "pipe", "pipe"],
    });
    return true;
  } catch (httpsErr) {
    try {
      execFileSync("git", [...cloneArgs, sshUrl, cachePath], {
        timeout: 30000,
        stdio: ["pipe", "pipe", "pipe"],
      });
      return true;
    } catch (sshErr) {
      console.error(
        `[TEMPLATE] Clone failed — HTTPS: ${httpsErr.message}, SSH: ${sshErr.message}`,
      );
      return false;
    }
  }
}

module.exports = {
  resolveTemplate,
  findLocalSibling,
  updateCachedClone,
  cloneToCache,
  KNOWN_TEMPLATES,
  CACHE_DIR,
};
