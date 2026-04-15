<template>
  <select
    :value="modelValue"
    @change="$emit('update:modelValue', $event.target.value)"
    class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-600 transition-colors focus:border-orange-400 focus:outline-none focus:ring-2 focus:ring-orange-100"
  >
    <slot />
  </select>
</template>

<script setup>
defineProps({
  modelValue: { type: [String, Number], default: '' },
});
defineEmits(['update:modelValue']);
</script>
