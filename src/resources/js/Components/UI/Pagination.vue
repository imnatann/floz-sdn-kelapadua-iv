<script setup>
import { Link } from '@inertiajs/vue3';

defineProps({
  links: Array,
});

const decode = (s) => {
  if (s == null) return '';
  const txt = document.createElement('textarea');
  txt.innerHTML = String(s);
  return txt.value;
};

const cleanLabel = (raw) => {
  const decoded = decode(raw).trim();
  // Laravel emits "&laquo; Previous" / "Next &raquo;" — normalize to Indonesian.
  if (/previous|sebelumnya|^[«]/i.test(decoded)) return 'Sebelumnya';
  if (/next|berikutnya|^[»]/i.test(decoded)) return 'Berikutnya';
  return decoded;
};

const isPrev = (label) => /sebelumnya/i.test(cleanLabel(label));
const isNext = (label) => /berikutnya/i.test(cleanLabel(label));
</script>

<template>
  <nav v-if="links && links.length > 3" aria-label="Pagination" class="flex justify-center">
    <ul class="inline-flex flex-wrap items-center gap-1">
      <li v-for="(link, key) in links" :key="key">
        <span
          v-if="link.url === null"
          class="inline-flex items-center justify-center min-w-[2.25rem] h-9 px-3 rounded-md border border-slate-200 bg-slate-50 text-xs font-medium text-slate-300 cursor-not-allowed select-none"
          :aria-disabled="true"
        >
          <svg v-if="isPrev(link.label)" class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
          <span v-else-if="isPrev(link.label) || isNext(link.label)">{{ cleanLabel(link.label) }}</span>
          <svg v-else-if="isNext(link.label)" class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>
          <span v-else>{{ cleanLabel(link.label) }}</span>
        </span>
        <Link
          v-else
          :href="link.url"
          :aria-current="link.active ? 'page' : null"
          :aria-label="isPrev(link.label) ? 'Halaman sebelumnya' : isNext(link.label) ? 'Halaman berikutnya' : `Halaman ${cleanLabel(link.label)}`"
          class="inline-flex items-center justify-center min-w-[2.25rem] h-9 px-3 rounded-md border text-xs font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-orange-500/40"
          :class="link.active
            ? 'bg-orange-600 text-white border-orange-600 shadow-sm'
            : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50 hover:border-slate-300'"
        >
          <template v-if="isPrev(link.label)">
            <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
            <span class="ml-1 hidden sm:inline">Sebelumnya</span>
          </template>
          <template v-else-if="isNext(link.label)">
            <span class="mr-1 hidden sm:inline">Berikutnya</span>
            <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>
          </template>
          <template v-else>{{ cleanLabel(link.label) }}</template>
        </Link>
      </li>
    </ul>
  </nav>
</template>
