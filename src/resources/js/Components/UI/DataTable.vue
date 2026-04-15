<template>
  <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
    <div class="overflow-x-auto">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-slate-100 bg-slate-50/80">
          <tr>
            <th
              v-for="col in columns"
              :key="col.key"
              class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wider text-slate-400"
            >
              {{ col.label }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-50">
          <tr
            v-for="(row, idx) in rows"
            :key="idx"
            class="transition-colors hover:bg-orange-50/30"
          >
            <slot name="row" :row="row" :index="idx" />
          </tr>
          <tr v-if="!rows?.length">
            <td :colspan="columns.length" class="px-5 py-10 text-center">
              <EmptyState :title="emptyTitle" :description="emptyDescription" :icon="emptyIcon" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import EmptyState from './EmptyState.vue';

defineProps({
  columns:          { type: Array, required: true },
  rows:             { type: Array, default: () => [] },
  emptyTitle:       { type: String, default: 'Belum ada data' },
  emptyDescription: { type: String, default: '' },
  emptyIcon:        { type: String, default: '📋' },
});
</script>
