import { Hono } from "hono";
import { cors } from "hono/cors";
import { serveStatic } from "hono/bun";
import { mkdirSync, existsSync, statSync } from "fs";
import { resolve } from "path";
import { connectDb } from "./db";
import { auth } from "./routes/auth";
import { posts } from "./routes/posts";
import { users } from "./routes/users";
import { chat } from "./routes/chat";

type Variables = { userId: string };

const uploadsDir = resolve(import.meta.dir, "../uploads");
if (!existsSync(uploadsDir)) mkdirSync(uploadsDir, { recursive: true });

async function getPort(): Promise<number> {
  const envPath = resolve(import.meta.dir, "../.env");
  const envText = await Bun.file(envPath).text();
  const port = envText.match(/PORT=(\d+)/)?.[1];
  return port ? parseInt(port) : 5000;
}

await connectDb();

const app = new Hono<{ Variables: Variables }>();

app.use(
  "*",
  cors({
    origin: ["http://localhost:5173", "http://127.0.0.1:5173"],
    allowHeaders: ["Content-Type", "Authorization"],
  })
);

app.get("/api/health", (c) => c.json({ ok: true, name: "pirate" }));

app.route("/api/auth", auth);
app.route("/api/posts", posts);
app.route("/api/users", users);
app.route("/api/chat", chat);

app.post("/api/upload", async (c) => {
  const form = await c.req.formData();
  const file = form.get("file");

  if (!file || !(file instanceof File)) {
    return c.json({ error: "No file provided" }, 400);
  }

  if (!file.type.startsWith("image/")) {
    return c.json({ error: "Only images allowed" }, 400);
  }

  if (file.size > 5 * 1024 * 1024) {
    return c.json({ error: "Max 5MB" }, 400);
  }

  const ext = file.name.split(".").pop() || "jpg";
  const filename = `${Date.now()}-${crypto.randomUUID().slice(0, 8)}.${ext}`;
  const buffer = await file.arrayBuffer();
  await Bun.write(`${uploadsDir}/${filename}`, buffer);

  return c.json({ url: `/uploads/${filename}` });
});

app.use("/uploads/*", serveStatic({ root: resolve(import.meta.dir, "..") }));

if (process.env.NODE_ENV === "production") {
  const clientDist = resolve(import.meta.dir, "../../client/dist");
  const indexHtml = resolve(clientDist, "index.html");

  if (existsSync(indexHtml)) {
    app.get("/*", (c) => {
      const filePath = resolve(clientDist, "." + c.req.path);
      const isFile =
        filePath.startsWith(clientDist) &&
        existsSync(filePath) &&
        statSync(filePath).isFile();
      const file = Bun.file(isFile ? filePath : indexHtml);
      return new Response(file, { headers: { "Content-Type": file.type } });
    });
  } else {
    console.warn(`Client build not found at ${clientDist}. Run the client build first.`);
  }
}

const port = await getPort();
console.log(`Pirate server running on http://localhost:${port}`);

export default {
  port,
  fetch: app.fetch,
};
