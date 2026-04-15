<template>
  <div
    :class="[
      'group relative overflow-hidden rounded-xl border bg-white p-5 transition-all duration-200',
      'hover:shadow-md hover:-translate-y-0.5',
      borderColor,
    ]"
  >
    <div class="flex items-start justify-between">
      <div class="space-y-1">
        <p class="text-xs font-medium uppercase tracking-wider text-slate-400">{{ label }}</p>
        <p class="text-2xl font-bold text-slate-800">{{ value }}</p>
        <p v-if="subtitle" class="text-xs text-slate-400">{{ subtitle }}</p>
      </div>
      <div
        :class="[
          'flex h-11 w-11 shrink-0 items-center justify-center rounded-lg text-xl',
          iconBg,
        ]"
      >
        <span>{{ icon }}</span>
      </div>
    </div>
    <!-- Accent Bar -->
    <div :class="['absolute bottom-0 left-0 h-0.5 w-full transition-all', accentBar]" />
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  label:    { type: String, required: true },
  value:    { type: [String, Number], required: true },
  icon:     { type: String, default: '📊' },
  color:    { type: String, default: 'orange' },
  subtitle: { type: String, default: '' },
});

const colorMap = {
  orange:  { border: 'border-orange-100', bg: 'bg-orange-50 text-orange-600', bar: 'bg-orange-500 group-hover:bg-orange-600' },
  blue:    { border: 'border-blue-100',   bg: 'bg-blue-50 text-blue-600',     bar: 'bg-blue-500 group-hover:bg-blue-600' },
  green:   { border: 'border-emerald-100',bg: 'bg-emerald-50 text-emerald-600',bar: 'bg-emerald-500 group-hover:bg-emerald-600' },
  purple:  { border: 'border-purple-100', bg: 'bg-purple-50 text-purple-600', bar: 'bg-purple-500 group-hover:bg-purple-600' },
  yellow:  { border: 'border-amber-100',  bg: 'bg-amber-50 text-amber-600',   bar: 'bg-amber-500 group-hover:bg-amber-600' },
  rose:    { border: 'border-rose-100',   bg: 'bg-rose-50 text-rose-600',     bar: 'bg-rose-500 group-hover:bg-rose-600' },
};

const borderColor = computed(() => colorMap[props.color]?.border || colorMap.orange.border);
const iconBg      = computed(() => colorMap[props.color]?.bg || colorMap.orange.bg);
const accentBar   = computed(() => colorMap[props.color]?.bar || colorMap.orange.bar);
</script>
