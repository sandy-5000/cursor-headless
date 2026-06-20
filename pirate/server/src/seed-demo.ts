import { ObjectId } from "mongodb";
import { connectDb, getDb } from "./db";
import { avatarUrl } from "./avatar";
import type { User } from "./types";

const DEMO_USER = {
  username: "demo",
  email: "demo@pirate.sea",
  password: "demo123",
  displayName: "Demo Captain",
  bio: "Ahoy! This is a demo account for testing Pirate.",
};

await connectDb();
const db = getDb();

const existing = await db.collection<User>("users").findOne({
  username: DEMO_USER.username,
});

if (existing) {
  console.log("Demo user already exists — skipping seed");
  console.log(`  Login: ${DEMO_USER.username} (or ${DEMO_USER.email})`);
  console.log(`  Password: ${DEMO_USER.password}`);
  process.exit(0);
}

const passwordHash = await Bun.password.hash(DEMO_USER.password, {
  algorithm: "bcrypt",
  cost: 10,
});

const user: User = {
  _id: new ObjectId(),
  username: DEMO_USER.username,
  email: DEMO_USER.email,
  passwordHash,
  displayName: DEMO_USER.displayName,
  bio: DEMO_USER.bio,
  avatar: avatarUrl(DEMO_USER.username, "male"),
  gender: "male",
  followers: [],
  following: [],
  createdAt: new Date(),
};

await db.collection<User>("users").insertOne(user);

console.log("Demo user created!");
console.log(`  Login: ${DEMO_USER.username} (or ${DEMO_USER.email})`);
console.log(`  Password: ${DEMO_USER.password}`);

process.exit(0);
