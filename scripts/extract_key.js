const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Administrator\\.gemini\\antigravity-ide\\brain\\2c6ef90a-81fa-448f-95ab-f2253b9ba529\\.system_generated\\logs\\transcript.jsonl';

if (!fs.existsSync(logPath)) {
  console.error("Log file not found at:", logPath);
  process.exit(1);
}

const lines = fs.readFileSync(logPath, 'utf8').split('\n');
for (const line of lines) {
  if (!line.trim()) continue;
  try {
    const obj = JSON.parse(line);
    // Find the step where the user provided the JSON (usually USER_INPUT type)
    if (obj.content && obj.content.includes("service_account")) {
      console.log("Found JSON in log! Extracting...");
      
      // The JSON might be embedded inside a text block. Let's find it.
      const match = obj.content.match(/\{[\s\S]*"private_key"[\s\S]*\}/);
      if (match) {
        const parsed = JSON.parse(match[0].trim());
        console.log("Parsed successfully!");
        console.log("Project ID:", parsed.project_id);
        console.log("Client Email:", parsed.client_email);
        
        // Write the clean, parsed service account details to scratch directory
        fs.writeFileSync('scratch/service_account.json', JSON.stringify(parsed, null, 2));
        console.log("Saved clean JSON to scratch/service_account.json");
        process.exit(0);
      }
    }
  } catch (err) {
    // Ignore parse errors on incomplete lines
  }
}

console.log("Could not find the service account JSON in the logs.");
process.exit(1);
