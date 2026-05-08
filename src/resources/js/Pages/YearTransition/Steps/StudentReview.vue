<script setup>
import { ref, computed, onMounted } from 'vue';
import axios from 'axios';
import Button from '@/Components/UI/Button.vue';
import StudentRow from '@/Components/YearTransition/StudentRow.vue';

const props = defineProps({
    modelValue: { type: Object, required: true },
});

const emit = defineEmits(['update:modelValue', 'next', 'back']);

const loading = ref(false);
const error = ref('');
const mutations = ref([]);
const localOverrides = ref({ ...props.modelValue.overrides });

// Group mutations by from_class_name
const groupedMutations = computed(() => {
    const groups = {};
    for (const m of mutations.value) {
        const key = m.from_class_name || 'Tanpa Kelas';
        if (!groups[key]) groups[key] = { className: key, gradeLevel: m.from_grade_level, students: [] };
        groups[key].students.push(m);
    }
    // Sort by grade level
    return Object.values(groups).sort((a, b) => a.gradeLevel - b.gradeLevel);
});

const excludedCount = computed(() => {
    return (mutations.value.length > 0)
        ? 0  // We only show active students in the mutation table
        : 0;
});

onMounted(async () => {
    await fetchStudents();
});

async function fetchStudents() {
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
            overrides: localOverrides.value,
        });
        mutations.value = response.data.mutations || [];
    } catch (err) {
        error.value = err.response?.data?.message || 'Gagal memuat data siswa.';
    } finally {
        loading.value = false;
    }
}

function handleStudentChange({ studentId, action, reason, isDefault }) {
    if (isDefault) {
        // Remove override if back to default
        const updated = { ...localOverrides.value };
        delete updated[studentId];
        localOverrides.value = updated;
    } else {
        localOverrides.value = {
            ...localOverrides.value,
            [studentId]: { action, reason },
        };
    }
}

function handleNext() {
    emit('update:modelValue', {
        ...props.modelValue,
        overrides: localOverrides.value,
    });
    emit('next');
}
</script>

<template>
    <div>
        <h3 class="text-base font-semibold text-slate-800 mb-1">Langkah 3: Review Per Siswa</h3>
        <p class="text-sm text-slate-500 mb-6">
            Tinjau tindakan default untuk setiap siswa. Ubah jika diperlukan sebelum membuat preview mutasi.
        </p>

        <!-- Loading state -->
        <div v-if="loading" class="space-y-4">
            <div v-for="i in 3" :key="i" class="rounded-xl border border-slate-200 overflow-hidden">
                <div class="h-10 bg-slate-100 animate-pulse" />
                <div class="divide-y divide-slate-100">
                    <div v-for="j in 4" :key="j" class="h-12 bg-white animate-pulse" />
                </div>
            </div>
        </div>

        <!-- Error state -->
        <div v-else-if="error" class="flex gap-3 rounded-lg border border-red-200 bg-red-50 p-4 mb-4">
            <svg class="h-5 w-5 text-red-500 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <div>
                <p class="text-sm text-red-700">{{ error }}</p>
                <button @click="fetchStudents" class="mt-2 text-xs text-red-600 hover:underline font-medium">Coba Lagi</button>
            </div>
        </div>

        <!-- Student groups -->
        <div v-else-if="groupedMutations.length > 0" class="space-y-4">
            <div
                v-for="group in groupedMutations"
                :key="group.className"
                class="overflow-hidden rounded-xl border border-slate-200"
            >
                <!-- Group header -->
                <div class="bg-slate-50 px-4 py-2.5 flex items-center justify-between">
                    <span class="text-sm font-semibold text-slate-700">{{ group.className }}</span>
                    <span class="text-xs text-slate-400">{{ group.students.length }} siswa</span>
                </div>
                <!-- Student rows -->
                <table class="min-w-full">
                    <thead class="text-xs font-semibold uppercase tracking-wide text-slate-400 bg-white border-b border-slate-100">
                        <tr>
                            <th class="px-4 py-2 text-left">Nama / NIS</th>
                            <th class="px-4 py-2 text-left">Kelas Asal</th>
                            <th class="px-4 py-2 text-left">Tindakan</th>
                            <th class="px-4 py-2 text-left">Alasan</th>
                            <th class="px-4 py-2 text-left">Keterangan</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 bg-white">
                        <StudentRow
                            v-for="m in group.students"
                            :key="m.student_id"
                            :mutation="m"
                            :override="localOverrides[m.student_id] || null"
                            @change="handleStudentChange"
                        />
                    </tbody>
                </table>
            </div>
        </div>

        <div v-else-if="!loading" class="text-center py-12 text-slate-400 text-sm">
            Tidak ada siswa aktif ditemukan di tahun ajaran sumber.
        </div>

        <!-- Override summary -->
        <div v-if="Object.keys(localOverrides).length > 0" class="mt-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3">
            <p class="text-sm text-amber-700">
                <span class="font-semibold">{{ Object.keys(localOverrides).length }} siswa</span> memiliki tindakan non-default.
            </p>
        </div>

        <!-- Navigation -->
        <div class="mt-8 flex justify-between">
            <Button variant="outline" @click="$emit('back')">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Sebelumnya
            </Button>
            <Button @click="handleNext" :disabled="loading">
                Buat Preview
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
            </Button>
        </div>
    </div>
</template>
