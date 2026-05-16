<script setup>
import { Head, router, usePage } from '@inertiajs/vue3';
import { ref, computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
  academicYears: { type: Array, default: () => [] },
  classes: Array,
  semesters: Array,
  subjects: Array,
  grades: { type: Array, default: null },
  filters: Object,
});

const page = usePage();
const isStudent = computed(() => page.props.auth?.user?.role === 'student');
const canManage = computed(() => !isStudent.value);

const academicYearId = ref(props.filters?.academic_year_id || '');
const classId = ref(props.filters?.class_id || '');
const semesterId = ref(props.filters?.semester_id || '');
const subjectId = ref(props.filters?.subject_id || '');

const applyFilters = () => {
  router.get('/grades', {
    academic_year_id: academicYearId.value,
    class_id: classId.value,
    semester_id: semesterId.value,
    subject_id: subjectId.value,
  }, { preserveState: true });
};

const changeAcademicYear = () => {
  classId.value = '';
  semesterId.value = '';
  applyFilters();
};

const openBatchInput = () => {
  if (!classId.value || !semesterId.value || !subjectId.value) return;
  router.get('/grades/batch', {
    class_id: classId.value, semester_id: semesterId.value, subject_id: subjectId.value,
  });
};

const downloadExcel = () => {
  if (!classId.value || !semesterId.value) return;
  const params = new URLSearchParams();
  params.append('class_id', classId.value);
  params.append('semester_id', semesterId.value);
  if (subjectId.value) params.append('subject_id', subjectId.value);
  window.location.href = `/analytics/export/grades?${params.toString()}`;
};

const predicateColor = (p) => p === 'A' ? 'emerald' : p === 'B' ? 'blue' : p === 'C' ? 'amber' : 'rose';
</script>

<template>
  <Head title="Nilai Siswa" />
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Nilai Siswa</h2>
        <p class="mt-0.5 text-sm text-slate-400">{{ canManage ? 'Lihat dan input nilai siswa per kelas' : 'Lihat nilai Anda per kelas dan mata pelajaran' }}</p>
      </div>
      <div class="flex flex-wrap gap-2">
        <Button
          v-if="canManage"
          variant="outline"
          @click="downloadExcel"
          :disabled="!classId || !semesterId"
          size="sm"
          title="Unduh rekap nilai dalam format Excel — per kelas, per semester, per mapel (atau semua mapel)"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
          Unduh Excel
        </Button>
        <Button
          v-if="canManage"
          @click="openBatchInput"
          :disabled="!classId || !semesterId || !subjectId"
          size="sm"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
          Input Nilai
        </Button>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="w-56">
        <FormSelect v-model="academicYearId" label="Tahun Ajaran" @change="changeAcademicYear">
          <option value="">— Pilih Tahun —</option>
          <option v-for="ay in academicYears" :key="ay.id" :value="ay.id">
            {{ ay.name }}{{ ay.is_active ? ' (Aktif)' : '' }}
          </option>
        </FormSelect>
      </div>
      <div class="w-56">
        <FormSelect v-model="classId" label="Kelas" @change="applyFilters">
          <option value="">— Pilih Kelas —</option>
          <option v-for="c in classes" :key="c.id" :value="c.id">{{ c.name }} {{ c.academic_year ? `(${c.academic_year.name})` : '' }}</option>
        </FormSelect>
      </div>
      <div class="w-56">
        <FormSelect v-model="semesterId" label="Semester" @change="applyFilters">
          <option value="">— Pilih Semester —</option>
          <option v-for="s in semesters" :key="s.id" :value="s.id">Sem. {{ s.semester_number }} — {{ s.academic_year?.name }}</option>
        </FormSelect>
      </div>
      <div class="w-48">
        <FormSelect v-model="subjectId" label="Mata Pelajaran" @change="applyFilters">
          <option value="">Semua</option>
          <option v-for="s in subjects" :key="s.id" :value="s.id">{{ s.name }}</option>
        </FormSelect>
      </div>
    </div>

    <!-- Grades Table -->
    <div v-if="grades !== null" class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100 bg-slate-50/60">
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Nama Siswa</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Mata Pelajaran</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Nilai Akhir</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Predikat</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Guru</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="grade in grades" :key="grade.id" class="border-b border-slate-50 transition-colors hover:bg-slate-50/50">
              <td class="px-4 py-3">
                <div class="flex items-center gap-3">
                  <div class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-emerald-100 to-teal-100 text-[10px] font-semibold text-emerald-700">
                    {{ grade.student?.name?.charAt(0) }}
                  </div>
                  <span class="font-medium text-slate-700">{{ grade.student?.name }}</span>
                </div>
              </td>
              <td class="px-4 py-3 text-slate-500">{{ grade.subject?.name }}</td>
              <td class="px-4 py-3">
                <span class="font-mono font-semibold text-slate-700">{{ grade.final_score ?? '—' }}</span>
              </td>
              <td class="px-4 py-3">
                <Badge v-if="grade.predicate" :color="predicateColor(grade.predicate)" size="sm">{{ grade.predicate }}</Badge>
                <span v-else class="text-slate-300">—</span>
              </td>
              <td class="px-4 py-3 text-xs text-slate-400">{{ grade.teacher?.name || '—' }}</td>
            </tr>
            <tr v-if="!grades?.length">
              <td colspan="5" class="px-4 py-12 text-center">
                <div class="flex flex-col items-center gap-2">
                  <span class="text-3xl">📝</span>
                  <p class="text-sm font-medium text-slate-500">Belum ada nilai</p>
                  <p class="text-xs text-slate-400">Silakan input nilai terlebih dahulu</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Empty State: No filter selected -->
    <div v-else class="flex flex-col items-center gap-3 rounded-xl border border-dashed border-slate-300 bg-white py-16 shadow-sm">
      <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-100 text-2xl">📊</div>
      <p class="text-sm font-medium text-slate-500">Pilih kelas dan semester untuk melihat data nilai</p>
      <p class="text-xs text-slate-400">Gunakan filter di atas untuk menampilkan data</p>
    </div>
  </div>
</template>
