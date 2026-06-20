<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from "vue";
import { useRoute, RouterLink } from "vue-router";
import AppLayout from "@/layouts/AppLayout.vue";
import UserAvatar from "@/components/UserAvatar.vue";
import EmptyState from "@/components/EmptyState.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { api } from "@/api/client";
import type { Conversation, Message, User } from "@/types";
import { useAuthStore } from "@/stores/auth";
import { MessagesSquare, ArrowLeft, Send, Trash2 } from "@lucide/vue";

const route = useRoute();
const auth = useAuthStore();

const conversations = ref<Conversation[]>([]);
const loadingList = ref(true);

const activeId = computed(() => (route.params.id as string) || "");
const partner = ref<User | null>(null);
const messages = ref<Message[]>([]);
const loadingThread = ref(false);
const draft = ref("");
const sending = ref(false);
const threadEl = ref<HTMLElement | null>(null);

let pollTimer: ReturnType<typeof setInterval> | null = null;

const myId = computed(() => auth.user?._id);

function fmtTime(d: string) {
  return new Date(d).toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
}

function fmtPreviewTime(d: string) {
  const diff = Date.now() - new Date(d).getTime();
  if (diff < 60000) return "now";
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h`;
  return new Date(d).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

async function loadConversations() {
  try {
    const { conversations: list } = await api.conversations();
    conversations.value = list;
  } finally {
    loadingList.value = false;
  }
}

async function scrollToBottom(smooth = false) {
  await nextTick();
  threadEl.value?.scrollTo({
    top: threadEl.value.scrollHeight,
    behavior: smooth ? "smooth" : "auto",
  });
}

async function openThread(id: string) {
  loadingThread.value = true;
  messages.value = [];
  partner.value = null;
  try {
    const res = await api.conversation(id);
    partner.value = res.partner;
    messages.value = res.messages;
    await scrollToBottom();
  } finally {
    loadingThread.value = false;
  }
}

async function poll() {
  if (!activeId.value) {
    loadConversations();
    return;
  }
  const last = messages.value[messages.value.length - 1]?.createdAt;
  try {
    const { messages: fresh } = await api.newMessages(activeId.value, last);
    if (fresh.length) {
      const seen = new Set(messages.value.map((m) => m._id));
      const toAdd = fresh.filter((m) => !seen.has(m._id));
      if (toAdd.length) {
        const nearBottom =
          threadEl.value &&
          threadEl.value.scrollHeight - threadEl.value.scrollTop - threadEl.value.clientHeight < 120;
        messages.value.push(...toAdd);
        if (nearBottom) scrollToBottom(true);
      }
    }
  } catch {
    /* ignore transient */
  }
}

const showClearConfirm = ref(false);
const clearing = ref(false);

function clearChat() {
  if (!activeId.value) return;
  showClearConfirm.value = true;
}

async function confirmClear() {
  if (!activeId.value) return;
  clearing.value = true;
  try {
    await api.clearChat(activeId.value);
    messages.value = [];
    loadConversations();
    showClearConfirm.value = false;
  } catch {
    /* ignore */
  } finally {
    clearing.value = false;
  }
}

async function send() {
  const text = draft.value.trim();
  if (!text || !activeId.value || sending.value) return;
  sending.value = true;
  draft.value = "";
  try {
    const { message } = await api.sendMessage(activeId.value, text);
    messages.value.push(message);
    await scrollToBottom(true);
    loadConversations();
  } catch {
    draft.value = text;
  } finally {
    sending.value = false;
  }
}

watch(
  activeId,
  (id) => {
    if (id) openThread(id);
    else {
      partner.value = null;
      messages.value = [];
    }
  },
  { immediate: true }
);

onMounted(() => {
  loadConversations();
  pollTimer = setInterval(poll, 3000);
});

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer);
});
</script>

<template>
  <AppLayout flush>
    <div class="flex h-full">
      <!-- Conversation list -->
      <div
        class="flex w-full flex-col border-r border-line/60 bg-surface md:w-[320px] lg:w-[360px] shrink-0"
        :class="activeId ? 'hidden md:flex' : 'flex'"
      >
        <header
          class="sticky-header px-4 pb-3.5"
          style="padding-top: calc(env(safe-area-inset-top, 0px) + 1.25rem)"
        >
          <h1 class="text-[20px] font-extrabold tracking-tightest text-white">Messages</h1>
          <p class="text-[13px] text-zinc-500">Your private conversations</p>
        </header>

        <div class="flex-1 overflow-y-auto">
          <div v-if="loadingList" class="space-y-1 p-2">
            <div v-for="i in 6" :key="i" class="flex items-center gap-3 rounded-lg p-3">
              <div class="h-12 w-12 rounded-full bg-surface-3" />
              <div class="flex-1 space-y-2">
                <div class="h-3 w-28 rounded-full bg-surface-3" />
                <div class="h-2.5 w-40 rounded-full bg-surface-3/70" />
              </div>
            </div>
          </div>

          <div v-else-if="!conversations.length" class="px-6 py-14 text-center">
            <p class="text-sm text-zinc-500">
              No conversations yet. Open someone's profile and tap
              <span class="text-zinc-300">Message</span> to start chatting.
            </p>
          </div>

          <RouterLink
            v-for="cv in conversations"
            :key="cv._id"
            :to="`/messages/${cv._id}`"
            class="flex items-center gap-3 px-3 py-3 transition-colors hover:bg-white/[0.03]"
            :class="cv._id === activeId ? 'bg-white/[0.05]' : ''"
          >
            <UserAvatar :src="cv.partner.avatar" :alt="cv.partner.displayName" size="lg" class="!h-12 !w-12" />
            <div class="min-w-0 flex-1">
              <div class="flex items-center justify-between gap-2">
                <span class="truncate font-semibold text-white">{{ cv.partner.displayName }}</span>
                <span class="shrink-0 text-xs text-zinc-600">{{ fmtPreviewTime(cv.lastMessageAt) }}</span>
              </div>
              <p class="truncate text-sm text-zinc-500">
                <span v-if="cv.lastSenderId === myId" class="text-zinc-600">You: </span>
                {{ cv.lastText || "Say hi 👋" }}
              </p>
            </div>
          </RouterLink>
        </div>
      </div>

      <!-- Thread -->
      <div class="flex min-w-0 flex-1 flex-col bg-surface-1" :class="activeId ? 'flex' : 'hidden md:flex'">
        <template v-if="!activeId">
          <div class="flex h-full items-center justify-center">
            <EmptyState
              title="Your messages"
              description="Pick a conversation on the left, or message someone from their profile."
            >
              <template #icon>
                <MessagesSquare class="h-7 w-7 text-accent-light" :stroke-width="1.5" />
              </template>
            </EmptyState>
          </div>
        </template>

        <template v-else>
          <!-- Thread header -->
          <header
            class="sticky-header flex items-center gap-3 px-3 pb-2.5 sm:px-4"
            style="padding-top: calc(env(safe-area-inset-top, 0px) + 0.8rem)"
          >
            <RouterLink to="/messages" class="rounded-lg p-2 text-zinc-400 hover:bg-white/5 hover:text-white md:hidden">
              <ArrowLeft class="h-5 w-5" :stroke-width="2" />
            </RouterLink>
            <RouterLink
              v-if="partner"
              :to="`/profile/${partner.username}`"
              class="flex min-w-0 items-center gap-3"
            >
              <UserAvatar :src="partner.avatar" :alt="partner.displayName" size="sm" />
              <div class="min-w-0">
                <p class="truncate font-semibold leading-tight text-white">{{ partner.displayName }}</p>
                <p class="truncate text-xs text-zinc-500">@{{ partner.username }}</p>
              </div>
            </RouterLink>

            <button
              v-if="partner && messages.length"
              class="ml-auto shrink-0 rounded-lg p-2 text-zinc-400 transition-colors hover:bg-like/10 hover:text-like"
              title="Clear chat"
              @click="clearChat"
            >
              <Trash2 class="h-5 w-5" :stroke-width="2" />
            </button>
          </header>

          <!-- Messages -->
          <div ref="threadEl" class="flex-1 overflow-y-auto px-4 py-5 sm:px-6">
            <div v-if="loadingThread" class="space-y-3">
              <div v-for="i in 5" :key="i" class="flex" :class="i % 2 ? 'justify-start' : 'justify-end'">
                <div class="h-9 w-44 rounded-lg bg-surface-3" />
              </div>
            </div>

            <div v-else class="flex flex-col gap-1">
              <template v-for="(m, idx) in messages" :key="m._id">
                <div
                  class="flex"
                  :class="m.senderId === myId ? 'justify-end' : 'justify-start'"
                >
                  <div
                    class="max-w-[78%] rounded-lg px-4 py-2.5 text-[15px] leading-snug shadow-soft"
                    :class="
                      m.senderId === myId
                        ? 'rounded-br-md bg-accent text-white'
                        : 'rounded-bl-md bg-surface-3 text-zinc-100'
                    "
                  >
                    <p class="whitespace-pre-wrap break-words">{{ m.text }}</p>
                    <p
                      class="mt-1 text-[10px]"
                      :class="m.senderId === myId ? 'text-white/60' : 'text-zinc-500'"
                    >
                      {{ fmtTime(m.createdAt) }}
                    </p>
                  </div>
                </div>
                <div
                  v-if="idx === messages.length - 1"
                  class="h-1"
                />
              </template>

              <div v-if="!messages.length" class="py-16 text-center text-sm text-zinc-600">
                No messages yet — send the first one.
              </div>
            </div>
          </div>

          <!-- Composer -->
          <div class="border-t border-line/60 bg-surface px-3 py-3 sm:px-4 safe-bottom">
            <form class="flex items-end gap-2" @submit.prevent="send">
              <textarea
                v-model="draft"
                rows="1"
                placeholder="Message..."
                class="input-field max-h-32 flex-1 resize-none py-2.5"
                @keydown.enter.exact.prevent="send"
              />
              <button
                type="submit"
                class="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-accent text-white transition-all hover:bg-accent-light active:scale-90 disabled:opacity-40"
                :disabled="!draft.trim() || sending"
              >
                <Send class="h-5 w-5" :stroke-width="2" />
              </button>
            </form>
          </div>
        </template>
      </div>
    </div>

    <ConfirmDialog
      :open="showClearConfirm"
      title="Clear chat?"
      message="This permanently deletes all messages in this conversation for both of you. This can't be undone."
      confirm-text="Clear chat"
      destructive
      :busy="clearing"
      @confirm="confirmClear"
      @cancel="showClearConfirm = false"
    />
  </AppLayout>
</template>
