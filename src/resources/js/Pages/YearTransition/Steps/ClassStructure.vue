<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';
import Button from '@/Components/UI/Button.vue';

const props = defineProps({
    modelValue: { type: Object, required: true },
});

const emit = defineEmits(['update:modelValue', 'next', 'back']);

const loading = ref(false);
const error = ref('');
const classes = ref([]); // local editable copy

onMounted(async () => {
    // If we already have newClasses from a previous visit, use them
    if (props.modelValue.newClasses && props.modelValue.newClasses.length > 0) {
        classes.value = props.modelValue.newClasses.map(c => ({ ...c, excluded: false }));
        return;
    }
    await fetchProposedClasses();
});

async function fetchProposedClasses() {
    if (!props.modelValue.sourceAyId || !props.modelValue.targetAyId) {
        error.value = 'Tahun ajaran belum dipilih. Kembali ke langkah sebelumnya.';
        return;
    }
    loading.value = true;
    error.value = '';
    try {
        const response = await axios.post('/year-transition/preview', {
            source_academic_year_id: props.modelValue.sourceAyId,
            target_academic_year_id: props.modelValue.targetAyId,
            overrides: {},
        });
        const newClasses = response.data.new_classes || [];
        classes.value = newClasses.map(c => ({
            ...c,
            excluded: false,
        }));
    } catch (err) {
        error.value = err.response?.data?.message || 'Gagal memuat struktur kelas. Coba lagi.';
    } finally {
        loading.value = false;
    }
}

function updateName(index, value) {
    classes.value[index].name = value;
}

function toggleExclude(index) {
    classes.value[index].excluded = !classes.value[index].excluded;
}

function handleNext() {
    const activeClasses = classes.value.filter(c => !c.excluded);
    emit('update:modelValue', {
        ...props.modelValue,
        newClasses: activeClasses,
    });
    emit('next');
}

const gradeLabel = (g) => `Kelas ${g}`;
</script>

<template>
    <div>
        <h3 class="text-base font-semibold text-slate-800 mb-1">Langkah 2: Struktur Kelas Baru</h3>
        <p class="text-sm text-slate-500 mb-6">
            Berikut daftar kelas yang akan dibuat di tahun ajaran tujuan berdasarkan struktur tahun sumber. Anda dapat mengedit nama kelas atau mengecualikan kelas yang tidak diperlukan.
        </p>

        <!-- Info callout -->
        <div class="mb-6 flex gap-3 rounded-lg border border-blue-200 bg-blue-50 p-4">
            <svg class="h-5 w-5 text-blue-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div class="text-sm text-blue-700">
                <p>Kelas 1 untuk siswa baru (PPDB) perlu dibuat terpisah setelah proses ini selesai.</p>
                <p class="mt-1">Wali kelas dapat diisi setelah transisi selesai melalui halaman edit kelas.</p>
            </div>
        </div>

        <!-- Loading skeleton -->
        <div v-if="loading" class="space-y-3">
            <div v-for="i in 4" :key="i" class="h-12 bg-slate-100 rounded-lg animate-pulse" />
        </div>

        <!-- Error state -->
        <div v-else-if="error" class="flex gap-3 rounded-lg border border-red-200 bg-red-50 p-4 mb-4">
            <svg class="h-5 w-5 text-red-500 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <div class="flex-1">
                <p class="text-sm text-red-700">{{ error }}</p>
                <button @click="fetchProposedClasses" class="mt-2 text-xs text-red-600 hover:underline font-medium">Coba Lagi</button>
            </div>
        </div>

        <!-- Class table -->
        <div v-else-if="classes.length > 0" class="overflow-hidden rounded-xl border border-slate-200">
            <table class="min-w-full divide-y divide-slate-100">
                <thead class="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <tr>
                        <th class="px-4 py-3 text-left w-10">
                            <span class="sr-only">Aktif</span>
                        </th>
                        <th class="px-4 py-3 text-left">Nama Kelas</th>
                        <th class="px-4 py-3 text-left">Tingkat</th>
                        <th class="px-4 py-3 text-left">Wali Kelas</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr
                        v-for="(cls, i) in classes"
                        :key="i"
                        :class="['transition-colors', cls.excluded ? 'bg-slate-50 opacity-50' : 'bg-white hover:bg-orange-50/30']"
                    >
                        <td class="px-4 py-3">
                            <input
                                type="checkbox"
                                :checked="!cls.excluded"
                                @change="toggleExclude(i)"
                                class="h-4 w-4 rounded border-slate-300 text-orange-500 focus:ring-orange-400"
                            />
                        </td>
                        <td class="px-4 py-3">
                            <input
                                type="text"
                                :value="cls.name"
                                :disabled="cls.excluded"
                                @input="updateName(i, $event.target.value)"
                                class="w-full rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 focus:border-orange-400 focus:outline-none focus:ring-1 focus:ring-orange-200 disabled:bg-slate-50 disabled:text-slate-400"
                            />
                        </td>
                        <td class="px-4 py-3 text-sm text-slate-600">
                            {{ gradeLabel(cls.grade_level) }}
                        </td>
                        <td class="px-4 py-3 text-sm text-slate-400 italic">
                            (Belum ditentukan)
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div v-else-if="!loading" class="text-center py-12 text-slate-400 text-sm">
            Tidak ada kelas ditemukan di tahun ajaran sumber.
        </div>

        <!-- Navigation -->
        <div class="mt-8 flex justify-between">
            <Button variant="outline" @click="$emit('back')">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Sebelumnya
            </Button>
            <Button @click="handleNext" :disabled="loading || !!error">
                Lanjutkan
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
            </Button>
        </div>
    </div>
</template>
