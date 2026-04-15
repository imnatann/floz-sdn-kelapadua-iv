<template>
  <div class="flex flex-col items-center justify-center py-12 text-center">
    <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-3xl">
      {{ icon }}
    </div>
    <h3 class="text-sm font-semibold text-slate-700">{{ title }}</h3>
    <p class="mt-1 max-w-sm text-xs text-slate-400">{{ description }}</p>
    <div v-if="$slots.action" class="mt-4">
      <slot name="action" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  icon:        { type: String, default: '📋' },
  title:       { type: String, default: 'Belum ada data' },
  description: { type: String, default: '' },
});
</script>
