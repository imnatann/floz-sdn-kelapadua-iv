<script setup>
import { Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';

defineOptions({ layout: TenantLayout });

defineProps({
    classes: Array,
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Nilai Ujian</h2>
        <p class="mt-0.5 text-sm text-slate-400">Pilih kelas untuk mengelola nilai Ulangan Harian, UTS, dan UAS</p>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Link 
            v-for="c in classes" :key="c.id" 
            :href="route('exams.class', c.id)"
            class="block group"
        >
            <Card class="p-6 transition-all hover:shadow-md hover:border-blue-200 border border-slate-200 cursor-pointer h-full flex flex-col justify-between">
                <div>
                    <h3 class="text-lg font-bold text-slate-900 group-hover:text-blue-600 transition-colors">{{ c.name }}</h3>
                    <p class="text-sm text-slate-500 mt-1">{{ c.students_count || 0 }} Siswa terdaftar</p>
                </div>
                <div class="mt-4 flex items-center text-sm font-medium text-blue-600">
                    Lihat Ujian
                    <svg class="w-4 h-4 ml-1 transition-transform group-hover:translate-x-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                </div>
            </Card>
        </Link>
    </div>

    <div v-if="classes.length === 0" class="text-center py-12 rounded-xl border border-dashed border-slate-200 bg-slate-50/50">
        <p class="text-slate-500">Anda belum ditugaskan untuk mengajar di kelas manapun.</p>
    </div>
  </div>
</template>
