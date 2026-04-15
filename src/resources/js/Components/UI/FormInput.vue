<template>
  <div class="space-y-1.5">
    <label v-if="label" :for="id" class="flex items-center gap-1 text-xs font-medium text-slate-600">
      {{ label }}
      <span v-if="required" class="text-orange-500">*</span>
      <span v-if="hint" class="ml-auto font-normal text-slate-400">{{ hint }}</span>
    </label>
    <input
      :id="id"
      :value="modelValue"
      @input="$emit('update:modelValue', $event.target.value)"
      :type="type"
      :placeholder="placeholder"
      :required="required"
      :disabled="disabled"
      :class="[
        'w-full rounded-lg border bg-white px-3.5 py-2.5 text-sm text-slate-700 placeholder:text-slate-300',
        'transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-offset-0',
        error
          ? 'border-red-300 focus:border-red-400 focus:ring-red-100'
          : 'border-slate-200 focus:border-orange-400 focus:ring-orange-100',
        disabled ? 'cursor-not-allowed bg-slate-50 text-slate-400' : '',
      ]"
    />
    <p v-if="error" class="flex items-center gap-1 text-xs text-red-500">
      <svg class="h-3.5 w-3.5 shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
      {{ error }}
    </p>
  </div>
</template>

<script setup>
defineProps({
  modelValue:  { type: [String, Number], default: '' },
  label:       { type: String, default: '' },
  type:        { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  required:    { type: Boolean, default: false },
  disabled:    { type: Boolean, default: false },
  error:       { type: String, default: '' },
  hint:        { type: String, default: '' },
  id:          { type: String, default: () => `input-${Math.random().toString(36).slice(2, 9)}` },
});
defineEmits(['update:modelValue']);
</script>
