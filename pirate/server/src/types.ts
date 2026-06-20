import { ObjectId } from "mongodb";

export interface User {
  _id: ObjectId;
  username: string;
  email: string;
  passwordHash: string;
  displayName: string;
  bio: string;
  avatar: string;
  gender: "female" | "male";
  followers: ObjectId[];
  following: ObjectId[];
  createdAt: Date;
}

export interface Comment {
  _id: ObjectId;
  userId: ObjectId;
  content: string;
  createdAt: Date;
}

export interface Post {
  _id: ObjectId;
  userId: ObjectId;
  content: string;
  imageUrl?: string;
  likes: ObjectId[];
  comments: Comment[];
  createdAt: Date;
}

export interface Conversation {
  _id: ObjectId;
  participants: ObjectId[];
  lastText: string;
  lastSenderId: ObjectId | null;
  lastMessageAt: Date;
  createdAt: Date;
}

export interface Message {
  _id: ObjectId;
  conversationId: ObjectId;
  senderId: ObjectId;
  text: string;
  createdAt: Date;
}

export type UserPublic = Omit<User, "passwordHash" | "email"> & {
  followerCount: number;
  followingCount: number;
  isFollowing?: boolean;
};

export type PostWithAuthor = Post & {
  author: UserPublic;
  liked: boolean;
  commentCount: number;
  likeCount: number;
};
