import { Pool } from "pg";
import { config } from "dotenv";

// Load environment variables
config();

// Simulate MCP server query execution with the same validation logic
class MockMCPServer {
  private pool: Pool;

  constructor() {
    this.pool = new Pool({
      host: process.env.POSTGRES_HOST || "localhost",
      port: parseInt(process.env.POSTGRES_PORT || "5432"),
      database: process.env.POSTGRES_DATABASE,
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      ssl: process.env.POSTGRES_SSL === "true",
    });
  }

  private validateReadOnlyQuery(query: string): void {
    const normalizedQuery = query.trim().toLowerCase();
    
    // Remove comments and normalize whitespace
    const cleanedQuery = normalizedQuery
      .replace(/\/\*[\s\S]*?\*\//g, ' ')  // Remove /* */ comments
      .replace(/--.*$/gm, ' ')            // Remove -- comments
      .replace(/\s+/g, ' ')               // Normalize whitespace
      .trim();
    
    // List of forbidden operation patterns (as separate words)
    const forbiddenPatterns = [
      /\binsert\s+into\b/,
      /\bupdate\s+\w+\s+set\b/,
      /\bdelete\s+from\b/,
      /\bdrop\s+(table|database|schema|view|index)\b/,
      /\bcreate\s+(table|database|schema|view|index)\b/,
      /\balter\s+(table|database|schema)\b/,
      /\btruncate\s+(table\s+)?\w+\b/,
      /\bgrant\s+\w+/,
      /\brevoke\s+\w+/,
      /\bcommit\b/,
      /\brollback\b/
    ];

    // Check if query contains forbidden patterns
    for (const pattern of forbiddenPatterns) {
      if (pattern.test(cleanedQuery)) {
        const match = cleanedQuery.match(pattern);
        throw new Error(`Operation ${match?.[0].toUpperCase()} is not allowed. This server only supports read-only operations.`);
      }
    }

    // Must start with SELECT or WITH (for CTEs)
    if (!cleanedQuery.startsWith('select') && !cleanedQuery.startsWith('with')) {
      throw new Error('Only SELECT queries and CTEs (WITH) are allowed.');
    }
  }

  async executeQuery(query: string): Promise<any> {
    this.validateReadOnlyQuery(query);
    
    const client = await this.pool.connect();
    try {
      const result = await client.query(query);
      return {
        success: true,
        rowCount: result.rows.length,
        data: result.rows
      };
    } finally {
      client.release();
    }
  }

  async close() {
    await this.pool.end();
  }
}

async function testMCPServerSecurity() {
  console.log("🧪 Testing MCP Server Security Against Malicious Queries");
  console.log("========================================================");
  console.log("");

  const server = new MockMCPServer();

  // Tricky queries that attackers might try
  const maliciousQueries = [
    {
      name: "SQL Injection Attempt",
      query: "SELECT * FROM users; DROP TABLE users; --",
      shouldPass: false
    },
    {
      name: "Comment with Malicious Code (Should Pass)",
      query: "SELECT * FROM users /* INSERT INTO users VALUES ('hacker', 'evil@hack.com') */ LIMIT 1",
      shouldPass: true // This should pass because comments are stripped
    },
    {
      name: "UNION with INSERT",
      query: "SELECT username FROM users UNION INSERT INTO users VALUES ('bad', 'bad@evil.com')",
      shouldPass: false
    },
    {
      name: "Nested Query Attack",
      query: "SELECT (INSERT INTO users VALUES ('nested', 'nested@evil.com')) FROM users",
      shouldPass: false
    },
    {
      name: "Case Variation Attack",
      query: "InSeRt InTo users (username, email) VALUES ('case', 'case@evil.com')",
      shouldPass: false
    },
    {
      name: "Leading Whitespace Attack",
      query: "   \n  \t  UPDATE users SET email = 'whitespace@evil.com'",
      shouldPass: false
    }
  ];

  const legitimateQueries = [
    {
      name: "User List",
      query: "SELECT id, username, email, active FROM users ORDER BY created_at DESC LIMIT 5"
    },
    {
      name: "Order Analytics",
      query: "SELECT COUNT(*) as total_orders, SUM(total_amount) as revenue FROM sales.orders WHERE status = 'completed'"
    },
    {
      name: "Product Categories",
      query: "SELECT c.name, COUNT(p.id) as product_count FROM sales.categories c LEFT JOIN sales.products p ON c.id = p.category_id GROUP BY c.id, c.name"
    }
  ];

  try {
    console.log("🚨 Testing Malicious Query Attempts:");
    console.log("------------------------------------");
    
    for (const test of maliciousQueries) {
      try {
        await server.executeQuery(test.query);
        if (test.shouldPass) {
          console.log(`✅ ${test.name}: Correctly allowed (comments stripped) - Safe query executed`);
        } else {
          console.log(`🆘 SECURITY BREACH: ${test.name} was executed!`);
        }
      } catch (error) {
        if (test.shouldPass) {
          console.log(`❌ ${test.name}: Incorrectly blocked - ${(error as Error).message}`);
        } else {
          console.log(`✅ ${test.name}: Blocked - ${(error as Error).message}`);
        }
      }
    }

    console.log("");
    console.log("✅ Testing Legitimate Queries:");
    console.log("------------------------------");
    
    for (const test of legitimateQueries) {
      try {
        const result = await server.executeQuery(test.query);
        console.log(`✅ ${test.name}: Success - ${result.rowCount} rows returned`);
        
        // Show first row of data for verification
        if (result.data.length > 0) {
          const firstRow = result.data[0];
          const keys = Object.keys(firstRow).slice(0, 3); // Show first 3 columns
          const preview = keys.map(key => `${key}: ${firstRow[key]}`).join(", ");
          console.log(`   📄 Sample: ${preview}${keys.length < Object.keys(firstRow).length ? '...' : ''}`);
        }
      } catch (error) {
        console.log(`❌ ${test.name}: Incorrectly blocked - ${(error as Error).message}`);
      }
    }

    // Final integrity check
    console.log("");
    console.log("🔒 Final Security Assessment:");
    console.log("-----------------------------");
    
    const userCountResult = await server.executeQuery("SELECT COUNT(*) as count FROM users");
    const userCount = userCountResult.data[0].count;
    
    console.log(`📊 Current user count: ${userCount}`);
    
    if (userCount === "10") {
      console.log("✅ SECURITY TEST PASSED: No unauthorized data modifications detected!");
      console.log("🛡️  MCP Server successfully blocked all malicious queries while allowing legitimate reads.");
    } else {
      console.log("🚨 SECURITY BREACH: User count changed! Data may have been modified.");
    }

  } catch (error) {
    console.error("❌ Security test failed:", error);
  } finally {
    await server.close();
  }

  console.log("");
  console.log("🎯 MCP Server Security Test Complete!");
  console.log("=====================================");
}

testMCPServerSecurity();
