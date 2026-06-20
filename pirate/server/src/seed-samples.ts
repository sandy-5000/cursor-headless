import { ObjectId } from "mongodb";
import { connectDb, getDb } from "./db";
import { avatarUrl, type Gender } from "./avatar";
import type { User, Post, Conversation, Message } from "./types";

const PASSWORD = "pirate123";

const SAMPLE_USERS: { username: string; displayName: string; bio: string; gender: Gender }[] = [
  {
    username: "ada",
    displayName: "Ada Lovelace",
    bio: "Mathematician. Writing notes the machine will one day read. 📜",
    gender: "female",
  },
  {
    username: "blackbeard",
    displayName: "Edward Teach",
    bio: "Captain of the Queen Anne's Revenge. Smoke on, sails up. ⚓",
    gender: "male",
  },
  {
    username: "mira",
    displayName: "Mira Sol",
    bio: "Designer & cartographer. I draw maps to places that don't exist yet.",
    gender: "female",
  },
  {
    username: "kenji",
    displayName: "Kenji Watanabe",
    bio: "Building small things on the open sea of the web. Coffee → code.",
    gender: "male",
  },
  {
    username: "nova",
    displayName: "Nova Reyes",
    bio: "Photographer chasing light and storms. 🌊📷",
    gender: "female",
  },
  {
    username: "fin",
    displayName: "Fin O'Hara",
    bio: "Sound designer. Field recordings from harbors around the world.",
    gender: "male",
  },
];

type SamplePost = { author: string; content: string; image?: string; hoursAgo: number };

const SAMPLE_POSTS: SamplePost[] = [
  { author: "blackbeard", content: "Set sail at dawn. The horizon owes us nothing, so we take everything. ⚓🏴‍☠️", hoursAgo: 1, image: "ship-dawn" },
  { author: "mira", content: "New map sketch for an island that lives only in my notebook. Sometimes the best places aren't on any chart.", hoursAgo: 2, image: "old-map" },
  { author: "ada", content: "The Analytical Engine weaves algebraic patterns just as the Jacquard loom weaves flowers and leaves. We are only beginning.", hoursAgo: 3 },
  { author: "nova", content: "Caught the storm rolling in over the bay tonight. Three seconds of perfect light.", hoursAgo: 4, image: "storm-bay" },
  { author: "kenji", content: "Shipped a tiny feature today and it felt better than any big launch. Small + done > huge + someday.", hoursAgo: 6 },
  { author: "fin", content: "Recorded the harbor at 5am — gulls, rigging, a distant foghorn. Headphones recommended. 🎧", hoursAgo: 8, image: "harbor" },
  { author: "mira", content: "Color study: the exact teal of shallow water over white sand. Took me 40 swatches to get it right.", hoursAgo: 11, image: "teal-water" },
  { author: "blackbeard", content: "Rule of the crew: share the spoils, share the watch, share the blame. That's how a ship stays afloat.", hoursAgo: 14 },
  { author: "nova", content: "Golden hour at the lighthouse. No filter, just patience.", hoursAgo: 19, image: "lighthouse" },
  { author: "ada", content: "Spent the evening with poetry and prime numbers. Both are about finding the pattern hiding in plain sight.", hoursAgo: 23 },
  { author: "kenji", content: "Hot take: a good README is a love letter to your future self.", hoursAgo: 28 },
  { author: "fin", content: "Layered three ocean recordings into one track. Close your eyes and you're on the deck. 🌊", hoursAgo: 33, image: "ocean-deck" },
  { author: "mira", content: "Started a sketchbook tour series. First stop: harbor towns and their impossible blues.", hoursAgo: 40, image: "harbor-town" },
  { author: "nova", content: "Reminder: the storm always passes. Keep your lens dry and your eyes open.", hoursAgo: 47 },
];

const SAMPLE_CHATS: { with: string; messages: { from: "me" | "them"; text: string; minsAgo: number }[] }[] = [
  {
    with: "mira",
    messages: [
      { from: "them", text: "Hey! Loved your last post about the open sea ⚓", minsAgo: 90 },
      { from: "me", text: "Thanks Mira! Your maps are unreal, btw.", minsAgo: 84 },
      { from: "them", text: "Want to collab on an island map for the next voyage?", minsAgo: 80 },
      { from: "me", text: "Absolutely. Let's sketch something this weekend.", minsAgo: 12 },
    ],
  },
  {
    with: "kenji",
    messages: [
      { from: "them", text: "That small-feature post hit home today 😅", minsAgo: 240 },
      { from: "me", text: "Ha! Ship small, ship often. What are you building?", minsAgo: 235 },
      { from: "them", text: "A tiny chat app, actually. Funny enough.", minsAgo: 30 },
    ],
  },
];

function avatar(username: string, gender: Gender = "female") {
  return avatarUrl(username, gender);
}

function image(seed: string) {
  return `https://picsum.photos/seed/${seed}/900/650`;
}

await connectDb();
const db = getDb();

const users = db.collection<User>("users");
const posts = db.collection<Post>("posts");
const conversations = db.collection<Conversation>("conversations");
const messages = db.collection<Message>("messages");

// Ensure the demo user exists
let demo = await users.findOne({ username: "demo" });
if (!demo) {
  const doc: User = {
    _id: new ObjectId(),
    username: "demo",
    email: "demo@pirate.sea",
    passwordHash: await Bun.password.hash("demo123", { algorithm: "bcrypt", cost: 10 }),
    displayName: "Demo Captain",
    bio: "Ahoy! Exploring Pirate. Follow along. 🏴‍☠️",
    avatar: avatar("demo", "male"),
    gender: "male",
    followers: [],
    following: [],
    createdAt: new Date(),
  };
  await users.insertOne(doc);
  demo = doc;
  console.log("Created demo user (demo / demo123)");
}

// Skip if already seeded
if (await users.findOne({ username: SAMPLE_USERS[0].username })) {
  console.log("Sample users already exist — skipping seed.");
  console.log("To reseed, drop the users/posts/conversations/messages collections first.");
  process.exit(0);
}

const passwordHash = await Bun.password.hash(PASSWORD, { algorithm: "bcrypt", cost: 10 });

// Create sample users
const created: Record<string, User> = {};
for (const u of SAMPLE_USERS) {
  const doc: User = {
    _id: new ObjectId(),
    username: u.username,
    email: `${u.username}@pirate.sea`,
    passwordHash,
    displayName: u.displayName,
    bio: u.bio,
    avatar: avatar(u.username, u.gender),
    gender: u.gender,
    followers: [],
    following: [],
    createdAt: new Date(),
  };
  created[u.username] = doc;
}
await users.insertMany(Object.values(created));
console.log(`Created ${SAMPLE_USERS.length} sample users (password: ${PASSWORD})`);

// Build follow graph: demo <-> everyone, plus some cross-follows
const all = Object.values(created);
for (const u of all) {
  // demo follows everyone, everyone follows demo
  demo.following.push(u._id);
  u.followers.push(demo._id);
  u.following.push(demo._id);
  demo.followers.push(u._id);
  // each user follows the next two (ring)
  const others = all.filter((o) => !o._id.equals(u._id));
  for (let i = 0; i < 2; i++) {
    const target = others[(all.indexOf(u) + i + 1) % others.length];
    if (target && !u.following.some((f) => f.equals(target._id))) {
      u.following.push(target._id);
      target.followers.push(u._id);
    }
  }
}

// Persist follow updates
await users.updateOne(
  { _id: demo._id },
  { $set: { following: demo.following, followers: demo.followers } }
);
for (const u of all) {
  await users.updateOne(
    { _id: u._id },
    { $set: { following: u.following, followers: u.followers } }
  );
}

// Create posts
const now = Date.now();
const postDocs: Post[] = SAMPLE_POSTS.map((p) => ({
  _id: new ObjectId(),
  userId: created[p.author]._id,
  content: p.content,
  imageUrl: p.image ? image(p.image) : undefined,
  likes: all
    .filter(() => Math.random() > 0.45)
    .map((u) => u._id)
    .concat(Math.random() > 0.5 ? [demo._id] : []),
  comments: [],
  createdAt: new Date(now - p.hoursAgo * 3600 * 1000),
}));

// Sprinkle a few comments
const commenters = all.concat(demo);
for (const post of postDocs) {
  const n = Math.floor(Math.random() * 3);
  for (let i = 0; i < n; i++) {
    const c = commenters[Math.floor(Math.random() * commenters.length)];
    post.comments.push({
      _id: new ObjectId(),
      userId: c._id,
      content: ["This is gold ⚓", "Saving this!", "So good.", "Take my anchor 🏴‍☠️", "Need more of this."][
        Math.floor(Math.random() * 5)
      ],
      createdAt: new Date(post.createdAt.getTime() + (i + 1) * 60000),
    });
  }
}
await posts.insertMany(postDocs);
console.log(`Created ${postDocs.length} sample posts`);

// Create conversations + messages with the demo user
let chatCount = 0;
let msgCount = 0;
for (const chat of SAMPLE_CHATS) {
  const partner = created[chat.with];
  if (!partner) continue;
  const convoId = new ObjectId();
  let last = chat.messages[chat.messages.length - 1];
  const convo: Conversation = {
    _id: convoId,
    participants: [demo._id, partner._id],
    lastText: last.text,
    lastSenderId: last.from === "me" ? demo._id : partner._id,
    lastMessageAt: new Date(now - last.minsAgo * 60000),
    createdAt: new Date(now - chat.messages[0].minsAgo * 60000),
  };
  await conversations.insertOne(convo);
  chatCount++;

  const msgs: Message[] = chat.messages.map((m) => ({
    _id: new ObjectId(),
    conversationId: convoId,
    senderId: m.from === "me" ? demo._id : partner._id,
    text: m.text,
    createdAt: new Date(now - m.minsAgo * 60000),
  }));
  await messages.insertMany(msgs);
  msgCount += msgs.length;
}
console.log(`Created ${chatCount} conversations with ${msgCount} messages`);

console.log("\nSeed complete! Log in as:");
console.log("  demo / demo123   (has feed, follows, and chats)");
console.log(`  ada / ${PASSWORD}   (or any sample username)`);

process.exit(0);
