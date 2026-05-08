<script setup>
import { ref, computed } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    log: { type: Object, required: true },
});

const showRawJson = ref(false);

const mutations = computed(() => props.log.plan_snapshot?.mutations || []);
const summary = computed(() => props.log.plan_snapshot?.summary || {
    promoted: props.log.promoted_count,
    graduated: props.log.graduated_count,
    retained: props.log.retained_count,
    excluded: props.log.excluded_count,
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

const actionLabel = (action) => {
    const map = {
        promote: 'Naik Kelas',
        graduate: 'Lulus',
        retain: 'Tinggal Kelas',
        transfer_out: 'Mutasi Keluar',
        dropout: 'Putus Sekolah',
    };
    return map[action] || action;
};

const actionBadgeClass = (action) => {
    switch (action) {
        case 'promote': return 'bg-emerald-100 text-emerald-700';
        case 'graduate': return 'bg-blue-100 text-blue-700';
        case 'retain': return 'bg-amber-100 text-amber-700';
        default: return 'bg-slate-100 text-slate-500';
    }
};

function downloadSnapshot() {
    const blob = new Blob([JSON.stringify(props.log.plan_snapshot, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `transition-log-${props.log.id}-snapshot.json`;
    a.click();
    URL.revokeObjectURL(url);
}
</script>

<template>
    <Head :title="`Detail Log Transisi #${log.id}`" />

    <div>
        <!-- Back link -->
        <div class="mb-4">
            <Link href="/year-transition/logs" class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700 transition-colors">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Kembali ke Riwayat
            </Link>
        </div>

        <!-- Header -->
        <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
                <h2 class="text-xl font-bold text-slate-800">Detail Log Transisi #{{ log.id }}</h2>
                <div class="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm text-slate-500">
                    <span>
                        <span class="font-medium text-slate-600">Dijalankan oleh:</span>
                        {{ log.executor?.name || '—' }}
                    </span>
                    <span>
                        <span class="font-medium text-slate-600">Waktu:</span>
                        {{ formatDate(log.executed_at) }}
                    </span>
                    <span v-if="log.ip_address">
                        <span class="font-medium text-slate-600">IP:</span>
                        {{ log.ip_address }}
                    </span>
                </div>
                <div class="mt-2 flex gap-2 text-sm">
                    <span class="font-medium text-slate-600">{{ log.source_academic_year?.name }}</span>
                    <svg class="h-5 w-5 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                    </svg>
                    <span class="font-medium text-slate-600">{{ log.target_academic_year?.name }}</span>
                </div>
            </div>
            <Button size="sm" variant="outline" @click="downloadSnapshot">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Unduh Snapshot JSON
            </Button>
        </div>

        <!-- Stat tiles -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
            <div class="rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-center">
                <div class="text-3xl font-bold text-emerald-600">{{ log.promoted_count }}</div>
                <div class="text-xs text-emerald-700 mt-1 font-medium">Naik Kelas</div>
            </div>
            <div class="rounded-xl border border-blue-200 bg-blue-50 p-4 text-center">
                <div class="text-3xl font-bold text-blue-600">{{ log.graduated_count }}</div>
                <div class="text-xs text-blue-700 mt-1 font-medium">Lulus</div>
            </div>
            <div class="rounded-xl border border-amber-200 bg-amber-50 p-4 text-center">
                <div class="text-3xl font-bold text-amber-600">{{ log.retained_count }}</div>
                <div class="text-xs text-amber-700 mt-1 font-medium">Tinggal Kelas</div>
            </div>
            <div class="rounded-xl border border-slate-200 bg-slate-50 p-4 text-center">
                <div class="text-3xl font-bold text-slate-500">{{ log.excluded_count }}</div>
                <div class="text-xs text-slate-500 mt-1 font-medium">Dikecualikan</div>
            </div>
        </div>

        <!-- Mutation table -->
        <div class="mb-6 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div class="border-b border-slate-100 px-4 py-3">
                <h3 class="text-sm font-semibold text-slate-700">Detail Mutasi Siswa</h3>
                <p class="text-xs text-slate-400 mt-0.5">{{ mutations.length }} siswa dalam snapshot</p>
            </div>
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-100">
                    <thead class="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                        <tr>
                            <th class="px-4 py-3 text-left">Nama Siswa</th>
                            <th class="px-4 py-3 text-left">NIS</th>
                            <th class="px-4 py-3 text-left">Kelas Asal</th>
                            <th class="px-4 py-3 text-left">Tindakan</th>
                            <th class="px-4 py-3 text-left">Kelas Tujuan</th>
                            <th class="px-4 py-3 text-left">Alasan</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        <tr
                            v-for="m in mutations"
                            :key="m.student_id"
                            class="hover:bg-slate-50 transition-colors"
                        >
                            <td class="px-4 py-3 font-medium text-sm text-slate-800">{{ m.student_name }}</td>
                            <td class="px-4 py-3 text-sm text-slate-500">{{ m.nis }}</td>
                            <td class="px-4 py-3 text-sm text-slate-600">{{ m.from_class_name }}</td>
                            <td class="px-4 py-3">
                                <span
                                    class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                                    :class="actionBadgeClass(m.action)"
                                >
                                    {{ actionLabel(m.action) }}
                                </span>
                            </td>
                            <td class="px-4 py-3 text-sm text-slate-600">{{ m.to_class_name || '—' }}</td>
                            <td class="px-4 py-3 text-xs text-slate-500">{{ m.reason || '—' }}</td>
                        </tr>
                        <tr v-if="mutations.length === 0">
                            <td colspan="6" class="px-4 py-10 text-center text-sm text-slate-400">
                                Tidak ada data mutasi dalam snapshot.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Raw JSON viewer -->
        <div class="rounded-xl border border-slate-200 bg-white shadow-sm overflow-hidden">
            <button
                @click="showRawJson = !showRawJson"
                class="flex w-full items-center justify-between px-4 py-3 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
            >
                <span class="flex items-center gap-2">
                    <svg class="h-4 w-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                    </svg>
                    Raw JSON Snapshot
                </span>
                <svg
                    :class="['h-4 w-4 text-slate-400 transition-transform', showRawJson && 'rotate-180']"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
            </button>
            <div v-if="showRawJson" class="border-t border-slate-100 p-4 bg-slate-900 overflow-x-auto max-h-96">
                <pre class="text-xs text-emerald-400 font-mono leading-relaxed whitespace-pre-wrap">{{ JSON.stringify(log.plan_snapshot, null, 2) }}</pre>
            </div>
        </div>
    </div>
</template>
