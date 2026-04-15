<script setup>
import { Link } from '@inertiajs/vue3';

defineProps({
    links: Array,
});
</script>

<template>
    <div v-if="links.length > 3">
        <div class="flex justify-center mb-8 animate-fade-in-up delay-200 sticky top-20 z-40">
            <!-- Hero Logo Placeholder (Invisible, used for calculating start position) -->
            <div ref="heroLogoRef" class="h-24 sm:h-32 w-full max-w-[400px] opacity-0"></div>
        </div>
        <div class="flex flex-wrap -mb-1">
            <template v-for="(link, key) in links">
                <div v-if="link.url === null" :key="key" class="mr-1 mb-1 px-4 py-3 text-sm leading-4 text-gray-400 border rounded" v-html="link.label" />
                <Link v-else :key="`link-${key}`" class="mr-1 mb-1 px-4 py-3 text-sm leading-4 border rounded hover:bg-slate-50 focus:border-orange-500 focus:text-orange-500 transition-colors" :class="{ 'bg-orange-600 text-white border-orange-600': link.active, 'bg-white text-slate-700 border-slate-200': !link.active }" :href="link.url" v-html="link.label" />
            </template>
        </div>
    </div>
</template>
```
