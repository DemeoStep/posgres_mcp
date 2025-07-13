import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { Pool, PoolClient } from "pg";
import { z } from "zod";

// Environment configuration schema
const envSchema = z.object({
  POSTGRES_HOST: z.string().default("localhost"),
  POSTGRES_PORT: z.coerce.number().default(5432),
  POSTGRES_DATABASE: z.string(),
  POSTGRES_USER: z.string(),
  POSTGRES_PASSWORD: z.string(),
  POSTGRES_SSL: z.string().transform((val: string) => val === "true").default("false"),
});

// Tool input schemas
const querySchema = z.object({
  query: z.string().describe("The SQL SELECT query to execute"),
});

const describeTableSchema = z.object({
  table_name: z.string().describe("The name of the table to describe"),
  schema_name: z.string().optional().describe("The schema name (optional)"),
});

const listTablesSchema = z.object({
  schema_name: z.string().optional().describe("Filter by schema name (optional)"),
});

const listSchemasSchema = z.object({});

class PostgreSQLMCPServer {
  private server: Server;
  private pool: Pool;

  constructor() {
    this.server = new Server({
      name: "postgresql-mcp-server",
      version: "1.0.0",
    });

    // Validate environment variables
    const env = envSchema.parse(process.env);

    // Initialize PostgreSQL connection pool
    this.pool = new Pool({
      host: env.POSTGRES_HOST,
      port: env.POSTGRES_PORT,
      database: env.POSTGRES_DATABASE,
      user: env.POSTGRES_USER,
      password: env.POSTGRES_PASSWORD,
      ssl: env.POSTGRES_SSL,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.setupToolHandlers();
  }

  private validateReadOnlyQuery(query: string): void {
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

  private async executeQuery(query: string): Promise<any[]> {
    this.validateReadOnlyQuery(query);
    
    const client: PoolClient = await this.pool.connect();
    try {
      const result = await client.query(query);
      return result.rows;
    } finally {
      client.release();
    }
  }

  private setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: "postgres_query",
            description: "Execute a read-only SQL query (SELECT statements only)",
            inputSchema: {
              type: "object",
              properties: {
                query: {
                  type: "string",
                  description: "The SQL SELECT query to execute",
                },
              },
              required: ["query"],
            },
          },
          {
            name: "postgres_describe_table",
            description: "Get detailed information about a table's structure",
            inputSchema: {
              type: "object",
              properties: {
                table_name: {
                  type: "string",
                  description: "The name of the table to describe",
                },
                schema_name: {
                  type: "string",
                  description: "The schema name (optional, defaults to public)",
                },
              },
              required: ["table_name"],
            },
          },
          {
            name: "postgres_list_tables",
            description: "List all tables in the database",
            inputSchema: {
              type: "object",
              properties: {
                schema_name: {
                  type: "string",
                  description: "Filter by schema name (optional)",
                },
              },
              required: [],
            },
          },
          {
            name: "postgres_list_schemas",
            description: "List all schemas in the database",
            inputSchema: {
              type: "object",
              properties: {},
              required: [],
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request: any) => {
      try {
        switch (request.params.name) {
          case "postgres_query": {
            const args = querySchema.parse(request.params.arguments);
            const result = await this.executeQuery(args.query);
            
            return {
              content: [
                {
                  type: "text",
                  text: `Query executed successfully. Found ${result.length} rows.\n\n${JSON.stringify(result, null, 2)}`,
                },
              ],
            };
          }

          case "postgres_describe_table": {
            const args = describeTableSchema.parse(request.params.arguments);
            const schema = args.schema_name || "public";
            
            const query = `
              SELECT 
                column_name,
                data_type,
                is_nullable,
                column_default,
                character_maximum_length,
                numeric_precision,
                numeric_scale
              FROM information_schema.columns 
              WHERE table_name = $1 AND table_schema = $2
              ORDER BY ordinal_position;
            `;
            
            const client = await this.pool.connect();
            try {
              const result = await client.query(query, [args.table_name, schema]);
              
              if (result.rows.length === 0) {
                throw new Error(`Table "${args.table_name}" not found in schema "${schema}"`);
              }
              
              return {
                content: [
                  {
                    type: "text",
                    text: `Table: ${schema}.${args.table_name}\n\nColumns:\n${JSON.stringify(result.rows, null, 2)}`,
                  },
                ],
              };
            } finally {
              client.release();
            }
          }

          case "postgres_list_tables": {
            const args = listTablesSchema.parse(request.params.arguments);
            
            let query = `
              SELECT 
                table_schema,
                table_name,
                table_type
              FROM information_schema.tables 
              WHERE table_type = 'BASE TABLE'
            `;
            
            const params: string[] = [];
            if (args.schema_name) {
              query += ` AND table_schema = $1`;
              params.push(args.schema_name);
            }
            
            query += ` ORDER BY table_schema, table_name`;
            
            const client = await this.pool.connect();
            try {
              const result = await client.query(query, params);
              
              return {
                content: [
                  {
                    type: "text",
                    text: `Found ${result.rows.length} tables:\n\n${JSON.stringify(result.rows, null, 2)}`,
                  },
                ],
              };
            } finally {
              client.release();
            }
          }

          case "postgres_list_schemas": {
            listSchemasSchema.parse(request.params.arguments);
            
            const query = `
              SELECT 
                schema_name,
                schema_owner
              FROM information_schema.schemata 
              WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
              ORDER BY schema_name;
            `;
            
            const client = await this.pool.connect();
            try {
              const result = await client.query(query);
              
              return {
                content: [
                  {
                    type: "text",
                    text: `Found ${result.rows.length} schemas:\n\n${JSON.stringify(result.rows, null, 2)}`,
                  },
                ],
              };
            } finally {
              client.release();
            }
          }

          default:
            throw new Error(`Unknown tool: ${request.params.name}`);
        }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        return {
          content: [
            {
              type: "text",
              text: `Error: ${errorMessage}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("PostgreSQL MCP server running on stdio");
  }

  async close() {
    await this.pool.end();
  }
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.error('Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.error('Shutting down gracefully...');
  process.exit(0);
});

// Start the server
const server = new PostgreSQLMCPServer();
server.run().catch(console.error);
