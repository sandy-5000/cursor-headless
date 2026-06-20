import { Hono } from "hono";
import { ObjectId } from "mongodb";
import { getDb } from "../db";
import { signToken, authMiddleware, getUserId } from "../middleware/auth";
import { avatarUrl, normalizeGender } from "../avatar";
import type { User, UserPublic } from "../types";

const auth = new Hono();

async function hashPassword(password: string): Promise<string> {
  return await Bun.password.hash(password, { algorithm: "bcrypt", cost: 10 });
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return await Bun.password.verify(password, hash);
}

function toPublic(user: User, viewerId?: string): UserPublic {
  const isFollowing = viewerId
    ? user.followers.some((f) => f.toString() === viewerId)
    : false;

  return {
    _id: user._id,
    username: user.username,
    displayName: user.displayName,
    bio: user.bio,
    avatar: user.avatar,
    gender: user.gender,
    followers: user.followers,
    following: user.following,
    createdAt: user.createdAt,
    followerCount: user.followers.length,
    followingCount: user.following.length,
    isFollowing,
  };
}

auth.post("/register", async (c) => {
  const { username, email, password, displayName, gender } = await c.req.json();

  if (!username || !email || !password) {
    return c.json({ error: "Username, email, and password required" }, 400);
  }

  if (username.length < 3 || password.length < 6) {
    return c.json({ error: "Username min 3 chars, password min 6 chars" }, 400);
  }

  const db = getDb();
  const existing = await db.collection<User>("users").findOne({
    $or: [{ username: username.toLowerCase() }, { email: email.toLowerCase() }],
  });

  if (existing) {
    return c.json({ error: "Username or email already taken" }, 409);
  }

  const passwordHash = await hashPassword(password);
  const userGender = normalizeGender(gender);
  const avatar = avatarUrl(username, userGender);

  const user: User = {
    _id: new ObjectId(),
    username: username.toLowerCase(),
    email: email.toLowerCase(),
    passwordHash,
    displayName: displayName || username,
    bio: "",
    avatar,
    gender: userGender,
    followers: [],
    following: [],
    createdAt: new Date(),
  };

  await db.collection<User>("users").insertOne(user);

  const token = await signToken(user._id.toString());
  return c.json({ token, user: toPublic(user) }, 201);
});

auth.post("/login", async (c) => {
  const { login, password } = await c.req.json();

  if (!login || !password) {
    return c.json({ error: "Login and password required" }, 400);
  }

  const db = getDb();
  const user = await db.collection<User>("users").findOne({
    $or: [{ username: login.toLowerCase() }, { email: login.toLowerCase() }],
  });

  if (!user || !(await verifyPassword(password, user.passwordHash))) {
    return c.json({ error: "Invalid credentials" }, 401);
  }

  const token = await signToken(user._id.toString());
  return c.json({ token, user: toPublic(user) });
});

auth.get("/me", authMiddleware, async (c) => {
  const db = getDb();
  const user = await db.collection<User>("users").findOne({
    _id: getUserId(c),
  });

  if (!user) return c.json({ error: "User not found" }, 404);
  return c.json({ user: toPublic(user) });
});

export { auth, toPublic };
