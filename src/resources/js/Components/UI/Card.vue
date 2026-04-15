<template>
  <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
    <!-- Header -->
    <div v-if="title || $slots.header" class="flex items-center justify-between border-b border-slate-100 px-5 py-3.5">
      <div v-if="title">
        <h3 class="text-sm font-semibold text-slate-800">{{ title }}</h3>
        <p v-if="subtitle" class="mt-0.5 text-xs text-slate-400">{{ subtitle }}</p>
      </div>
      <slot name="header" />
      <slot name="header-actions" />
    </div>

    <!-- Body -->
    <div :class="[noPadding ? '' : 'p-5']">
      <slot />
    </div>

    <!-- Footer -->
    <div v-if="$slots.footer" class="border-t border-slate-100 px-5 py-3">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  title:     { type: String, default: '' },
  subtitle:  { type: String, default: '' },
  noPadding: { type: Boolean, default: false },
});
</script>
