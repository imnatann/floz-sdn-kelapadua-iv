<template>
  <span
    :class="[
      'inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold ring-1 ring-inset',
      variantClasses,
    ]"
  >
    <span v-if="dot" :class="['h-1.5 w-1.5 rounded-full', dotColor]" />
    <slot />
  </span>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  variant: { type: String, default: 'default' },
  dot:     { type: Boolean, default: false },
});

const variants = {
  default:  'bg-slate-50 text-slate-600 ring-slate-200',
  success:  'bg-emerald-50 text-emerald-700 ring-emerald-200',
  warning:  'bg-amber-50 text-amber-700 ring-amber-200',
  danger:   'bg-red-50 text-red-700 ring-red-200',
  info:     'bg-blue-50 text-blue-700 ring-blue-200',
  orange:   'bg-orange-50 text-orange-700 ring-orange-200',
  purple:   'bg-purple-50 text-purple-700 ring-purple-200',
};

const dots = {
  default:  'bg-slate-400',
  success:  'bg-emerald-500',
  warning:  'bg-amber-500',
  danger:   'bg-red-500',
  info:     'bg-blue-500',
  orange:   'bg-orange-500',
  purple:   'bg-purple-500',
};

const variantClasses = computed(() => variants[props.variant] || variants.default);
const dotColor       = computed(() => dots[props.variant] || dots.default);
</script>
