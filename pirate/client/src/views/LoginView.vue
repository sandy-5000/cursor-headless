<script setup lang="ts">
import { ref } from "vue";
import { useRouter, useRoute, RouterLink } from "vue-router";
import PirateLogo from "@/components/PirateLogo.vue";
import { useAuthStore } from "@/stores/auth";
import { ApiError } from "@/api/client";

const auth = useAuthStore();
const router = useRouter();
const route = useRoute();

const login = ref("");
const password = ref("");
const error = ref("");

async function submit() {
  error.value = "";
  try {
    await auth.login(login.value, password.value);
    router.push((route.query.redirect as string) || "/");
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : "Login failed";
  }
}

function fillDemo() {
  login.value = "demo";
  password.value = "demo123";
}
</script>

<template>
  <div class="relative flex min-h-screen items-center justify-center overflow-hidden bg-ink px-5 py-10">
    <div class="auth-orb -left-20 -top-20 h-[420px] w-[420px] bg-accent animate-orb-1" />
    <div class="auth-orb -bottom-24 -right-16 h-[380px] w-[380px] bg-accent-light animate-orb-2" />

    <div class="relative z-10 grid w-full max-w-5xl items-center gap-10 lg:grid-cols-2">
      <!-- Brand -->
      <div class="hidden flex-col lg:flex animate-slide-up">
        <div class="mb-8 flex items-center gap-3">
          <PirateLogo class="h-12 w-12" />
          <span class="text-3xl font-extrabold tracking-tightest text-white">Pirate</span>
        </div>
        <h1 class="text-5xl font-extrabold leading-[1.05] tracking-tightest text-white">
          Where your<br />
          <span class="text-gradient">crew connects.</span>
        </h1>
        <p class="mt-6 max-w-sm text-[15px] leading-relaxed text-zinc-500">
          A calm, beautiful space for small communities. No noise, no ads — just the people you care about.
        </p>
      </div>

      <!-- Form -->
      <div class="mx-auto w-full max-w-[400px] animate-scale-in">
        <div class="card-glow p-8">
          <div class="mb-6 flex items-center gap-3 lg:hidden">
            <PirateLogo class="h-10 w-10" />
            <span class="text-2xl font-extrabold tracking-tightest text-white">Pirate</span>
          </div>

          <h2 class="text-2xl font-extrabold tracking-tightest text-white">Welcome back</h2>
          <p class="mt-1.5 text-sm text-zinc-500">
            New here?
            <RouterLink to="/register" class="font-semibold text-accent-light hover:underline">
              Create account
            </RouterLink>
          </p>

          <form class="mt-7 space-y-4" @submit.prevent="submit">
            <div>
              <label class="mb-1.5 block text-[13px] font-medium text-zinc-400">Username or email</label>
              <input v-model="login" type="text" autocomplete="username" class="input-field" placeholder="demo" required />
            </div>

            <div>
              <label class="mb-1.5 block text-[13px] font-medium text-zinc-400">Password</label>
              <input v-model="password" type="password" autocomplete="current-password" class="input-field" placeholder="••••••••" required />
            </div>

            <p v-if="error" class="rounded-lg bg-like/10 px-3 py-2 text-sm text-like">{{ error }}</p>

            <button type="submit" class="btn-primary mt-1 w-full py-3" :disabled="auth.loading">
              {{ auth.loading ? "Signing in..." : "Sign in" }}
            </button>
          </form>

          <button
            class="mt-3 w-full rounded-lg border border-dashed border-line py-2.5 text-[13px] font-medium text-zinc-500 transition-colors hover:border-accent/50 hover:text-accent-light"
            @click="fillDemo"
          >
            Try the demo account
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
