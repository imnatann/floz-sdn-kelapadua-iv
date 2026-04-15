<script setup>
import { useForm, Head } from '@inertiajs/vue3';
import { computed } from 'vue';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  classRoom: Object,
  semester: Object,
  subject: Object,
  students: Array,
  existingGrades: Object,
});

const form = useForm({
  class_id: props.classRoom.id,
  semester_id: props.semester.id,
  subject_id: props.subject.id,
  grades: props.students.map(student => {
    const existing = props.existingGrades?.[student.id] || {};
    return {
      student_id: student.id,
      daily_test_avg: existing.daily_test_avg || '',
      mid_test: existing.mid_test || '',
      final_test: existing.final_test || '',
      knowledge_score: existing.knowledge_score || '',
      skill_score: existing.skill_score || '',
      notes: existing.notes || '',
    };
  }),
});

const isSD = computed(() => props.subject.education_level === 'SD');

// Helper to determine predicate based on score
const getPredicate = (score) => {
  if (score >= 90) return 'A';
  if (score >= 80) return 'B';
  if (score >= 70) return 'C';
  return 'D';
};

// Real-time calculation for Final Score
const getFinalScore = (gradeData) => {
  if (isSD.value) {
    const daily = parseFloat(gradeData.daily_test_avg) || 0;
    const mid = parseFloat(gradeData.mid_test) || 0;
    const final = parseFloat(gradeData.final_test) || 0;
    return (daily * 0.4 + mid * 0.3 + final * 0.3).toFixed(2);
  } else {
    const knowledge = parseFloat(gradeData.knowledge_score) || 0;
    const skill = parseFloat(gradeData.skill_score) || 0;
    return ((knowledge + skill) / 2).toFixed(2);
  }
};
const submit = () => form.post('/grades/batch');
</script>

<template>
  <Head :title="`Input Nilai — ${subject.name}`" />
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div class="flex items-center gap-4">
        <Button href="/grades" variant="outline" size="sm">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
          Kembali
        </Button>
        <div>
          <h2 class="text-xl font-bold text-slate-800">Input Nilai — {{ subject.name }}</h2>
          <p class="mt-0.5 text-sm text-slate-400">
            Kelas {{ classRoom.name }} · Semester {{ semester.semester_number }}
          </p>
        </div>
      </div>
    </div>

    <!-- Info Banner -->
    <div class="flex items-start gap-3 rounded-xl border border-emerald-200 bg-emerald-50 p-4">
      <svg class="mt-0.5 h-5 w-5 shrink-0 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      <div>
        <p class="text-sm font-medium text-emerald-800">{{ students.length }} siswa ditemukan</p>
        <p class="mt-0.5 text-xs text-emerald-600">Masukkan nilai untuk setiap siswa. Nilai yang sudah ada akan ditimpa.</p>
      </div>
    </div>

    <!-- Batch Input Table -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <form @submit.prevent="submit">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-10">#</th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Nama Siswa</th>
                <template v-if="isSD">
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Nilai Harian</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">UTS</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">UAS</th>
                </template>
                <template v-else>
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Pengetahuan (KI-3)</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Keterampilan (KI-4)</th>
                </template>
                <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-emerald-600 bg-emerald-50/50">Nilai Akhir (Preview)</th>
                <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-emerald-600 bg-emerald-50/50">Predikat</th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Catatan</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(gradeData, index) in form.grades" :key="gradeData.student_id" class="border-b border-slate-50 transition-colors hover:bg-slate-50/50">
                <td class="px-4 py-3 text-xs text-slate-400">{{ index + 1 }}</td>
                <td class="px-4 py-3">
                  <div class="flex items-center gap-2">
                    <div class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-emerald-100 to-teal-100 text-[10px] font-semibold text-emerald-700">
                      {{ students[index]?.name?.charAt(0) }}
                    </div>
                    <span class="whitespace-nowrap font-medium text-slate-700">{{ students[index]?.name }}</span>
                  </div>
                </td>
                <template v-if="isSD">
                  <td class="px-4 py-2">
                    <input v-model.number="gradeData.daily_test_avg" type="number" min="0" max="100" step="0.01" class="w-20 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
                  </td>
                  <td class="px-4 py-2">
                    <input v-model.number="gradeData.mid_test" type="number" min="0" max="100" step="0.01" class="w-20 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
                  </td>
                  <td class="px-4 py-2">
                    <input v-model.number="gradeData.final_test" type="number" min="0" max="100" step="0.01" class="w-20 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
                  </td>
                </template>
                <template v-else>
                  <td class="px-4 py-2">
                    <input v-model.number="gradeData.knowledge_score" type="number" min="0" max="100" step="0.01" class="w-20 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
                  </td>
                  <td class="px-4 py-2">
                    <input v-model.number="gradeData.skill_score" type="number" min="0" max="100" step="0.01" class="w-20 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
                  </td>
                </template>
                <td class="px-4 py-2 text-center bg-emerald-50/30">
                  <span class="font-mono font-bold text-slate-800">{{ getFinalScore(gradeData) }}</span>
                </td>
                <td class="px-4 py-2 text-center bg-emerald-50/30">
                  <span class="inline-flex items-center justify-center w-6 h-6 rounded-full text-xs font-bold"
                    :class="[
                      getPredicate(getFinalScore(gradeData)) === 'A' ? 'bg-emerald-100 text-emerald-700' :
                      getPredicate(getFinalScore(gradeData)) === 'B' ? 'bg-blue-100 text-blue-700' :
                      getPredicate(getFinalScore(gradeData)) === 'C' ? 'bg-amber-100 text-amber-700' :
                      'bg-red-100 text-red-700'
                    ]"
                  >
                    {{ getPredicate(getFinalScore(gradeData)) }}
                  </span>
                </td>
                <td class="px-4 py-2">
                  <input v-model="gradeData.notes" type="text" placeholder="Opsional" class="w-32 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Actions -->
        <div class="flex items-center justify-between border-t border-slate-100 px-6 py-4">
          <p class="text-xs text-slate-400">{{ form.grades.length }} siswa</p>
          <div class="flex gap-3">
            <Button href="/grades" variant="ghost">Batal</Button>
            <Button type="submit" :loading="form.processing">
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Simpan Semua Nilai
            </Button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
