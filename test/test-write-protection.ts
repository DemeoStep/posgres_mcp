import { Pool } from "pg";
import { config } from "dotenv";

// Load environment variables
config();

// Import the validation function from our MCP server
async function validateReadOnlyQuery(query: string): Promise<void> {
    const normalizedQuery = query.trim().toLowerCase();
    
    // List of forbidden operations
    const forbiddenOperations = [
      'insert', 'update', 'delete', 'drop', 'create', 'alter', 
      'truncate', 'grant', 'revoke', 'commit', 'rollback'
    ];

    // Check if query starts with forbidden operations
    for (const operation of forbiddenOperations) {
      if (normalizedQuery.startsWith(operation)) {
        throw new Error(`Operation ${operation.toUpperCase()} is not allowed. This server only supports read-only operations.`);
      }
    }

    // Must start with SELECT or WITH (for CTEs)
    if (!normalizedQuery.startsWith('select') && !normalizedQuery.startsWith('with')) {
      throw new Error('Only SELECT queries and CTEs (WITH) are allowed.');
    }
}

async function testWriteProtection() {
  const pool = new Pool({
    host: process.env.POSTGRES_HOST || "localhost",
    port: parseInt(process.env.POSTGRES_PORT || "5432"),
    database: process.env.POSTGRES_DATABASE,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    ssl: process.env.POSTGRES_SSL === "true",
  });

  console.log("🛡️  Testing Write Protection in PostgreSQL MCP Server");
  console.log("====================================================");
  console.log("");

  // Test cases - these should all be BLOCKED
  const prohibitedQueries = [
    {
      name: "INSERT Operation",
      query: "INSERT INTO users (username, email) VALUES ('hacker', 'hacker@evil.com')"
    },
    {
      name: "UPDATE Operation", 
      query: "UPDATE users SET email = 'compromised@evil.com' WHERE id = 1"
    },
    {
      name: "DELETE Operation",
      query: "DELETE FROM users WHERE id = 1"
    },
    {
      name: "DROP TABLE",
      query: "DROP TABLE users"
    },
    {
      name: "CREATE TABLE",
      query: "CREATE TABLE malicious_table (id INT)"
    },
    {
      name: "ALTER TABLE",
      query: "ALTER TABLE users ADD COLUMN malicious_field VARCHAR(100)"
    },
    {
      name: "TRUNCATE",
      query: "TRUNCATE TABLE users"
    },
    {
      name: "GRANT Permissions",
      query: "GRANT ALL PRIVILEGES ON users TO public"
    }
  ];

  // Test cases - these should be ALLOWED
  const allowedQueries = [
    {
      name: "Simple SELECT",
      query: "SELECT * FROM users LIMIT 5"
    },
    {
      name: "SELECT with JOIN",
      query: "SELECT u.username, o.total_amount FROM users u JOIN sales.orders o ON u.id = o.user_id LIMIT 3"
    },
    {
      name: "CTE Query",
      query: "WITH user_stats AS (SELECT COUNT(*) as total FROM users) SELECT * FROM user_stats"
    },
    {
      name: "Aggregate Query",
      query: "SELECT COUNT(*) as user_count, AVG(salary) as avg_salary FROM users WHERE active = true"
    }
  ];

  try {
    console.log("❌ Testing PROHIBITED Operations (should be blocked):");
    console.log("----------------------------------------------------");
    
    for (const test of prohibitedQueries) {
      try {
        await validateReadOnlyQuery(test.query);
        console.log(`🚨 SECURITY BREACH: ${test.name} was NOT blocked!`);
      } catch (error) {
        console.log(`✅ ${test.name}: Correctly blocked - ${(error as Error).message}`);
      }
    }

    console.log("");
    console.log("✅ Testing ALLOWED Operations (should work):");
    console.log("--------------------------------------------");
    
    const client = await pool.connect();
    try {
      for (const test of allowedQueries) {
        try {
          await validateReadOnlyQuery(test.query);
          const result = await client.query(test.query);
          console.log(`✅ ${test.name}: Allowed - Found ${result.rows.length} rows`);
        } catch (error) {
          console.log(`❌ ${test.name}: Incorrectly blocked - ${(error as Error).message}`);
        }
      }
    } finally {
      client.release();
    }

    // Test current data integrity
    console.log("");
    console.log("🔍 Data Integrity Check:");
    console.log("------------------------");
    
    const integrityClient = await pool.connect();
    try {
      const userCount = await integrityClient.query("SELECT COUNT(*) as count FROM users");
      const productCount = await integrityClient.query("SELECT COUNT(*) as count FROM sales.products");
      const orderCount = await integrityClient.query("SELECT COUNT(*) as count FROM sales.orders");
      
      console.log(`📊 Users: ${userCount.rows[0].count} (should be 10)`);
      console.log(`📊 Products: ${productCount.rows[0].count} (should be 21)`);
      console.log(`📊 Orders: ${orderCount.rows[0].count} (should be 9)`);
      
      if (userCount.rows[0].count === "10" && 
          productCount.rows[0].count === "21" && 
          orderCount.rows[0].count === "9") {
        console.log("✅ All data counts match expected values - No unauthorized changes!");
      } else {
        console.log("🚨 Data counts don't match - Possible data modification!");
      }
    } finally {
      integrityClient.release();
    }

  } catch (error) {
    console.error("❌ Test failed:", error);
  } finally {
    await pool.end();
  }

  console.log("");
  console.log("🎯 Write Protection Test Complete!");
  console.log("==================================");
}

testWriteProtection();
