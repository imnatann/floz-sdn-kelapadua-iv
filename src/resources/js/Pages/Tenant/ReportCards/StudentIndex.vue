<script setup>
import { Link, Head, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  semesters: Array,
  grades: Array,
  reportCard: Object,
  filters: Object,
});

const semesterId = ref(props.filters?.semester_id || '');
const activeTab = ref('bayangan'); // 'bayangan' or 'final'

const applyFilters = () => {
  router.get('/report-cards', {
    semester_id: semesterId.value,
  }, { preserveState: true });
};
</script>

<template>
  <Head title="Rapor Saya" />
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Rapor Saya</h2>
        <p class="mt-0.5 text-sm text-slate-400">Lihat nilai akademik per semester</p>
      </div>
    </div>

    <!-- Filters & Tabs -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="w-full md:w-56">
        <FormSelect v-model="semesterId" label="Pilih Semester" @change="applyFilters">
          <option v-if="!semesters.length" value="">— Belum ada data —</option>
          <option v-for="s in semesters" :key="s.id" :value="s.id">
            Sem. {{ s.semester_number }} — {{ s.academic_year?.name }}
          </option>
        </FormSelect>
      </div>

      <!-- Tab Navigation -->
      <div class="flex p-1 space-x-1 bg-slate-100/80 rounded-xl">
        <button
          @click="activeTab = 'bayangan'"
          :class="[
            'px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200',
            activeTab === 'bayangan' 
              ? 'bg-white text-orange-600 shadow-sm border border-slate-200/50' 
              : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'
          ]"
        >
          Rapor Bayangan (UTS)
        </button>
        <button
          @click="activeTab = 'final'"
          :class="[
            'px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200',
            activeTab === 'final' 
              ? 'bg-white text-orange-600 shadow-sm border border-slate-200/50' 
              : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'
          ]"
        >
          Rapor Final (UAS)
        </button>
      </div>
    </div>

    <!-- Content: Rapor Bayangan (Midterm) -->
    <div v-show="activeTab === 'bayangan'" class="space-y-4">
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th class="px-4 py-3 text-left w-12 text-xs font-semibold uppercase tracking-wider text-slate-400">No</th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Mata Pelajaran</th>
                <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400">Nilai Harian</th>
                <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400">Nilai UTS</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(grade, index) in grades" :key="grade.id" class="border-b border-slate-50 transition-colors hover:bg-slate-50/50">
                <td class="px-4 py-3 text-slate-400">{{ index + 1 }}</td>
                <td class="px-4 py-3 font-medium text-slate-700">{{ grade.subject?.name }}</td>
                <td class="px-4 py-3 text-center">
                  <span class="font-mono font-semibold" :class="grade.daily_test_avg ? 'text-slate-700' : 'text-slate-300'">
                    {{ grade.daily_test_avg ?? '-' }}
                  </span>
                </td>
                <td class="px-4 py-3 text-center">
                  <span class="font-mono font-semibold" :class="grade.mid_test ? 'text-slate-700' : 'text-slate-300'">
                    {{ grade.mid_test ?? '-' }}
                  </span>
                </td>
              </tr>
              <tr v-if="!grades.length">
                <td colspan="4" class="px-4 py-12 text-center">
                  <div class="flex flex-col items-center gap-2">
                    <span class="text-3xl text-slate-300">📝</span>
                    <p class="text-sm font-medium text-slate-500">Pilih semester terlebih dahulu atau belum ada nilai</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <p class="text-xs text-slate-400 px-1">
        *Rapor Bayangan berisi rekapitulasi nilai harian dan nilai Ujian Tengah Semester (UTS) yang sudah di-input oleh guru.
      </p>
    </div>

    <!-- Content: Rapor Final (End of Term) -->
    <div v-show="activeTab === 'final'" class="space-y-6">
      <!-- Published / Empty State -->
      <div v-if="reportCard && reportCard.status === 'published'" class="space-y-6">
        
        <!-- Summary Card -->
        <div class="bg-gradient-to-br from-orange-500 to-orange-600 rounded-2xl shadow-md p-6 text-white overflow-hidden relative">
          <!-- Decorative Background Elements -->
          <div class="absolute top-0 right-0 p-8 opacity-10 pointer-events-none">
            <svg class="w-32 h-32 transform rotate-12" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/></svg>
          </div>
          
          <div class="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div>
              <div class="flex items-center gap-2 mb-1">
                <Badge class="bg-white/20 text-white border-none backdrop-blur-sm">Rapor Diterbitkan</Badge>
                <span class="text-orange-100 text-sm hidden md:inline">•</span>
                <span class="text-orange-100 text-sm">{{ new Date(reportCard.published_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' }) }}</span>
              </div>
              <h3 class="text-2xl font-bold mt-2">{{ reportCard.school_class?.name }}</h3>
              <p class="text-orange-100 mt-1">Wali Kelas: {{ reportCard.school_class?.homeroom_teacher?.name ?? '-' }}</p>
            </div>
            
            <div class="flex items-center gap-6 bg-white/10 p-4 rounded-xl backdrop-blur-sm w-full md:w-auto">
              <div class="text-center">
                <p class="text-orange-200 text-xs font-medium uppercase tracking-wider mb-1">Peringkat</p>
                <p class="text-3xl font-bold font-mono">{{ reportCard.rank ?? '-' }}</p>
              </div>
              <div class="w-px h-10 bg-white/20"></div>
              <div class="text-center">
                <p class="text-orange-200 text-xs font-medium uppercase tracking-wider mb-1">Rata-rata</p>
                <p class="text-3xl font-bold font-mono">{{ reportCard.average_score ?? '-' }}</p>
              </div>
              <div class="w-px h-10 bg-white/20 hidden md:block"></div>
              <div class="text-center hidden md:block">
                <p class="text-orange-200 text-xs font-medium uppercase tracking-wider mb-1">Kehadiran</p>
                <p class="text-xl font-bold mt-2">{{ reportCard.attendance_present ?? 0 }}H</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Notes Card -->
        <div v-if="reportCard.notes || reportCard.homeroom_comment" class="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
           <h4 class="text-sm font-bold text-slate-700 uppercase tracking-wider mb-3 flex items-center gap-2">
             <svg class="w-4 h-4 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"></path></svg>
             Catatan Wali Kelas
           </h4>
           <p class="text-slate-600 text-sm whitespace-pre-wrap">{{ reportCard.homeroom_comment || reportCard.notes }}</p>
        </div>

        <!-- Grades Table -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Mata Pelajaran</th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400">Pengetahuan</th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400">Keterampilan</th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400">Nilai Akhir</th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400">Predikat</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="grade in grades" :key="grade.id" class="border-b border-slate-50 transition-colors hover:bg-slate-50/50">
                  <td class="px-4 py-3 font-medium text-slate-700">{{ grade.subject?.name }}</td>
                  <td class="px-4 py-3 text-center text-slate-600 font-mono">{{ grade.knowledge_score ?? '-' }}</td>
                  <td class="px-4 py-3 text-center text-slate-600 font-mono">{{ grade.skill_score ?? '-' }}</td>
                  <td class="px-4 py-3 text-center">
                    <span class="font-mono font-bold text-slate-800">{{ grade.final_score ?? '-' }}</span>
                  </td>
                  <td class="px-4 py-3 text-center">
                    <Badge v-if="grade.predicate" :variant="['A', 'A+', 'A-'].includes(grade.predicate) ? 'success' : (['B', 'B+', 'B-'].includes(grade.predicate) ? 'primary' : 'warning')">{{ grade.predicate }}</Badge>
                    <span v-else class="text-slate-400">-</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        
        <div class="flex justify-end pt-2">
            <a :href="`/report-cards/${reportCard.id}/pdf`" target="_blank" class="inline-flex items-center justify-center gap-2 rounded-xl bg-slate-900 px-6 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-slate-800 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-slate-900 focus:ring-offset-2">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                Download PDF
            </a>
        </div>

      </div>

      <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
        <div class="w-16 h-16 mx-auto bg-slate-50 rounded-2xl flex items-center justify-center mb-4">
          <svg class="w-8 h-8 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>
        </div>
        <h3 class="text-lg font-semibold text-slate-700 mb-1">Rapor Belum Tersedia</h3>
        <p class="text-sm text-slate-500 max-w-sm mx-auto">Rapor final untuk semester ini belum diterbitkan oleh pihak sekolah atau wali kelas.</p>
      </div>
    </div>

  </div>
</template>
