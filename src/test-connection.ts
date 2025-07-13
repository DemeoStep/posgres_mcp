import { Pool } from "pg";
import { config } from "dotenv";

// Load environment variables
config();

async function testConnection() {
  const pool = new Pool({
    host: process.env.POSTGRES_HOST || "localhost",
    port: parseInt(process.env.POSTGRES_PORT || "5432"),
    database: process.env.POSTGRES_DATABASE,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    ssl: process.env.POSTGRES_SSL === "true",
  });

  try {
    console.log("Testing PostgreSQL connection...");
    const client = await pool.connect();
    
    // Test basic query
    const result = await client.query("SELECT NOW() as current_time, version() as pg_version");
    console.log("✅ Connection successful!");
    console.log("Current time:", result.rows[0].current_time);
    console.log("PostgreSQL version:", result.rows[0].pg_version);
    
    client.release();
  } catch (error) {
    console.error("❌ Connection failed:", error);
  } finally {
    await pool.end();
  }
}

testConnection();
