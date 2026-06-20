import { Hono } from "hono";
import { ObjectId } from "mongodb";
import { getDb } from "../db";
import { authMiddleware, getUserId } from "../middleware/auth";
import { toPublic } from "./auth";
import type { Conversation, Message, User } from "../types";

const chat = new Hono();

chat.use("*", authMiddleware);

function parseId(id: string): ObjectId | null {
  try {
    return new ObjectId(id);
  } catch {
    return null;
  }
}

// List my conversations, newest activity first
chat.get("/conversations", async (c) => {
  const db = getDb();
  const me = getUserId(c);

  const convos = await db
    .collection<Conversation>("conversations")
    .find({ participants: me })
    .sort({ lastMessageAt: -1 })
    .limit(50)
    .toArray();

  const partnerIds = convos
    .map((cv) => cv.participants.find((p) => !p.equals(me)))
    .filter((p): p is ObjectId => !!p);

  const partners = await db
    .collection<User>("users")
    .find({ _id: { $in: partnerIds } })
    .toArray();

  const map = new Map(partners.map((p) => [p._id.toString(), p]));

  const conversations = convos
    .map((cv) => {
      const pid = cv.participants.find((p) => !p.equals(me));
      const partner = pid ? map.get(pid.toString()) : null;
      if (!partner) return null;
      return {
        _id: cv._id,
        partner: toPublic(partner, me.toString()),
        lastText: cv.lastText,
        lastSenderId: cv.lastSenderId,
        lastMessageAt: cv.lastMessageAt,
      };
    })
    .filter(Boolean);

  return c.json({ conversations });
});

// Find or create a 1:1 conversation with a user
chat.post("/start", async (c) => {
  const { username } = await c.req.json();
  const db = getDb();
  const me = getUserId(c);

  const target = await db.collection<User>("users").findOne({
    username: username?.toLowerCase(),
  });
  if (!target) return c.json({ error: "User not found" }, 404);
  if (target._id.equals(me)) return c.json({ error: "Cannot message yourself" }, 400);

  let convo = await db.collection<Conversation>("conversations").findOne({
    participants: { $all: [me, target._id], $size: 2 },
  });

  if (!convo) {
    const doc: Conversation = {
      _id: new ObjectId(),
      participants: [me, target._id],
      lastText: "",
      lastSenderId: null,
      lastMessageAt: new Date(),
      createdAt: new Date(),
    };
    await db.collection<Conversation>("conversations").insertOne(doc);
    convo = doc;
  }

  return c.json({ conversationId: convo._id });
});

// Get a conversation thread (partner + messages)
chat.get("/:id", async (c) => {
  const db = getDb();
  const me = getUserId(c);
  const cid = parseId(c.req.param("id"));
  if (!cid) return c.json({ error: "Invalid conversation id" }, 400);

  const convo = await db.collection<Conversation>("conversations").findOne({ _id: cid });
  if (!convo || !convo.participants.some((p) => p.equals(me))) {
    return c.json({ error: "Conversation not found" }, 404);
  }

  const pid = convo.participants.find((p) => !p.equals(me));
  const partner = pid ? await db.collection<User>("users").findOne({ _id: pid }) : null;

  const messages = await db
    .collection<Message>("messages")
    .find({ conversationId: cid })
    .sort({ createdAt: 1 })
    .limit(300)
    .toArray();

  return c.json({
    partner: partner ? toPublic(partner, me.toString()) : null,
    messages,
  });
});

// Poll messages, optionally only those after a timestamp
chat.get("/:id/messages", async (c) => {
  const db = getDb();
  const me = getUserId(c);
  const cid = parseId(c.req.param("id"));
  if (!cid) return c.json({ error: "Invalid conversation id" }, 400);

  const convo = await db.collection<Conversation>("conversations").findOne({ _id: cid });
  if (!convo || !convo.participants.some((p) => p.equals(me))) {
    return c.json({ error: "Conversation not found" }, 404);
  }

  const after = c.req.query("after");
  const filter: Record<string, unknown> = { conversationId: cid };
  if (after) {
    const d = new Date(after);
    if (!isNaN(d.getTime())) filter.createdAt = { $gt: d };
  }

  const messages = await db
    .collection<Message>("messages")
    .find(filter)
    .sort({ createdAt: 1 })
    .limit(100)
    .toArray();

  return c.json({ messages });
});

// Send a message
chat.post("/:id/messages", async (c) => {
  const db = getDb();
  const me = getUserId(c);
  const cid = parseId(c.req.param("id"));
  if (!cid) return c.json({ error: "Invalid conversation id" }, 400);

  const { text } = await c.req.json();
  if (!text?.trim()) return c.json({ error: "Message cannot be empty" }, 400);

  const convo = await db.collection<Conversation>("conversations").findOne({ _id: cid });
  if (!convo || !convo.participants.some((p) => p.equals(me))) {
    return c.json({ error: "Conversation not found" }, 404);
  }

  const message: Message = {
    _id: new ObjectId(),
    conversationId: cid,
    senderId: me,
    text: text.trim().slice(0, 2000),
    createdAt: new Date(),
  };

  await db.collection<Message>("messages").insertOne(message);
  await db.collection<Conversation>("conversations").updateOne(
    { _id: cid },
    {
      $set: {
        lastText: message.text,
        lastSenderId: me,
        lastMessageAt: message.createdAt,
      },
    }
  );

  return c.json({ message }, 201);
});

// Clear all messages in a conversation (for both participants)
chat.delete("/:id/messages", async (c) => {
  const db = getDb();
  const me = getUserId(c);
  const cid = parseId(c.req.param("id"));
  if (!cid) return c.json({ error: "Invalid conversation id" }, 400);

  const convo = await db.collection<Conversation>("conversations").findOne({ _id: cid });
  if (!convo || !convo.participants.some((p) => p.equals(me))) {
    return c.json({ error: "Conversation not found" }, 404);
  }

  await db.collection<Message>("messages").deleteMany({ conversationId: cid });
  await db.collection<Conversation>("conversations").updateOne(
    { _id: cid },
    { $set: { lastText: "", lastSenderId: null, lastMessageAt: new Date() } }
  );

  return c.json({ ok: true });
});

export { chat };
