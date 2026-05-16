<script setup>
import { Link, router } from '@inertiajs/vue3';
import { ref, watch } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';
import Card from '@/Components/UI/Card.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
  classes: Array,
  academicYears: { type: Array, default: () => [] },
  filters: { type: Object, default: () => ({}) },
});

const academicYearId = ref(props.filters?.academic_year_id ?? '');

watch(academicYearId, () => {
  router.get(
    '/tasks',
    { academic_year_id: academicYearId.value || undefined },
    { preserveState: true, preserveScroll: true, replace: true }
  );
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Tugas & Nilai</h2>
        <p class="mt-0.5 text-sm text-slate-400">Pilih kelas untuk mengelola tugas dan menginput nilai siswa</p>
      </div>
      <div class="w-full sm:w-72">
        <FormSelect v-model="academicYearId" label="Tahun Ajaran">
          <option v-for="ay in academicYears" :key="ay.id" :value="ay.id">{{ ay.name }}{{ ay.is_active ? ' (Aktif)' : '' }}</option>
        </FormSelect>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <Link
        v-for="c in classes" :key="c.id"
        :href="route('tasks.class', c.id)"
        class="block group"
      >
        <Card class="p-6 transition-all hover:shadow-md hover:border-orange-200 border border-slate-200 cursor-pointer h-full flex flex-col justify-between">
          <div>
            <div class="flex items-start justify-between gap-2">
              <h3 class="text-lg font-bold text-slate-900 group-hover:text-orange-600 transition-colors">{{ c.name }}</h3>
              <span v-if="c.academic_year?.name" class="shrink-0 inline-flex items-center rounded-md bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-600">
                {{ c.academic_year.name }}{{ c.academic_year.is_active ? ' · Aktif' : '' }}
              </span>
            </div>
            <p class="text-sm text-slate-500 mt-1">{{ c.students_count || 0 }} Siswa terdaftar</p>
          </div>
          <div class="mt-4 flex items-center text-sm font-medium text-orange-600">
            Lihat Tugas
            <svg class="w-4 h-4 ml-1 transition-transform group-hover:translate-x-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </div>
        </Card>
      </Link>
    </div>

    <div v-if="classes.length === 0" class="text-center py-12 rounded-xl border border-dashed border-slate-200 bg-slate-50/50">
      <p class="text-slate-500">Tidak ada kelas untuk tahun ajaran yang dipilih.</p>
    </div>
  </div>
</template>
