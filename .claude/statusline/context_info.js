#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const readline = require("readline");
const { execSync } = require("child_process");

// Constants
const COMPACTION_THRESHOLD = 200000 * 0.8;

// Read JSON from stdin
let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", async () => {
  try {
    const data = JSON.parse(input);

    // Extract values
    const model = data.model?.display_name || data.model?.id || "Unknown";
    const version = data.version || "Unknown";
    const total_duration = data.cost?.total_duration_ms || 0;
    const total_cost_usd = data.cost?.total_cost_usd || 0;
    const currentDir = path.basename(
      data.workspace?.current_dir || data.cwd || ".",
    );
    // const sessionId = data.session_id;

    // Check for git information
    let gitInfo = "";
    try {
      // Get current git branch using git command (works in subdirectories)
      const branch = execSync("git rev-parse --abbrev-ref HEAD", {
        encoding: "utf8",
      }).trim();

      // Get git status information
      const statusOutput = execSync("git status --porcelain", {
        encoding: "utf8",
      });
      const modifiedFiles = statusOutput
        .split("\n")
        .filter((line) => line.trim() && line.startsWith(" M")).length;
      const untrackedFiles = statusOutput
        .split("\n")
        .filter((line) => line.trim() && line.startsWith("??")).length;
      const stagedFiles = statusOutput
        .split("\n")
        .filter(
          (line) =>
            line.trim() &&
            (line.startsWith("A ") ||
              line.startsWith("M ") ||
              line.startsWith("D ")),
        ).length;

      // Get ahead/behind information
      let aheadBehind = "";
      try {
        const trackingBranch = execSync(
          `git rev-parse --abbrev-ref ${branch}@{upstream}`,
          { encoding: "utf8" },
        ).trim();
        const aheadBehindOutput = execSync(
          `git rev-list --left-right --count ${trackingBranch}...HEAD`,
          { encoding: "utf8" },
        ).trim();
        const [behind, ahead] = aheadBehindOutput.split("\t").map(Number);

        if (ahead > 0 || behind > 0) {
          aheadBehind = ` (↑${ahead} ↓${behind})`;
        }
      } catch (e) {
        // No upstream or other error
      }

      // Build git info string with bright color coding
      let statusColor = "\x1b[92m"; // Bright green for clean
      if (modifiedFiles > 0 || untrackedFiles > 0 || stagedFiles > 0) {
        statusColor = "\x1b[93m"; // Bright yellow for changes
      }

      const fileInfo = [];
      if (stagedFiles > 0) fileInfo.push(`\x1b[92m+${stagedFiles}\x1b[97m`);
      if (modifiedFiles > 0) fileInfo.push(`\x1b[93m~${modifiedFiles}\x1b[97m`);
      if (untrackedFiles > 0)
        fileInfo.push(`\x1b[91m?${untrackedFiles}\x1b[97m`);

      const fileInfoStr = fileInfo.length > 0 ? ` [${fileInfo.join(" ")}]` : "";
      gitInfo = `\x1b[96mGit info: ${statusColor}${branch}\x1b[97m${aheadBehind}${fileInfoStr}`;
    } catch (e) {
      // Not a git repo or can't read git info
    }

    // Calculate token usage for current session
    let totalTokens = 0;

    const transcript_path = data.transcript_path || undefined;
    if (transcript_path && fs.existsSync(transcript_path)) {
      totalTokens = await calculateTokensFromTranscript(transcript_path);
    }

    // Calculate percentage
    const percentage = Math.min(
      100,
      Math.round((totalTokens / COMPACTION_THRESHOLD) * 100),
    );

    // Format token display
    const tokenDisplay = formatTokenCount(totalTokens);

    // Color coding for percentage (bright colors)
    let percentageColor = "\x1b[92m"; // Bright green
    if (percentage >= 70) percentageColor = "\x1b[93m"; // Bright yellow
    if (percentage >= 90) percentageColor = "\x1b[91m"; // Bright red

    // Build status line with bright colors
    const statusLine = `\x1b[96mModel: \x1b[97m${model} | \x1b[96mVersion: \x1b[97m${version}\n\x1b[96mCurrent dir: \x1b[97m📁 ${currentDir} | ${gitInfo}\n\x1b[96mTotal token: \x1b[97m🪙 ${tokenDisplay} (${percentageColor}${percentage}%\x1b[97m) | \x1b[96mTotal duration: \x1b[97m${total_duration} ms\n\x1b[96mCost: \x1b[97m$${total_cost_usd}`;

    console.log(statusLine);
  } catch (error) {
    // Fallback status line on error
    console.log(
      "\x1b[91m[Error]\x1b[97m\nversion: ${version}\n\x1b[96mCurrent dir: \x1b[97m📁 .\n\x1b[96mTotal token: \x1b[97m🪙 0 (0%)",
    );
  }
});

async function calculateTokensFromTranscript(filePath) {
  return new Promise((resolve, reject) => {
    let lastUsage = null;

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity,
    });

    rl.on("line", (line) => {
      try {
        const entry = JSON.parse(line);

        // Check if this is an assistant message with usage data
        if (entry.type === "assistant" && entry.message?.usage) {
          lastUsage = entry.message.usage;
        }
      } catch (e) {
        // Skip invalid JSON lines
      }
    });

    rl.on("close", () => {
      if (lastUsage) {
        // The last usage entry contains cumulative tokens
        const totalTokens =
          (lastUsage.input_tokens || 0) +
          (lastUsage.output_tokens || 0) +
          (lastUsage.cache_creation_input_tokens || 0) +
          (lastUsage.cache_read_input_tokens || 0);
        resolve(totalTokens);
      } else {
        resolve(0);
      }
    });

    rl.on("error", (err) => {
      reject(err);
    });
  });
}

function formatTokenCount(tokens) {
  if (tokens >= 1000000) {
    return `${(tokens / 1000000).toFixed(1)}M`;
  } else if (tokens >= 1000) {
    return `${(tokens / 1000).toFixed(1)}K`;
  }
  return tokens.toString();
}
