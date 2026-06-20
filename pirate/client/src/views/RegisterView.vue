<script setup lang="ts">
import { ref } from "vue";
import { useRouter, RouterLink } from "vue-router";
import PirateLogo from "@/components/PirateLogo.vue";
import { useAuthStore } from "@/stores/auth";
import { ApiError } from "@/api/client";

const auth = useAuthStore();
const router = useRouter();

const username = ref("");
const email = ref("");
const displayName = ref("");
const password = ref("");
const gender = ref<"female" | "male">("female");
const error = ref("");

async function submit() {
  error.value = "";
  try {
    await auth.register({
      username: username.value,
      email: email.value,
      password: password.value,
      displayName: displayName.value || undefined,
      gender: gender.value,
    });
    router.push("/");
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : "Registration failed";
  }
}
</script>

<template>
  <div class="relative flex min-h-screen items-center justify-center overflow-hidden bg-ink px-5 py-10">
    <div class="auth-orb -right-20 -top-20 h-[420px] w-[420px] bg-accent animate-orb-1" />
    <div class="auth-orb -bottom-24 -left-16 h-[360px] w-[360px] bg-accent-light animate-orb-2" />

    <div class="relative z-10 grid w-full max-w-5xl items-center gap-10 lg:grid-cols-2">
      <div class="hidden flex-col lg:flex animate-slide-up">
        <div class="mb-8 flex items-center gap-3">
          <PirateLogo class="h-12 w-12" />
          <span class="text-3xl font-extrabold tracking-tightest text-white">Pirate</span>
        </div>
        <h1 class="text-5xl font-extrabold leading-[1.05] tracking-tightest text-white">
          Join the<br />
          <span class="text-gradient">conversation.</span>
        </h1>
        <ul class="mt-8 space-y-4">
          <li class="flex items-center gap-3 text-[15px] text-zinc-400">
            <span class="flex h-6 w-6 items-center justify-center rounded-full bg-accent/15 text-xs text-accent-light">✓</span>
            A clean feed from people you follow
          </li>
          <li class="flex items-center gap-3 text-[15px] text-zinc-400">
            <span class="flex h-6 w-6 items-center justify-center rounded-full bg-accent/15 text-xs text-accent-light">✓</span>
            Share text and photos in seconds
          </li>
          <li class="flex items-center gap-3 text-[15px] text-zinc-400">
            <span class="flex h-6 w-6 items-center justify-center rounded-full bg-accent/15 text-xs text-accent-light">✓</span>
            Built for small, tight communities
          </li>
        </ul>
      </div>

      <div class="mx-auto w-full max-w-[400px] animate-scale-in">
        <div class="card-glow p-8">
          <div class="mb-6 flex items-center gap-3 lg:hidden">
            <PirateLogo class="h-10 w-10" />
            <span class="text-2xl font-extrabold tracking-tightest text-white">Pirate</span>
          </div>

          <h2 class="text-2xl font-extrabold tracking-tightest text-white">Create account</h2>
          <p class="mt-1.5 text-sm text-zinc-500">
            Have an account?
            <RouterLink to="/login" class="font-semibold text-accent-light hover:underline">Sign in</RouterLink>
          </p>

          <form class="mt-7 space-y-3.5" @submit.prevent="submit">
            <div>
              <label class="mb-1.5 block text-[13px] font-medium text-zinc-400">Username</label>
              <input v-model="username" type="text" autocomplete="username" class="input-field" placeholder="johndoe" minlength="3" required />
            </div>
            <div>
              <label class="mb-1.5 block text-[13px] font-medium text-zinc-400">Display name</label>
              <input v-model="displayName" type="text" class="input-field" placeholder="John Doe" />
            </div>
            <div>
              <label class="mb-1.5 block text-[13px] font-medium text-zinc-400">Gender</label>
              <div class="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  class="rounded-lg border px-4 py-2.5 text-sm font-semibold transition-all active:scale-[0.98]"
                  :class="gender === 'female'
                    ? 'border-accent bg-accent/10 text-white'
                    : 'border-line text-zinc-400 hover:border-zinc-600 hover:text-zinc-200'"
                  @click="gender = 'female'"
                >
                  Female
                </button>
                <button
                  type="button"
                  class="rounded-lg border px-4 py-2.5 text-sm font-semibold transition-all active:scale-[0.98]"
                  :class="gender === 'male'
                    ? 'border-accent bg-accent/10 text-white'
                    : 'border-line text-zinc-400 hover:border-zinc-600 hover:text-zinc-200'"
                  @click="gender = 'male'"
                >
                  Male
                </button>
              </div>
            </div>
            <div>
              <label class="mb-1.5 block text-[13px] font-medium text-zinc-400">Email</label>
              <input v-model="email" type="email" autocomplete="email" class="input-field" placeholder="you@email.com" required />
            </div>
            <div>
              <label class="mb-1.5 block text-[13px] font-medium text-zinc-400">Password</label>
              <input v-model="password" type="password" autocomplete="new-password" class="input-field" placeholder="Min 6 characters" minlength="6" required />
            </div>

            <p v-if="error" class="rounded-lg bg-like/10 px-3 py-2 text-sm text-like">{{ error }}</p>

            <button type="submit" class="btn-primary mt-1 w-full py-3" :disabled="auth.loading">
              {{ auth.loading ? "Creating..." : "Create account" }}
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
