import { MongoClient, Db, ObjectId } from "mongodb";
import { resolve } from "path";

export { ObjectId };

let db: Db;

export async function connectDb(): Promise<Db> {
  const envPath = resolve(import.meta.dir, "../.env");
  const envFile = Bun.file(envPath);
  const envText = await envFile.text();
  const url =
    envText.match(/MONGO_DB_URL=(.+)/)?.[1]?.trim() ??
    process.env.MONGO_DB_URL;

  if (!url) throw new Error("MONGO_DB_URL not found in .env");

  const client = new MongoClient(url.replace(/\/[^/?]+(\?|$)/, "/social$1"));
  await client.connect();
  db = client.db("social");
  console.log("MongoDB connected (database: social)");
  return db;
}

export function getDb(): Db {
  if (!db) throw new Error("Database not connected");
  return db;
}
