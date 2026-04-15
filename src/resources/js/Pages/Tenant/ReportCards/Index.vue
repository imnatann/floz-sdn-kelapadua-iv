<script setup>
import { Link, Head, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  reportCards: Object,
  classes: Array,
  semesters: Array,
  filters: Object,
});

const classId = ref(props.filters?.class_id || '');
const semesterId = ref(props.filters?.semester_id || '');
const reportType = ref(props.filters?.report_type || 'final');
const generating = ref(false);

const applyFilters = () => {
  router.get('/report-cards', {
    class_id: classId.value, semester_id: semesterId.value, report_type: reportType.value, status: props.filters?.status
  }, { preserveState: true });
};

const generateReportCards = () => {
  if (!classId.value || !semesterId.value || !reportType.value) return;
  generating.value = true;
  router.post('/report-cards/generate', {
    class_id: classId.value, semester_id: semesterId.value, report_type: reportType.value
  }, { onFinish: () => generating.value = false });
};
</script>

<template>
  <Head title="Rapor Siswa" />
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Rapor Siswa</h2>
        <p class="mt-0.5 text-sm text-slate-400">Generate dan kelola rapor digital</p>
      </div>
      <Button
        @click="generateReportCards"
        :disabled="!classId || !semesterId || generating"
        :loading="generating"
        size="sm"
      >
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
        Generate Rapor
      </Button>
    </div>

    <!-- Filters -->
    <div class="flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="w-48">
        <FormSelect v-model="classId" label="Kelas" @change="applyFilters">
          <option value="">— Pilih —</option>
          <option v-for="c in classes" :key="c.id" :value="c.id">{{ c.name }}</option>
        </FormSelect>
      </div>
      <div class="w-56">
        <FormSelect v-model="semesterId" label="Semester" @change="applyFilters">
          <option value="">— Pilih —</option>
          <option v-for="s in semesters" :key="s.id" :value="s.id">Sem. {{ s.semester_number }} — {{ s.academic_year?.name }}</option>
        </FormSelect>
      </div>
      <div class="w-48">
        <FormSelect v-model="reportType" label="Tipe Rapor" @change="applyFilters">
          <option value="uts">Tengah Semester (UTS)</option>
          <option value="final">Akhir Semester (Final)</option>
        </FormSelect>
      </div>
    </div>

    <!-- Report Cards Table -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100 bg-slate-50/60">
              <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400 w-16">Rank</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Nama Siswa</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Kelas</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Rata-rata</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Status</th>
              <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="rc in reportCards.data" :key="rc.id" class="border-b border-slate-50 transition-colors hover:bg-slate-50/50">
              <td class="px-4 py-3 text-center">
                <div v-if="rc.rank && rc.rank <= 3" class="mx-auto flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold" :class="rc.rank === 1 ? 'bg-amber-100 text-amber-700' : rc.rank === 2 ? 'bg-slate-100 text-slate-600' : 'bg-orange-100 text-orange-700'">
                  {{ rc.rank }}
                </div>
                <span v-else-if="rc.rank" class="font-mono text-sm font-semibold text-slate-500">{{ rc.rank }}</span>
                <span v-else class="text-slate-300">—</span>
              </td>
              <td class="px-4 py-3">
                <div class="flex items-center gap-3">
                  <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-emerald-100 to-teal-100 text-xs font-semibold text-emerald-700">
                    {{ rc.student?.name?.charAt(0) }}
                  </div>
                  <div>
                    <span class="font-medium text-slate-700 block">{{ rc.student?.name }}</span>
                    <span class="text-xs text-slate-500">{{ rc.report_type === 'uts' ? 'Rapor UTS' : 'Rapor Final' }}</span>
                  </div>
                </div>
              </td>
              <td class="px-4 py-3 text-slate-500">{{ rc.school_class?.name }}</td>
              <td class="px-4 py-3">
                <span class="font-mono font-semibold text-slate-700">{{ rc.average_score ?? '—' }}</span>
              </td>
              <td class="px-4 py-3">
                <Badge :color="rc.status === 'published' ? 'emerald' : 'amber'" size="sm">
                  {{ rc.status === 'published' ? 'Diterbitkan' : 'Draft' }}
                </Badge>
              </td>
              <td class="px-4 py-3">
                <div class="flex items-center justify-end gap-1">
                  <Button :href="`/report-cards/${rc.id}`" variant="ghost" size="xs">Detail</Button>
                  <Link
                    v-if="rc.status === 'draft'"
                    :href="`/report-cards/${rc.id}/publish`"
                    method="post"
                    as="button"
                    class="rounded-lg px-2.5 py-1 text-xs font-medium text-emerald-600 transition-colors hover:bg-emerald-50"
                  >
                    Terbitkan
                  </Link>
                  <a :href="`/report-cards/${rc.id}/pdf`" class="rounded-lg px-2.5 py-1 text-xs font-medium text-slate-500 transition-colors hover:bg-slate-100">
                    PDF
                  </a>
                </div>
              </td>
            </tr>
            <tr v-if="!reportCards.data?.length">
              <td colspan="6" class="px-4 py-12 text-center">
                <div class="flex flex-col items-center gap-2">
                  <span class="text-3xl">📋</span>
                  <p class="text-sm font-medium text-slate-500">Belum ada rapor</p>
                  <p class="text-xs text-slate-400">Pilih kelas dan semester, lalu klik "Generate Rapor"</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="reportCards.links?.length > 3" class="flex justify-center gap-1">
      <template v-for="link in reportCards.links" :key="link.label">
        <Link
          v-if="link.url"
          :href="link.url"
          :class="[
            'flex h-8 min-w-[2rem] items-center justify-center rounded-lg px-3 text-xs font-medium transition-all',
            link.active
              ? 'bg-emerald-600 text-white shadow-sm'
              : 'bg-white text-slate-500 border border-slate-200 hover:bg-slate-50',
          ]"
          v-html="link.label"
        />
        <span v-else class="flex h-8 min-w-[2rem] items-center justify-center rounded-lg px-3 text-xs text-slate-300" v-html="link.label" />
      </template>
    </div>
  </div>
</template>
