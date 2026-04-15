<template>
  <div class="space-y-1.5">
    <label v-if="label" :for="id" class="flex items-center gap-1 text-xs font-medium text-slate-600">
      {{ label }}
      <span v-if="required" class="text-orange-500">*</span>
    </label>
    <div class="relative">
      <select
        :id="id"
        :value="modelValue"
        @change="$emit('update:modelValue', $event.target.value)"
        :required="required"
        :disabled="disabled"
        :class="[
          'w-full appearance-none rounded-lg border bg-white px-3.5 py-2.5 pr-10 text-sm text-slate-700',
          'transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-offset-0',
          error
            ? 'border-red-300 focus:border-red-400 focus:ring-red-100'
            : 'border-slate-200 focus:border-orange-400 focus:ring-orange-100',
          disabled ? 'cursor-not-allowed bg-slate-50 text-slate-400' : '',
        ]"
      >
        <option v-if="placeholder" value="" disabled selected>{{ placeholder }}</option>
        <template v-if="options && options.length">
            <option 
                v-for="(opt, index) in options" 
                :key="index" 
                :value="typeof opt === 'object' ? opt.value : opt"
            >
                {{ typeof opt === 'object' ? opt.label : opt }}
            </option>
        </template>
        <slot v-else />
      </select>
      <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
        <svg class="h-4 w-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </div>
    <p v-if="error" class="flex items-center gap-1 text-xs text-red-500">
      <svg class="h-3.5 w-3.5 shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
      {{ error }}
    </p>
  </div>
</template>

<script setup>
defineProps({
  modelValue: { type: [String, Number], default: '' },
  label:      { type: String, default: '' },
  options:    { type: Array, default: () => [] },
  placeholder:{ type: String, default: '' },
  required:   { type: Boolean, default: false },
  disabled:   { type: Boolean, default: false },
  error:      { type: String, default: '' },
  id:         { type: String, default: () => `select-${Math.random().toString(36).slice(2, 9)}` },
});
defineEmits(['update:modelValue']);
</script>
