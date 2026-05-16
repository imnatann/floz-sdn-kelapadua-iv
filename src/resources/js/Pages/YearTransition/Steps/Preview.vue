<script setup>
import { ref, computed, onMounted } from 'vue';
import axios from 'axios';
import Button from '@/Components/UI/Button.vue';

const props = defineProps({
    modelValue: { type: Object, required: true },
});

const emit = defineEmits(['update:modelValue', 'next', 'back']);

const loading = ref(false);
const error = ref('');
const plan = ref(props.modelValue.plan || null);

const activeTab = ref('all');

const summary = computed(() => plan.value?.summary || { promoted: 0, graduated: 0, retained: 0, excluded: 0 });
const mutations = computed(() => plan.value?.mutations || []);

const filteredMutations = computed(() => {
    if (activeTab.value === 'all') return mutations.value;
    const tabToAction = {
        promoted: 'promote',
        graduated: 'graduate',
        retained: 'retain',
        excluded: ['transfer_out', 'dropout'],
    };
    const target = tabToAction[activeTab.value];
    if (Array.isArray(target)) return mutations.value.filter(m => target.includes(m.action));
    return mutations.value.filter(m => m.action === target);
});

const tabs = [
    { key: 'all', label: 'Semua' },
    { key: 'promoted', label: 'Naik Kelas' },
    { key: 'graduated', label: 'Lulus' },
    { key: 'retained', label: 'Tinggal Kelas' },
    { key: 'excluded', label: 'Dikecualikan' },
];

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

onMounted(async () => {
    if (!plan.value) {
        await fetchPreview();
    }
});

async function fetchPreview() {
    if (!props.modelValue.sourceAyId || !props.modelValue.targetAyId) {
        error.value = 'Tahun ajaran belum dipilih.';
        return;
    }
    loading.value = true;
    error.value = '';
    try {
        const response = await axios.post('/year-transition/preview', {
            source_academic_year_id: props.modelValue.sourceAyId,
            target_academic_year_id: props.modelValue.targetAyId,
            overrides: props.modelValue.overrides || {},
        });
        plan.value = response.data;
        // Store plan in wizardData
        emit('update:modelValue', {
            ...props.modelValue,
            plan: response.data,
        });
    } catch (err) {
        error.value = err.response?.data?.message || 'Gagal memuat preview mutasi.';
    } finally {
        loading.value = false;
    }
}

function downloadJson() {
    if (!plan.value) return;
    const blob = new Blob([JSON.stringify(plan.value, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `year-transition-preview-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
}

function handleNext() {
    emit('next');
}
</script>

<template>
    <div>
        <h3 class="text-base font-semibold text-slate-800 mb-1">Langkah 4: Preview Mutasi (Dry Run)</h3>
        <p class="text-sm text-slate-500 mb-6">
            Tinjau semua perubahan yang akan diterapkan. Belum ada data yang diubah.
        </p>

        <!-- Loading -->
        <div v-if="loading" class="space-y-4">
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                <div v-for="i in 4" :key="i" class="h-24 bg-slate-100 rounded-xl animate-pulse" />
            </div>
            <div class="h-64 bg-slate-100 rounded-xl animate-pulse" />
        </div>

        <!-- Error -->
        <div v-else-if="error" class="flex gap-3 rounded-lg border border-red-200 bg-red-50 p-4 mb-4">
            <svg class="h-5 w-5 text-red-500 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <div>
                <p class="text-sm text-red-700">{{ error }}</p>
                <button @click="fetchPreview" class="mt-2 text-xs text-red-600 hover:underline font-medium">Coba Lagi</button>
            </div>
        </div>

        <!-- Content -->
        <div v-else-if="plan">
            <!-- Summary stat cards -->
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
                <div class="rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-center">
                    <div class="text-3xl font-bold text-emerald-600">{{ summary.promoted }}</div>
                    <div class="text-xs text-emerald-700 mt-1 font-medium">Naik Kelas</div>
                </div>
                <div class="rounded-xl border border-blue-200 bg-blue-50 p-4 text-center">
                    <div class="text-3xl font-bold text-blue-600">{{ summary.graduated }}</div>
                    <div class="text-xs text-blue-700 mt-1 font-medium">Lulus</div>
                </div>
                <div class="rounded-xl border border-amber-200 bg-amber-50 p-4 text-center">
                    <div class="text-3xl font-bold text-amber-600">{{ summary.retained }}</div>
                    <div class="text-xs text-amber-700 mt-1 font-medium">Tinggal Kelas</div>
                </div>
                <div class="rounded-xl border border-slate-200 bg-slate-50 p-4 text-center">
                    <div class="text-3xl font-bold text-slate-500">{{ summary.excluded }}</div>
                    <div class="text-xs text-slate-500 mt-1 font-medium">Dikecualikan</div>
                </div>
            </div>

            <!-- Info alert -->
            <div class="mb-4 flex gap-3 rounded-lg border border-blue-200 bg-blue-50 p-4">
                <svg class="h-5 w-5 text-blue-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p class="text-sm text-blue-700">
                    Belum ada perubahan data. Klik "Lanjutkan ke Konfirmasi" untuk menerapkan perubahan ini.
                </p>
            </div>

            <!-- Actions row -->
            <div class="mb-4 flex items-center justify-between gap-2 flex-wrap">
                <!-- Tabs -->
                <div class="flex gap-1 flex-wrap">
                    <button
                        v-for="tab in tabs"
                        :key="tab.key"
                        @click="activeTab = tab.key"
                        :class="[
                            'rounded-lg px-3 py-1.5 text-xs font-medium transition-colors',
                            activeTab === tab.key
                                ? 'bg-orange-100 text-orange-700'
                                : 'text-slate-500 hover:bg-slate-100'
                        ]"
                    >
                        {{ tab.label }}
                    </button>
                </div>
                <!-- Download + Refresh -->
                <div class="flex gap-2">
                    <Button size="sm" variant="outline" @click="fetchPreview" :loading="loading">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        Refresh
                    </Button>
                    <Button size="sm" variant="outline" @click="downloadJson">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                        Unduh JSON
                    </Button>
                </div>
            </div>

            <!-- Mutation table -->
            <div class="overflow-hidden rounded-xl border border-slate-200">
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
                        <tbody class="divide-y divide-slate-100 bg-white">
                            <tr
                                v-for="m in filteredMutations"
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
                            <tr v-if="filteredMutations.length === 0">
                                <td colspan="6" class="px-4 py-10 text-center text-sm text-slate-400">
                                    Tidak ada data untuk kategori ini.
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Navigation -->
        <div class="mt-8 flex justify-between">
            <Button variant="outline" @click="$emit('back')">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Sebelumnya
            </Button>
            <Button @click="handleNext" :disabled="loading || !plan">
                Lanjutkan ke Konfirmasi
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
            </Button>
        </div>
    </div>
</template>
