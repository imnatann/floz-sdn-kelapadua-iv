<template>
  <component
    :is="href ? Link : 'button'"
    :href="href"
    :type="href ? undefined : type"
    :disabled="loading || disabled"
    :class="[
      'inline-flex items-center justify-center gap-2 font-medium transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-offset-1',
      sizeClasses,
      variantClasses,
      { 'pointer-events-none opacity-60': loading || disabled },
      'rounded-lg',
    ]"
  >
    <!-- Loading Spinner -->
    <svg v-if="loading" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
    </svg>
    <slot />
  </component>
</template>

<script setup>
import { computed } from 'vue';
import { Link } from '@inertiajs/vue3';

const props = defineProps({
  variant:  { type: String, default: 'primary' },
  size:     { type: String, default: 'md' },
  href:     { type: String, default: '' },
  type:     { type: String, default: 'button' },
  loading:  { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
});

const sizes = {
  xs: 'px-2.5 py-1 text-xs',
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-sm',
  lg: 'px-5 py-2.5 text-base',
};

const variants = {
  primary:   'bg-orange-600 text-white hover:bg-orange-700 focus:ring-orange-500 shadow-sm shadow-orange-600/20',
  secondary: 'bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-400',
  outline:   'border border-slate-200 text-slate-600 hover:bg-slate-50 focus:ring-slate-400',
  ghost:     'text-slate-500 hover:bg-slate-100 hover:text-slate-700 focus:ring-slate-400',
  danger:    'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500 shadow-sm',
  success:   'bg-emerald-600 text-white hover:bg-emerald-700 focus:ring-emerald-500 shadow-sm',
};

const sizeClasses    = computed(() => sizes[props.size] || sizes.md);
const variantClasses = computed(() => variants[props.variant] || variants.primary);
</script>
