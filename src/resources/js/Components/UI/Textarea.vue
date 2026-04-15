<script setup>
import { onMounted, ref } from 'vue';

defineProps({
    modelValue: {
        type: String,
        required: true,
    },
    rows: {
        type: [String, Number],
        default: 3,
    },
});

defineEmits(['update:modelValue']);

const input = ref(null);

onMounted(() => {
    if (input.value.hasAttribute('autofocus')) {
        input.value.focus();
    }
});

defineExpose({ focus: () => input.value.focus() });
</script>

<template>
    <textarea
        ref="input"
        class="border-gray-300 focus:border-emerald-500 focus:ring-emerald-500 rounded-md shadow-sm w-full"
        :value="modelValue"
        :rows="rows"
        @input="$emit('update:modelValue', $event.target.value)"
    ></textarea>
</template>
