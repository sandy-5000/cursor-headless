import { Hono } from "hono";
import { ObjectId } from "mongodb";
import { getDb } from "../db";
import { authMiddleware, getUserId, optionalAuth } from "../middleware/auth";
import { toPublic } from "./auth";
import type { Post, PostWithAuthor, User } from "../types";

const posts = new Hono();

export async function enrichPosts(
  rawPosts: Post[],
  viewerId?: string
): Promise<PostWithAuthor[]> {
  const db = getDb();
  const userIds = [...new Set(rawPosts.map((p) => p.userId.toString()))];
  const authors = await db
    .collection<User>("users")
    .find({ _id: { $in: userIds.map((id) => new ObjectId(id)) } })
    .toArray();

  const authorMap = new Map(authors.map((a) => [a._id.toString(), a]));

  return rawPosts.map((post) => {
    const author = authorMap.get(post.userId.toString())!;
    return {
      ...post,
      author: toPublic(author, viewerId),
      liked: viewerId
        ? post.likes.some((l) => l.toString() === viewerId)
        : false,
      likeCount: post.likes.length,
      commentCount: post.comments.length,
    };
  });
}

posts.get("/feed", optionalAuth, async (c) => {
  const db = getDb();
  const viewerId = c.get("userId") as string | undefined;
  const page = Math.max(1, parseInt(c.req.query("page") || "1"));
  const limit = Math.min(20, parseInt(c.req.query("limit") || "20"));
  const skip = (page - 1) * limit;

  let userIds: ObjectId[] | null = null;

  if (viewerId) {
    const me = await db.collection<User>("users").findOne({
      _id: new ObjectId(viewerId),
    });
    // Only scope the feed to the people you follow once you actually follow
    // someone. Brand-new users (following nobody) get a global feed so Home
    // isn't empty.
    if (me && me.following.length > 0) {
      userIds = [me._id, ...me.following];
    }
  }

  const filter = userIds ? { userId: { $in: userIds } } : {};
  const rawPosts = await db
    .collection<Post>("posts")
    .find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .toArray();

  const enriched = await enrichPosts(rawPosts, viewerId);
  return c.json({ posts: enriched, page, hasMore: rawPosts.length === limit });
});

posts.get("/explore", optionalAuth, async (c) => {
  const db = getDb();
  const viewerId = c.get("userId") as string | undefined;
  const page = Math.max(1, parseInt(c.req.query("page") || "1"));
  const limit = Math.min(20, parseInt(c.req.query("limit") || "20"));
  const skip = (page - 1) * limit;

  const rawPosts = await db
    .collection<Post>("posts")
    .find({})
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .toArray();

  const enriched = await enrichPosts(rawPosts, viewerId);
  return c.json({ posts: enriched, page, hasMore: rawPosts.length === limit });
});

posts.get("/:id", optionalAuth, async (c) => {
  const db = getDb();
  const viewerId = c.get("userId") as string | undefined;

  let postId: ObjectId;
  try {
    postId = new ObjectId(c.req.param("id"));
  } catch {
    return c.json({ error: "Invalid post id" }, 400);
  }

  const post = await db.collection<Post>("posts").findOne({ _id: postId });
  if (!post) return c.json({ error: "Post not found" }, 404);

  const [enriched] = await enrichPosts([post], viewerId);
  return c.json({ post: enriched });
});

posts.post("/", authMiddleware, async (c) => {
  const { content, imageUrl } = await c.req.json();
  const userId = getUserId(c);

  if (!content?.trim() && !imageUrl) {
    return c.json({ error: "Post needs content or an image" }, 400);
  }

  if (content && content.length > 500) {
    return c.json({ error: "Post max 500 characters" }, 400);
  }

  const post: Post = {
    _id: new ObjectId(),
    userId,
    content: content?.trim() || "",
    imageUrl: imageUrl || undefined,
    likes: [],
    comments: [],
    createdAt: new Date(),
  };

  const db = getDb();
  await db.collection<Post>("posts").insertOne(post);

  const [enriched] = await enrichPosts([post], userId.toString());
  return c.json({ post: enriched }, 201);
});

posts.post("/:id/like", authMiddleware, async (c) => {
  const db = getDb();
  const userId = getUserId(c);

  let postId: ObjectId;
  try {
    postId = new ObjectId(c.req.param("id"));
  } catch {
    return c.json({ error: "Invalid post id" }, 400);
  }

  const post = await db.collection<Post>("posts").findOne({ _id: postId });
  if (!post) return c.json({ error: "Post not found" }, 404);

  const liked = post.likes.some((l) => l.equals(userId));

  if (liked) {
    await db.collection<Post>("posts").updateOne(
      { _id: postId },
      { $pull: { likes: userId } }
    );
  } else {
    await db.collection<Post>("posts").updateOne(
      { _id: postId },
      { $addToSet: { likes: userId } }
    );
  }

  const updated = await db.collection<Post>("posts").findOne({ _id: postId });
  const [enriched] = await enrichPosts([updated!], userId.toString());
  return c.json({ post: enriched });
});

posts.post("/:id/comments", authMiddleware, async (c) => {
  const { content } = await c.req.json();
  const userId = getUserId(c);

  if (!content?.trim()) {
    return c.json({ error: "Comment content required" }, 400);
  }

  let postId: ObjectId;
  try {
    postId = new ObjectId(c.req.param("id"));
  } catch {
    return c.json({ error: "Invalid post id" }, 400);
  }

  const comment = {
    _id: new ObjectId(),
    userId,
    content: content.trim(),
    createdAt: new Date(),
  };

  const db = getDb();
  const result = await db.collection<Post>("posts").updateOne(
    { _id: postId },
    { $push: { comments: comment } }
  );

  if (result.matchedCount === 0) {
    return c.json({ error: "Post not found" }, 404);
  }

  const post = await db.collection<Post>("posts").findOne({ _id: postId });
  const [enriched] = await enrichPosts([post!], userId.toString());
  return c.json({ post: enriched }, 201);
});

posts.delete("/:id", authMiddleware, async (c) => {
  const db = getDb();
  const userId = getUserId(c);

  let postId: ObjectId;
  try {
    postId = new ObjectId(c.req.param("id"));
  } catch {
    return c.json({ error: "Invalid post id" }, 400);
  }

  const post = await db.collection<Post>("posts").findOne({ _id: postId });
  if (!post) return c.json({ error: "Post not found" }, 404);
  if (!post.userId.equals(userId)) {
    return c.json({ error: "Not your post" }, 403);
  }

  await db.collection<Post>("posts").deleteOne({ _id: postId });
  return c.json({ ok: true });
});

export { posts };
