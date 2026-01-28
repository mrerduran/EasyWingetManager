const { execFile } = require('child_process');

// The new implementation of runCommand from src/main.js
const runCommand = (file, args) => {
  return new Promise((resolve) => {
    // Increase maxBuffer to handle large outputs (e.g. winget list)
    // Use execFile to avoid spawning a shell and preventing command injection
    execFile(file, args, { maxBuffer: 1024 * 1024 * 5, encoding: 'utf8' }, (error, stdout, stderr) => {
      if (error) {
        console.error(`Command error: ${error.message}`);
      }
      resolve({ stdout, stderr, error });
    });
  });
};

async function verify() {
  console.log("Verifying Security Fix...");

  // Test case: Injection attempt
  // If vulnerable (using exec shell), $(date) would execute.
  // If secure (using execFile), $(date) should be treated as a literal string.

  const maliciousInput = '$(date)';
  console.log(`Input: ${maliciousInput}`);

  // We use 'echo' instead of 'winget' for cross-platform testing in this environment
  // and because we just want to verify argument passing.
  const result = await runCommand('echo', [maliciousInput]);

  const output = result.stdout.trim();
  console.log(`Output: ${output}`);

  if (output === maliciousInput) {
    console.log("✅ SUCCESS: Input was treated as a literal string. No injection occurred.");
  } else {
    console.log("❌ FAILURE: Output does not match input. Possible injection or unexpected behavior.");
    console.log(`Expected: ${maliciousInput}`);
    console.log(`Actual:   ${output}`);
    process.exit(1);
  }
}

verify();
