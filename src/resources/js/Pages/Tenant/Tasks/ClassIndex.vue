<script setup>
import { Link, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

defineProps({
    schoolClass: Object,
    tasks: Array,
    studentsCount: Number,
});

const progressColor = (count) => {
    if (count === 0) return 'text-slate-400 bg-slate-100';
    // Accessing reactive prop studentsCount directly in the template avoids passing 'this'
    return 'text-emerald-700 bg-emerald-100'; 
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
      <div>
         <Link :href="route('tasks.create', schoolClass.id)">
             <Button>
                Buat Tugas Baru
             </Button>
         </Link>
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
                        <th class="px-5 py-3 text-center">Progress Penilaian</th>
                        <th class="px-5 py-3">Status</th>
                        <th class="px-5 py-3 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="task in tasks" :key="task.id" class="bg-white border-b border-slate-50 hover:bg-slate-50/50">
                        <td class="px-5 py-4 font-bold text-slate-900">{{ task.title }}</td>
                        <td class="px-5 py-4 font-medium text-slate-600">{{ task.subject.name }}</td>
                        <td class="px-5 py-4 font-medium text-slate-600">{{ task.task_date }}</td>
                        <td class="px-5 py-4 text-center">
                            <span :class="['px-2.5 py-1 rounded-full text-xs font-bold', progressColor(task.scores_count)]">
                                {{ task.scores_count }} / {{ studentsCount }}
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
                             <Link :href="route('tasks.show', task.id)" class="text-sm font-medium text-orange-600 hover:text-orange-900 hover:underline">Input Nilai &rarr;</Link>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <div v-if="tasks.length === 0" class="text-center py-12 p-4 border border-dashed border-slate-200 mt-4 rounded-xl mx-4 mb-4">
            <p class="text-slate-500">Belum ada tugas untuk kelas ini di semester aktif.</p>
        </div>
    </Card>
  </div>
</template>
