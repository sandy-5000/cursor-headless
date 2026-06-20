<script setup lang="ts">
import { computed } from "vue";
import { useRoute, RouterLink } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import PirateLogo from "@/components/PirateLogo.vue";
import NavIcon from "@/components/NavIcon.vue";
import { LogOut } from "@lucide/vue";

const props = defineProps<{ flush?: boolean }>();

const route = useRoute();
const auth = useAuthStore();

const navItems = computed(() => [
  { name: "home", to: "/", label: "Home", icon: "home" },
  { name: "explore", to: "/explore", label: "Explore", icon: "compass" },
  { name: "messages", to: "/messages", label: "Messages", icon: "chat" },
  {
    name: "profile",
    to: auth.user ? `/profile/${auth.user.username}` : "/login",
    label: "Profile",
    icon: "user",
  },
]);

function isActive(name: string) {
  if (name === "home") return route.name === "home";
  if (name === "messages") return route.name === "messages" || route.name === "conversation";
  if (name === "profile") return route.name === "profile" || route.name === "settings";
  return route.name === name;
}

const mainClass = computed(() =>
  props.flush
    ? "flex-1 min-w-0 h-[calc(100svh-3.5rem)] lg:h-screen overflow-hidden"
    : "flex-1 min-w-0 border-x border-line/60 bg-surface min-h-screen pb-20 lg:pb-0"
);

const hideBottomNav = computed(
  () => route.name === "messages" || route.name === "conversation"
);
</script>

<template>
  <div class="min-h-screen bg-ink">
    <!-- Mobile header -->
    <header
      class="lg:hidden sticky top-0 z-40 flex items-center justify-between border-b border-line/60 bg-ink/80 px-4 py-3 backdrop-blur-2xl safe-top"
    >
      <RouterLink to="/" class="flex items-center gap-2">
        <PirateLogo class="h-8 w-8" />
        <span class="text-lg font-extrabold tracking-tightest text-white">Pirate</span>
      </RouterLink>
      <RouterLink v-if="auth.isLoggedIn" to="/compose" class="btn-accent px-4 py-1.5 text-sm">
        Post
      </RouterLink>
      <RouterLink v-else to="/login" class="btn-secondary px-4 py-1.5 text-sm">Sign in</RouterLink>
    </header>

    <div class="mx-auto flex w-full">
      <!-- Left rail -->
      <aside
        class="hidden lg:flex w-[240px] xl:w-[270px] shrink-0 flex-col sticky top-0 h-screen px-3 py-5"
      >
        <RouterLink to="/" class="mb-6 flex items-center gap-2.5 px-3 group">
          <PirateLogo class="h-9 w-9 transition-transform duration-300 group-hover:rotate-[-6deg]" />
          <span class="text-[22px] font-extrabold tracking-tightest text-white">Pirate</span>
        </RouterLink>

        <nav class="flex flex-col gap-1">
          <RouterLink
            v-for="item in navItems"
            :key="item.name"
            :to="item.to"
            class="nav-item"
            :class="{ 'nav-item-active': isActive(item.name) }"
          >
            <NavIcon :name="item.icon" icon-class="w-[23px] h-[23px]" />
            <span>{{ item.label }}</span>
          </RouterLink>

          <RouterLink
            v-if="auth.isLoggedIn"
            to="/settings"
            class="nav-item"
            :class="{ 'nav-item-active': route.name === 'settings' }"
          >
            <NavIcon name="settings" icon-class="w-[23px] h-[23px]" />
            <span>Settings</span>
          </RouterLink>
        </nav>

        <RouterLink v-if="auth.isLoggedIn" to="/compose" class="btn-accent mt-5 w-full py-3">
          New post
        </RouterLink>
        <RouterLink v-else to="/register" class="btn-primary mt-5 w-full py-3">
          Get started
        </RouterLink>

        <div v-if="auth.user" class="mt-auto">
          <div class="card flex items-center gap-3 p-2.5">
            <img
              :src="auth.user.avatar"
              :alt="auth.user.displayName"
              class="h-10 w-10 rounded-full object-cover ring-1 ring-line"
            />
            <div class="min-w-0 flex-1">
              <p class="truncate text-sm font-semibold text-white">{{ auth.user.displayName }}</p>
              <p class="truncate text-xs text-zinc-500">@{{ auth.user.username }}</p>
            </div>
            <button
              class="rounded-lg p-2 text-zinc-500 transition-colors hover:bg-white/5 hover:text-zinc-200"
              title="Sign out"
              @click="auth.logout(); $router.push('/login')"
            >
              <LogOut class="h-[18px] w-[18px]" :stroke-width="2" />
            </button>
          </div>
        </div>
      </aside>

      <!-- Main content fills remaining width -->
      <main :class="mainClass">
        <slot />
      </main>

      <!-- Right rail (only when a page provides one) -->
      <aside
        v-if="$slots.sidebar"
        class="hidden xl:flex w-[340px] shrink-0 flex-col sticky top-0 h-screen overflow-y-auto px-5 py-5"
      >
        <slot name="sidebar" />
      </aside>
    </div>

    <!-- Mobile bottom nav -->
    <nav
      v-if="!hideBottomNav"
      class="lg:hidden fixed bottom-0 inset-x-0 z-50 border-t border-line/60 bg-ink/85 backdrop-blur-2xl safe-bottom"
    >
      <div class="flex items-center justify-around px-1 pt-1.5 pb-1">
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          :to="item.to"
          class="flex flex-col items-center rounded-lg px-4 py-2 transition-colors"
          :class="isActive(item.name) ? 'text-white' : 'text-zinc-600'"
        >
          <NavIcon :name="item.icon" icon-class="w-[25px] h-[25px]" />
        </RouterLink>

        <RouterLink
          to="/compose"
          class="-mt-5 flex h-12 w-12 items-center justify-center rounded-lg bg-accent text-white shadow-fab transition-transform active:scale-90"
        >
          <NavIcon name="plus" icon-class="w-6 h-6" />
        </RouterLink>
      </div>
    </nav>
  </div>
</template>
