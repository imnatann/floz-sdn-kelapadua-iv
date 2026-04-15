<script setup>
import { ref, watch } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Pagination from '@/Components/UI/Pagination.vue';
import DetailModal from './DetailModal.vue';
import debounce from 'lodash/debounce';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  logs: Object,
  filters: Object,
});

const search = ref(props.filters.search || '');
const eventFilter = ref(props.filters.event || 'all');
const dateFilter = ref(props.filters.date || '');
const logDetail = ref(null);
const showModal = ref(false);

const openDetail = (log) => {
  logDetail.value = log;
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  setTimeout(() => logDetail.value = null, 300);
};

// Search & Filter
watch([search, eventFilter, dateFilter], debounce(() => {
  router.get(route('audit-logs.index'), {
    search: search.value,
    event: eventFilter.value,
    date: dateFilter.value,
  }, {
    preserveState: true,
    preserveScroll: true,
    replace: true,
  });
}, 300));

const eventColor = (event) => {
    switch (event) {
        case 'created': return 'success';
        case 'updated': return 'warning';
        case 'deleted': return 'danger';
        default: return 'neutral';
    }
};
</script>

<template>
  <Head title="Audit Logs" />

  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold text-slate-800">Audit Logs</h2>
        <p class="mt-1 text-sm text-slate-400">Jejak aktivitas keamanan dan perubahan data.</p>
      </div>
    </div>

    <!-- Filters -->
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-4">
      <div class="sm:col-span-2">
        <input
          v-model="search"
          type="text"
          placeholder="Cari user, event, atau tipe data..."
          class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm placeholder:text-slate-400 focus:border-orange-500 focus:outline-none focus:ring-1 focus:ring-orange-500"
        >
      </div>
      <div>
         <select
          v-model="eventFilter"
          class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 focus:border-orange-500 focus:outline-none"
        >
          <option value="all">Semua Event</option>
          <option value="created">Created</option>
          <option value="updated">Updated</option>
          <option value="deleted">Deleted</option>
        </select>
      </div>
      <div>
        <input
          v-model="dateFilter"
          type="date"
          class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 focus:border-orange-500 focus:outline-none"
        >
      </div>
    </div>

    <!-- Table -->
     <Card :noPadding="true">
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead class="border-b border-slate-100 bg-slate-50/60">
            <tr>
              <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wider text-slate-400">Waktu</th>
              <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wider text-slate-400">User</th>
              <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wider text-slate-400">Event</th>
              <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wider text-slate-400">Target</th>
              <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wider text-slate-400">IP Address</th>
              <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wider text-slate-400"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-for="log in logs.data" :key="log.id" class="transition-colors hover:bg-slate-50 cursor-pointer" @click="openDetail(log)">
              <td class="whitespace-nowrap px-5 py-3.5 text-slate-500 font-mono text-xs">
                {{ new Date(log.created_at).toLocaleString('id-ID') }}
              </td>
              <td class="whitespace-nowrap px-5 py-3.5">
                <div class="flex items-center gap-3">
                  <div class="flex h-8 w-8 items-center justify-center rounded-full bg-slate-100 text-xs font-bold text-slate-600">
                    {{ log.user?.name?.charAt(0) || '?' }}
                  </div>
                  <div>
                    <p class="text-sm font-medium text-slate-700">{{ log.user?.name || 'Unknown' }}</p>
                    <p class="text-xs text-slate-400">{{ log.user?.email }}</p>
                  </div>
                </div>
              </td>
              <td class="whitespace-nowrap px-5 py-3.5">
                <div class="flex gap-1">
                  <Badge v-if="log.method" variant="neutral">{{ log.method }}</Badge>
                  <Badge :variant="eventColor(log.event)">{{ log.event.toUpperCase() }}</Badge>
                </div>
              </td>
              <td class="whitespace-nowrap px-5 py-3.5 text-slate-600">
                <span class="font-medium">{{ log.auditable_type.split('\\').pop() }}</span>
                <span class="text-slate-400 text-xs ml-1">#{{ log.auditable_id }}</span>
              </td>
              <td class="whitespace-nowrap px-5 py-3.5 text-slate-500 font-mono text-xs">{{ log.ip_address }}</td>
              <td class="whitespace-nowrap px-5 py-3.5 text-right">
                <button class="text-slate-400 hover:text-orange-500">
                  <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                </button>
              </td>
            </tr>
             <tr v-if="!logs.data.length">
              <td colspan="6" class="px-5 py-12 text-center">
                <div class="flex flex-col items-center gap-2">
                  <span class="text-3xl">🛡️</span>
                  <p class="text-sm font-medium text-slate-500">Belum ada log aktivitas</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <div v-if="logs.data.length" class="border-t border-slate-100 px-5 py-3">
         <Pagination :links="logs.links" />
      </div>
    </Card>

    <DetailModal :show="showModal" :log="logDetail" @close="closeModal" />
  </div>
</template>
