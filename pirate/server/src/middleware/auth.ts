import { Context, Next } from "hono";
import jwt from "jsonwebtoken";
import { ObjectId } from "mongodb";
import { resolve } from "path";

export type AuthUser = { userId: string };

async function getJwtSecret(): Promise<string> {
  const envPath = resolve(import.meta.dir, "../../.env");
  const envText = await Bun.file(envPath).text();
  return (
    envText.match(/JWT_SECRET=(.+)/)?.[1]?.trim() ??
    process.env.JWT_SECRET ??
    "dev-secret"
  );
}

let jwtSecret: string | null = null;

export async function signToken(userId: string): Promise<string> {
  if (!jwtSecret) jwtSecret = await getJwtSecret();
  return jwt.sign({ userId }, jwtSecret, { expiresIn: "30d" });
}

export async function authMiddleware(c: Context, next: Next) {
  const header = c.req.header("Authorization");
  if (!header?.startsWith("Bearer ")) {
    return c.json({ error: "Unauthorized" }, 401);
  }

  if (!jwtSecret) jwtSecret = await getJwtSecret();

  try {
    const payload = jwt.verify(header.slice(7), jwtSecret) as AuthUser;
    c.set("userId", payload.userId);
    await next();
  } catch {
    return c.json({ error: "Invalid token" }, 401);
  }
}

export async function optionalAuth(c: Context, next: Next) {
  const header = c.req.header("Authorization");
  if (header?.startsWith("Bearer ")) {
    if (!jwtSecret) jwtSecret = await getJwtSecret();
    try {
      const payload = jwt.verify(header.slice(7), jwtSecret) as AuthUser;
      c.set("userId", payload.userId);
    } catch {
      /* ignore */
    }
  }
  await next();
}

export function getUserId(c: Context): ObjectId {
  return new ObjectId(c.get("userId") as string);
}
