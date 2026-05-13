<script setup>
import { ref, computed, watch } from 'vue';
import { Link, router, usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    schoolClass: Object,
    tasks: Array,
    subjects: { type: Array, default: () => [] },
    semesters: { type: Array, default: () => [] },
    filters: { type: Object, default: () => ({}) },
    studentsCount: Number,
});

const page = usePage();
const isStudent = computed(() => page.props.auth?.user?.role === 'student');
const canManage = computed(() => !isStudent.value);

const subjectId = ref(props.filters?.subject_id ?? '');
const semesterId = ref(props.filters?.semester_id ?? '');

const applyFilters = () => {
    router.get(
        route('tasks.class', props.schoolClass.id),
        {
            subject_id:  subjectId.value || undefined,
            semester_id: semesterId.value || undefined,
        },
        { preserveState: true, preserveScroll: true, replace: true }
    );
};

watch([subjectId, semesterId], applyFilters);

const downloadExcel = () => {
    if (!semesterId.value) return;
    const params = new URLSearchParams();
    params.append('class_id', props.schoolClass.id);
    params.append('semester_id', semesterId.value);
    if (subjectId.value) params.append('subject_id', subjectId.value);
    window.location.href = `/analytics/export/grades?${params.toString()}`;
};

const formatDate = (raw) => {
    if (!raw) return '-';
    const d = new Date(raw);
    return Number.isNaN(d.getTime())
        ? raw
        : d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <div class="flex items-center gap-2 mb-1">
            <Link :href="route('tasks.index')" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Tugas & Nilai</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">Kelas {{ schoolClass.name }}</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Daftar Tugas Kelas {{ schoolClass.name }}</h2>
      </div>
      <div v-if="canManage" class="flex flex-wrap gap-2">
         <Button
            variant="outline"
            @click="downloadExcel"
            :disabled="!semesterId"
            title="Unduh rekap nilai Excel — per mapel (atau semua mapel) untuk kelas dan semester yang dipilih"
         >
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Unduh Excel
         </Button>
         <Link :href="route('tasks.create', schoolClass.id)">
             <Button>
                Buat Tugas Baru
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

    <Card class="overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-sm text-left">
                <thead class="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100">
                    <tr>
                        <th class="px-5 py-3">Judul Tugas</th>
                        <th class="px-5 py-3">Mata Pelajaran</th>
                        <th class="px-5 py-3">Tanggal Diberikan</th>
                        <th class="px-5 py-3">Pengumpulan</th>
                        <th class="px-5 py-3">Status</th>
                        <th class="px-5 py-3 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="task in tasks" :key="task.id" class="bg-white border-b border-slate-50 hover:bg-slate-50/50">
                        <td class="px-5 py-4 font-bold text-slate-900">{{ task.title }}</td>
                        <td class="px-5 py-4 font-medium text-slate-600">{{ task.subject.name }}</td>
                        <td class="px-5 py-4 font-medium text-slate-600">{{ formatDate(task.task_date) }}</td>
                        <td class="px-5 py-4">
                            <div v-if="task.scores_count > 0" class="flex flex-wrap gap-1.5 items-center">
                                <span v-if="task.kumpul_count > 0" class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold text-emerald-700 bg-emerald-50 ring-1 ring-inset ring-emerald-600/15">
                                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                    {{ task.kumpul_count }} Kumpul
                                </span>
                                <span v-if="task.terlambat_count > 0" class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold text-amber-700 bg-amber-50 ring-1 ring-inset ring-amber-600/15">
                                    <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                                    {{ task.terlambat_count }} Telat
                                </span>
                                <span v-if="task.tidak_kumpul_count > 0" class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold text-rose-700 bg-rose-50 ring-1 ring-inset ring-rose-600/15">
                                    <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
                                    {{ task.tidak_kumpul_count }} Tidak
                                </span>
                                <span class="text-xs text-slate-400 font-medium">dari {{ studentsCount }}</span>
                            </div>
                            <span v-else class="inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium text-slate-500 bg-slate-100">
                                Belum diisi
                            </span>
                        </td>
                        <td class="px-5 py-4">
                            <span v-if="task.status === 'graded'" class="inline-flex items-center gap-1.5 rounded-full px-2 py-1 text-xs font-medium text-emerald-700 bg-emerald-50 ring-1 ring-inset ring-emerald-600/20">
                                Sudah Dinilai
                            </span>
                            <span v-else class="inline-flex items-center gap-1.5 rounded-full px-2 py-1 text-xs font-medium text-amber-700 bg-amber-50 ring-1 ring-inset ring-amber-600/20">
                                Belum Dinilai
                            </span>
                        </td>
                        <td class="px-5 py-4 text-right">
                             <Link :href="route('tasks.show', task.id)" class="text-sm font-medium text-orange-600 hover:text-orange-900 hover:underline">
                                {{ canManage ? 'Input Nilai' : 'Lihat Detail' }} &rarr;
                             </Link>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div v-if="tasks.length === 0" class="text-center py-12 p-4 border border-dashed border-slate-200 mt-4 rounded-xl mx-4 mb-4">
            <p class="text-slate-500">Belum ada tugas yang cocok dengan filter ini.</p>
        </div>
    </Card>
  </div>
</template>
