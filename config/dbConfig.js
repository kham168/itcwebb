import dotevn from "dotenv";
dotevn.config();
import { logEvents } from "../middleware/logEvent.js";
import pkg from "pg";
const { Pool } = pkg;

const dbPool = new Pool({
  host: String(process.env.DBHOST),
  database: String(process.env.DBNAME),
  user: String(process.env.DBUSER),
  password: String(process.env.DBPWD),
  port: Number(process.env.DBPORT),
  connectionTimeoutMillis: 90000,
  idleTimeoutMillis: 30000,
  max: 100,
  allowExitOnIdle: true,
});

// export const dbMiddleware = (req, res, next) => {
//   console.log("HHHHHHHH");
//   dbPool.connect((err, client, success) => {
//     if (err) {
//       return next(err);
//     }

//     //attach db to the client req
//     req.dbClient = client;

//     //release client back to the pool
//     req.releaseClient = success;

//     //go to next middleware
//     next();
//   });
// };

export const dbExecution = async (query, params = []) => {
  const client = await dbPool.connect();

  try {
    // Check if query is defined and is a non-empty string
    if (typeof query !== "string" || query.trim() === "") {
      throw new Error("Invalid query");
    }
    const result = await client.query(query, params);

    return result;
  } catch (error) {
    await logEvents(`Query: ${query}\n\nParams: ${params}`);
    console.error("Error executing database query:", error);
    return false;
  } finally {
    if (client) client.release();
  }
};

// export const dbExecution = async (query, params = []) => {
//   const client = await dbPool.connect();
//   console.log("Connected to database");

//   try {
//     if (typeof query !== "string" || query.trim() === "") {
//       throw new Error("Invalid query string1");
//     }
//     if (!Array.isArray(params)) {
//       throw new Error("Params must be an array");
//     }

//     const result = await client.query(query, params);
//     console.log("Query result:", result);
//     return result;
//   } catch (error) {
//     // await logEvents(`Query: ${query}\n\nParams:${params}`);
//     console.error("Error executing database query:", error);
//     return false;
//   } finally {
//     if (client) client.release();
//   }
// };
