<script setup>
import { ref, computed } from 'vue';
import { Link, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
    schoolClass: Object,
    exams: Array,
    studentsCount: Number,
});

const currentTab = ref('all');

const tabs = [
    { id: 'all', name: 'Semua Ujian' },
    { id: 'ulangan_harian', name: 'Ulangan Harian' },
    { id: 'uts', name: 'UTS / PTS' },
    { id: 'uas', name: 'UAS / PAS' },
];

const filteredExams = computed(() => {
    if (currentTab.value === 'all') return props.exams;
    return props.exams.filter(exam => exam.exam_type === currentTab.value);
});

const examTypeBadge = (type) => {
    switch(type) {
        case 'ulangan_harian': return 'bg-emerald-100 text-emerald-800';
        case 'uts': return 'bg-amber-100 text-amber-800';
        case 'uas': return 'bg-rose-100 text-rose-800';
        default: return 'bg-slate-100 text-slate-800';
    }
};

const examTypeLabel = (type) => {
    switch(type) {
        case 'ulangan_harian': return 'Ulangan Harian';
        case 'uts': return 'Sumatif Tengah Semester (UTS)';
        case 'uas': return 'Sumatif Akhir Semester (UAS)';
        default: return type;
    }
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <div class="flex items-center gap-2 mb-1">
            <Link :href="route('exams.index')" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Nilai Ujian</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">Kelas {{ schoolClass.name }}</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Daftar Ujian Kelas {{ schoolClass.name }}</h2>
      </div>
      <div>
         <Link :href="route('exams.create', schoolClass.id)">
             <Button>
                Buat Ujian Baru
             </Button>
         </Link>
      </div>
    </div>

    <!-- Tabs -->
    <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
            <button
                v-for="tab in tabs"
                :key="tab.id"
                @click="currentTab = tab.id"
                :class="[
                    currentTab === tab.id
                        ? 'border-blue-500 text-blue-600'
                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                    'whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium'
                ]"
            >
                {{ tab.name }}
            </button>
        </nav>
    </div>

    <Card class="overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-sm text-left">
                <thead class="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100">
                    <tr>
                        <th class="px-5 py-3">Judul Ujian</th>
                        <th class="px-5 py-3">Tipe</th>
                        <th class="px-5 py-3">Mata Pelajaran</th>
                        <th class="px-5 py-3">Tanggal</th>
                        <th class="px-5 py-3">Kehadiran</th>
                        <th class="px-5 py-3 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="exam in filteredExams" :key="exam.id" class="bg-white border-b border-slate-50 hover:bg-slate-50/50">
                        <td class="px-5 py-4 font-bold text-slate-900">
                            <div>{{ exam.title }}</div>
                            <div class="text-xs font-normal text-slate-500 mt-1" v-if="exam.status === 'active'">Belum Dinilai</div>
                            <div class="text-xs font-normal text-emerald-600 mt-1" v-else>Sudah Dinilai</div>
                        </td>
                        <td class="px-5 py-4">
                            <span :class="['inline-flex items-center px-2 py-1 rounded text-xs font-bold leading-none', examTypeBadge(exam.exam_type)]">
                                {{ examTypeLabel(exam.exam_type) }}
                            </span>
                        </td>
                        <td class="px-5 py-4 font-medium text-slate-600">{{ exam.subject.name }}</td>
                        <td class="px-5 py-4 font-medium text-slate-600">{{ exam.exam_date }}</td>
                        <td class="px-5 py-4">
                            <div v-if="exam.scores_count > 0" class="flex flex-wrap gap-1.5 items-center">
                                <span v-if="exam.kumpul_count > 0" class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold text-emerald-700 bg-emerald-50 ring-1 ring-inset ring-emerald-600/15">
                                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                    {{ exam.kumpul_count }} Hadir
                                </span>
                                <span v-if="exam.terlambat_count > 0" class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold text-amber-700 bg-amber-50 ring-1 ring-inset ring-amber-600/15">
                                    <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                                    {{ exam.terlambat_count }} Telat
                                </span>
                                <span v-if="exam.tidak_kumpul_count > 0" class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold text-rose-700 bg-rose-50 ring-1 ring-inset ring-rose-600/15">
                                    <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
                                    {{ exam.tidak_kumpul_count }} Tidak
                                </span>
                                <span class="text-xs text-slate-400 font-medium">dari {{ studentsCount }}</span>
                            </div>
                            <span v-else class="inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium text-slate-500 bg-slate-100">
                                Belum diisi
                            </span>
                        </td>
                        <td class="px-5 py-4 text-right">
                             <Link :href="route('exams.show', exam.id)" class="text-sm font-medium text-blue-600 hover:text-blue-900 hover:underline">Input Nilai &rarr;</Link>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <div v-if="filteredExams.length === 0" class="text-center py-12 p-4 border border-dashed border-slate-200 mt-4 rounded-xl mx-4 mb-4">
            <p class="text-slate-500">Belum ada ujian untuk kategori kelas ini di semester aktif.</p>
        </div>
    </Card>
  </div>
</template>
