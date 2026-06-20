import { Hono } from "hono";
import { ObjectId } from "mongodb";
import { getDb } from "../db";
import { authMiddleware, getUserId, optionalAuth } from "../middleware/auth";
import { toPublic } from "./auth";
import { enrichPosts } from "./posts";
import { avatarUrl, normalizeGender } from "../avatar";
import type { Post, User } from "../types";

const users = new Hono();

users.get("/suggested", authMiddleware, async (c) => {
  const db = getDb();
  const me = await db.collection<User>("users").findOne({
    _id: getUserId(c),
  });

  if (!me) return c.json({ users: [] });

  const exclude = [me._id, ...me.following];
  const suggested = await db
    .collection<User>("users")
    .find({ _id: { $nin: exclude } })
    .sort({ createdAt: -1 })
    .limit(5)
    .toArray();

  return c.json({
    users: suggested.map((u) => toPublic(u, me._id.toString())),
  });
});

users.get("/search", optionalAuth, async (c) => {
  const q = c.req.query("q")?.trim();
  if (!q) return c.json({ users: [] });

  const db = getDb();
  const viewerId = c.get("userId") as string | undefined;
  const regex = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");

  const results = await db
    .collection<User>("users")
    .find({
      $or: [{ username: regex }, { displayName: regex }],
    })
    .limit(10)
    .toArray();

  return c.json({
    users: results.map((u) => toPublic(u, viewerId)),
  });
});

// Generate a fresh random avatar (used by the "Generate" button in settings).
users.get("/avatar/generate", authMiddleware, (c) => {
  const gender = normalizeGender(c.req.query("gender"));
  const seed = crypto.randomUUID();
  return c.json({ avatar: avatarUrl(seed, gender) });
});

users.get("/:username", optionalAuth, async (c) => {
  const db = getDb();
  const viewerId = c.get("userId") as string | undefined;
  const username = c.req.param("username").toLowerCase();

  const user = await db.collection<User>("users").findOne({ username });
  if (!user) return c.json({ error: "User not found" }, 404);

  const posts = await db
    .collection<Post>("posts")
    .find({ userId: user._id })
    .sort({ createdAt: -1 })
    .limit(50)
    .toArray();

  const enriched = await enrichPosts(posts, viewerId);

  return c.json({
    user: toPublic(user, viewerId),
    posts: enriched,
  });
});

users.patch("/me", authMiddleware, async (c) => {
  const { displayName, bio, avatar, gender } = await c.req.json();
  const db = getDb();
  const userId = getUserId(c);

  const updates: Partial<User> = {};
  if (displayName !== undefined) updates.displayName = displayName.trim();
  if (bio !== undefined) updates.bio = bio.trim().slice(0, 160);

  // Changing gender regenerates the avatar from the username (unless an
  // explicit avatar is also provided, which then takes precedence).
  if (gender !== undefined) {
    const g = normalizeGender(gender);
    updates.gender = g;
    const me = await db.collection<User>("users").findOne({ _id: userId });
    if (me) updates.avatar = avatarUrl(me.username, g);
  }

  if (avatar !== undefined) updates.avatar = avatar;

  await db.collection<User>("users").updateOne(
    { _id: userId },
    { $set: updates }
  );

  const user = await db.collection<User>("users").findOne({ _id: userId });
  return c.json({ user: toPublic(user!) });
});

users.post("/:username/follow", authMiddleware, async (c) => {
  const db = getDb();
  const meId = getUserId(c);
  const username = c.req.param("username").toLowerCase();

  const target = await db.collection<User>("users").findOne({ username });
  if (!target) return c.json({ error: "User not found" }, 404);
  if (target._id.equals(meId)) {
    return c.json({ error: "Cannot follow yourself" }, 400);
  }

  const me = await db.collection<User>("users").findOne({ _id: meId });
  const isFollowing = me!.following.some((f) => f.equals(target._id));

  if (isFollowing) {
    await db.collection<User>("users").updateOne(
      { _id: meId },
      { $pull: { following: target._id } }
    );
    await db.collection<User>("users").updateOne(
      { _id: target._id },
      { $pull: { followers: meId } }
    );
  } else {
    await db.collection<User>("users").updateOne(
      { _id: meId },
      { $addToSet: { following: target._id } }
    );
    await db.collection<User>("users").updateOne(
      { _id: target._id },
      { $addToSet: { followers: meId } }
    );
  }

  const updated = await db.collection<User>("users").findOne({ username });
  return c.json({ user: toPublic(updated!, meId.toString()) });
});

export { users };
