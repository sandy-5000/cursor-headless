<script setup lang="ts">
import { computed } from "vue";
import {
  Home,
  Compass,
  Plus,
  User,
  MessageCircle,
  Settings,
  type LucideIcon,
} from "@lucide/vue";

const props = defineProps<{ name: string; iconClass?: string }>();

const icons: Record<string, LucideIcon> = {
  home: Home,
  compass: Compass,
  plus: Plus,
  user: User,
  chat: MessageCircle,
  settings: Settings,
};

const icon = computed(() => icons[props.name]);
</script>

<template>
  <component
    :is="icon"
    v-if="icon"
    :class="iconClass ?? 'w-5 h-5'"
    :stroke-width="1.75"
  />
</template>
