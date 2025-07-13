// Test the comment removal logic specifically
const testQuery = "SELECT * FROM users /* INSERT INTO users VALUES ('hacker', 'evil@hack.com') */ LIMIT 1";

console.log("Original query:", testQuery);

const normalizedQuery = testQuery.trim().toLowerCase();
console.log("Normalized:", normalizedQuery);

const cleanedQuery = normalizedQuery
  .replace(/\/\*[\s\S]*?\*\//g, ' ')  // Remove /* */ comments
  .replace(/--.*$/gm, ' ')            // Remove -- comments
  .replace(/\s+/g, ' ')               // Normalize whitespace
  .trim();

console.log("Cleaned:", cleanedQuery);

const forbiddenPatterns = [
  /\binsert\s+into\b/,
  /\bupdate\s+\w+\s+set\b/,
  /\bdelete\s+from\b/
];

for (const pattern of forbiddenPatterns) {
  if (pattern.test(cleanedQuery)) {
    console.log(`Found forbidden pattern: ${pattern}`);
  }
}
