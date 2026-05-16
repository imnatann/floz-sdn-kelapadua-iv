<script setup>
import { ref, computed, watch } from 'vue';
import { Link, router, usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Modal from '@/Components/UI/Modal.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    schoolClass: Object,
    exams: Array,
    subjects: { type: Array, default: () => [] },
    exportableSubjects: { type: Array, default: () => [] },
    semesters: { type: Array, default: () => [] },
    filters: { type: Object, default: () => ({}) },
    studentsCount: Number,
});

const page = usePage();
const userRole = computed(() => page.props.auth?.user?.role);
const isStudent = computed(() => userRole.value === 'student');
const isAdmin = computed(() => userRole.value === 'school_admin');
const canManage = computed(() => !isStudent.value);

const subjectId = ref(props.filters?.subject_id ?? '');
const semesterId = ref(props.filters?.semester_id ?? '');

const applyFilters = () => {
    router.get(
        route('exams.class', props.schoolClass.id),
        {
            subject_id:  subjectId.value || undefined,
            semester_id: semesterId.value || undefined,
        },
        { preserveState: true, preserveScroll: true, replace: true }
    );
};

watch([subjectId, semesterId], applyFilters);

// Excel export modal — pick which mapel(s) to include
const showExportModal = ref(false);
const exportSelectedIds = ref([]);

const openExportModal = () => {
    if (!semesterId.value) return;
    exportSelectedIds.value = props.exportableSubjects.map(s => s.id);
    showExportModal.value = true;
};

const toggleSelectAll = () => {
    if (exportSelectedIds.value.length === props.exportableSubjects.length) {
        exportSelectedIds.value = [];
    } else {
        exportSelectedIds.value = props.exportableSubjects.map(s => s.id);
    }
};

const confirmExport = () => {
    if (!semesterId.value || exportSelectedIds.value.length === 0) return;
    const params = new URLSearchParams();
    params.append('class_id', props.schoolClass.id);
    params.append('semester_id', semesterId.value);
    exportSelectedIds.value.forEach(id => params.append('subject_ids[]', id));
    window.location.href = `/analytics/export/grades?${params.toString()}`;
    showExportModal.value = false;
};

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

const formatDate = (raw) => {
    if (!raw) return '-';
    const d = new Date(raw);
    return Number.isNaN(d.getTime())
        ? raw
        : d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
};

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
      <div v-if="canManage" class="flex flex-wrap gap-2">
         <Button
            variant="outline"
            @click="openExportModal"
            :disabled="!semesterId || exportableSubjects.length === 0"
            :title="exportableSubjects.length === 0 ? 'Belum ada mapel di kelas ini — atur Penugasan Guru dulu' : 'Pilih mapel mana yang akan diunduh sebagai Excel'"
         >
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Unduh Excel
         </Button>
         <Link :href="route('exams.create', schoolClass.id)">
             <Button>
                Buat Ujian Baru
             </Button>
         </Link>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex flex-col gap-3 sm:flex-row">
      <div class="w-full sm:w-64">
        <FormSelect v-model="subjectId" label="Mata Pelajaran">
          <option value="">Semua Mapel</option>
          <option v-for="s in subjects" :key="s.id" :value="s.id">{{ s.name }}</option>
        </FormSelect>
      </div>
      <div class="w-full sm:w-72">
        <FormSelect v-model="semesterId" label="Semester">
          <option v-for="sem in semesters" :key="sem.id" :value="sem.id">
            Sem. {{ sem.semester_number }} — {{ sem.academic_year?.name }}{{ sem.is_active ? ' (Aktif)' : '' }}
          </option>
          <option v-if="!semesters.length" value="">Tidak ada data</option>
        </FormSelect>
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
                        <td class="px-5 py-4 font-medium text-slate-600">{{ formatDate(exam.exam_date) }}</td>
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
                             <Link :href="route('exams.show', exam.id)" class="text-sm font-medium text-blue-600 hover:text-blue-900 hover:underline">
                                {{ canManage ? 'Input Nilai' : 'Lihat Detail' }} &rarr;
                             </Link>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <div v-if="filteredExams.length === 0" class="text-center py-12 p-4 border border-dashed border-slate-200 mt-4 rounded-xl mx-4 mb-4">
            <p class="text-slate-500">Belum ada ujian untuk kategori kelas ini di semester aktif.</p>
        </div>
    </Card>

    <!-- Excel Export Modal: pick subjects via checkboxes -->
    <Modal :show="showExportModal" @close="showExportModal = false">
      <div class="p-6">
        <div class="mb-4">
          <h2 class="text-lg font-bold text-slate-800">Unduh Rekap Nilai Excel</h2>
          <p class="mt-0.5 text-sm text-slate-500">Pilih mata pelajaran yang akan dimasukkan. Setiap mapel jadi 1 sheet.</p>
        </div>

        <div class="mb-3 flex items-center justify-between border-b border-slate-100 pb-2">
          <span class="text-xs font-medium text-slate-500">{{ exportSelectedIds.length }} / {{ exportableSubjects.length }} mapel dipilih</span>
          <button
            type="button"
            @click="toggleSelectAll"
            class="text-xs font-medium text-orange-600 hover:text-orange-700 hover:underline"
          >
            {{ exportSelectedIds.length === exportableSubjects.length ? 'Hapus Semua' : 'Pilih Semua' }}
          </button>
        </div>

        <div class="max-h-[50vh] space-y-1 overflow-y-auto pr-1">
          <label
            v-for="s in exportableSubjects"
            :key="s.id"
            class="flex cursor-pointer items-center gap-3 rounded-md px-3 py-2 transition-colors hover:bg-slate-50"
          >
            <input
              type="checkbox"
              :value="s.id"
              v-model="exportSelectedIds"
              class="h-4 w-4 rounded border-slate-300 text-orange-600 focus:ring-orange-500"
            />
            <span class="text-sm text-slate-700">{{ s.name }}</span>
          </label>
          <p v-if="exportableSubjects.length === 0" class="py-8 text-center text-sm text-slate-400">Belum ada mapel di kelas ini.</p>
        </div>

        <div class="mt-5 flex justify-end gap-3 border-t border-slate-100 pt-4">
          <Button variant="outline" @click="showExportModal = false">Batal</Button>
          <Button @click="confirmExport" :disabled="exportSelectedIds.length === 0">
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Unduh {{ exportSelectedIds.length || '' }} Sheet
          </Button>
        </div>
      </div>
    </Modal>
  </div>
</template>
