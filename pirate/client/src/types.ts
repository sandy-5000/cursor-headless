export interface User {
  _id: string;
  username: string;
  displayName: string;
  bio: string;
  avatar: string;
  gender?: "female" | "male";
  followerCount: number;
  followingCount: number;
  isFollowing?: boolean;
  createdAt: string;
}

export interface Comment {
  _id: string;
  userId: string;
  content: string;
  createdAt: string;
}

export interface Post {
  _id: string;
  userId: string;
  content: string;
  imageUrl?: string;
  likes: string[];
  comments: Comment[];
  createdAt: string;
  author: User;
  liked: boolean;
  likeCount: number;
  commentCount: number;
}

export interface Message {
  _id: string;
  conversationId: string;
  senderId: string;
  text: string;
  createdAt: string;
}

export interface Conversation {
  _id: string;
  partner: User;
  lastText: string;
  lastSenderId: string | null;
  lastMessageAt: string;
}
