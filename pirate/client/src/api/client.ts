import type { User, Post, Conversation, Message } from "@/types";

const TOKEN_KEY = "pirate_token";

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number
  ) {
    super(message);
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string>),
  };

  if (!(options.body instanceof FormData)) {
    headers["Content-Type"] = "application/json";
  }

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const res = await fetch(path, { ...options, headers });
  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    throw new ApiError(data.error || "Something went wrong", res.status);
  }

  return data as T;
}

export const api = {
  register: (body: {
    username: string;
    email: string;
    password: string;
    displayName?: string;
    gender?: "female" | "male";
  }) =>
    request<{ token: string; user: User }>("/api/auth/register", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  login: (body: { login: string; password: string }) =>
    request<{ token: string; user: User }>("/api/auth/login", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  me: () => request<{ user: User }>("/api/auth/me"),

  feed: (page = 1) =>
    request<{ posts: Post[]; page: number; hasMore: boolean }>(
      `/api/posts/feed?page=${page}`
    ),

  explore: (page = 1) =>
    request<{ posts: Post[]; page: number; hasMore: boolean }>(
      `/api/posts/explore?page=${page}`
    ),

  getPost: (id: string) => request<{ post: Post }>(`/api/posts/${id}`),

  createPost: (body: { content: string; imageUrl?: string }) =>
    request<{ post: Post }>("/api/posts", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  toggleLike: (id: string) =>
    request<{ post: Post }>(`/api/posts/${id}/like`, {
      method: "POST",
    }),

  addComment: (id: string, content: string) =>
    request<{ post: Post }>(`/api/posts/${id}/comments`, {
      method: "POST",
      body: JSON.stringify({ content }),
    }),

  deletePost: (id: string) =>
    request<{ ok: boolean }>(`/api/posts/${id}`, { method: "DELETE" }),

  getUser: (username: string) =>
    request<{ user: User; posts: Post[] }>(`/api/users/${username}`),

  searchUsers: (q: string) =>
    request<{ users: User[] }>(`/api/users/search?q=${encodeURIComponent(q)}`),

  suggestedUsers: () => request<{ users: User[] }>("/api/users/suggested"),

  followUser: (username: string) =>
    request<{ user: User }>(`/api/users/${username}/follow`, {
      method: "POST",
    }),

  generateAvatar: (gender: "female" | "male") =>
    request<{ avatar: string }>(`/api/users/avatar/generate?gender=${gender}`),

  updateProfile: (body: {
    displayName?: string;
    bio?: string;
    avatar?: string;
    gender?: "female" | "male";
  }) =>
    request<{ user: User }>("/api/users/me", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  uploadImage: (file: File) => {
    const form = new FormData();
    form.append("file", file);
    return request<{ url: string }>("/api/upload", {
      method: "POST",
      body: form,
    });
  },

  conversations: () =>
    request<{ conversations: Conversation[] }>("/api/chat/conversations"),

  startConversation: (username: string) =>
    request<{ conversationId: string }>("/api/chat/start", {
      method: "POST",
      body: JSON.stringify({ username }),
    }),

  conversation: (id: string) =>
    request<{ partner: User | null; messages: Message[] }>(`/api/chat/${id}`),

  newMessages: (id: string, after?: string) =>
    request<{ messages: Message[] }>(
      `/api/chat/${id}/messages${after ? `?after=${encodeURIComponent(after)}` : ""}`
    ),

  sendMessage: (id: string, text: string) =>
    request<{ message: Message }>(`/api/chat/${id}/messages`, {
      method: "POST",
      body: JSON.stringify({ text }),
    }),

  clearChat: (id: string) =>
    request<{ ok: boolean }>(`/api/chat/${id}/messages`, { method: "DELETE" }),
};
