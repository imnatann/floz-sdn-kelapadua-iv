<script setup>
import { computed } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Pagination from '@/Components/UI/Pagination.vue';
import Button from '@/Components/UI/Button.vue';
import EmptyState from '@/Components/UI/EmptyState.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    logs: { type: Object, required: true },
});

function formatDate(dateStr) {
    if (!dateStr) return '—';
    const d = new Date(dateStr);
    return d.toLocaleDateString('id-ID', {
        day: '2-digit',
        month: 'long',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
}
</script>

<template>
    <Head title="Riwayat Transisi Tahun Ajaran" />

    <div>
        <!-- Header -->
        <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <h2 class="text-xl font-bold text-slate-800">Riwayat Transisi Tahun Ajaran</h2>
                <p class="text-sm text-slate-500 mt-0.5">Histori eksekusi kenaikan kelas</p>
            </div>
            <Link href="/year-transition">
                <Button variant="outline">
                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                    </svg>
                    Mulai Transisi Baru
                </Button>
            </Link>
        </div>

        <!-- Table -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <table class="min-w-full divide-y divide-slate-100">
                <thead class="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <tr>
                        <th class="px-4 py-3 text-left">Tanggal</th>
                        <th class="px-4 py-3 text-left">Tahun Sumber</th>
                        <th class="px-4 py-3 text-left">Tahun Tujuan</th>
                        <th class="px-4 py-3 text-left">Dijalankan Oleh</th>
                        <th class="px-4 py-3 text-center">Naik</th>
                        <th class="px-4 py-3 text-center">Lulus</th>
                        <th class="px-4 py-3 text-center">Mengulang</th>
                        <th class="px-4 py-3 text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr v-for="log in logs.data" :key="log.id" class="hover:bg-slate-50 transition-colors">
                        <td class="px-4 py-3 text-sm text-slate-600 whitespace-nowrap">
                            {{ formatDate(log.executed_at) }}
                        </td>
                        <td class="px-4 py-3 text-sm font-medium text-slate-700">
                            {{ log.source_academic_year?.name || '—' }}
                        </td>
                        <td class="px-4 py-3 text-sm font-medium text-slate-700">
                            {{ log.target_academic_year?.name || '—' }}
                        </td>
                        <td class="px-4 py-3 text-sm text-slate-600">
                            {{ log.executor?.name || '—' }}
                        </td>
                        <td class="px-4 py-3 text-center">
                            <span class="inline-flex items-center justify-center rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-semibold text-emerald-700 min-w-[32px]">
                                {{ log.promoted_count }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-center">
                            <span class="inline-flex items-center justify-center rounded-full bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-700 min-w-[32px]">
                                {{ log.graduated_count }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-center">
                            <span class="inline-flex items-center justify-center rounded-full bg-amber-100 px-2 py-0.5 text-xs font-semibold text-amber-700 min-w-[32px]">
                                {{ log.retained_count }}
                            </span>
                        </td>
                        <td class="px-4 py-3">
                            <Link
                                :href="`/year-transition/logs/${log.id}`"
                                class="text-sm font-medium text-orange-600 hover:text-orange-700 hover:underline"
                            >
                                Lihat Detail
                            </Link>
                        </td>
                    </tr>
                    <tr v-if="!logs.data?.length">
                        <td colspan="8">
                            <EmptyState
                                icon="📋"
                                title="Belum ada riwayat transisi"
                                description="Mulai proses transisi tahun ajaran untuk melihat riwayat di sini."
                            />
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="mt-6">
            <Pagination :links="logs.links" />
        </div>
    </div>
</template>
