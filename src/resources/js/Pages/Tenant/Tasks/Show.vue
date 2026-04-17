<script setup>
import { useForm, Link, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  task: Object,
  students: Array,
  scores: Object,
});

const formatDate = (raw) => {
    if (!raw) return '-';
    const d = new Date(raw);
    return Number.isNaN(d.getTime())
        ? raw
        : d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
};

const STATUS_OPTIONS = [
  { value: 'kumpul',       label: 'Kumpul',       activeClass: 'bg-emerald-500 text-white shadow-sm' },
  { value: 'terlambat',    label: 'Telat',        activeClass: 'bg-amber-500 text-white shadow-sm' },
  { value: 'tidak_kumpul', label: 'Tidak Kumpul', activeClass: 'bg-rose-500 text-white shadow-sm' },
];

const form = useForm({
  scores: props.students.map(s => {
      const existing = props.scores[s.id];
      return {
          student_id: s.id,
          score: existing ? existing.score : null,
          notes: existing ? existing.notes : '',
          submission_status: existing?.submission_status || 'kumpul',
      };
  }),
});

const setStatus = (idx, value) => {
    form.scores[idx].submission_status = value;
    if (value === 'tidak_kumpul') {
        form.scores[idx].score = null;
    }
};

const submit = () => {
  form.post(route('tasks.scores.store', props.task.id), {
      preserveScroll: true,
  });
};

const destroy = () => {
    if (confirm('Apakah Anda yakin ingin menghapus tugas ini? Semua data nilai akan ikut terhapus.')) {
        router.delete(route('tasks.destroy', props.task.id));
    }
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <div class="flex items-center gap-2 mb-1">
            <Link :href="route('tasks.index')" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Tugas & Nilai</Link>
            <span class="text-slate-300">/</span>
            <Link :href="route('tasks.class', task.class_id)" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Kelas {{ task.school_class?.name }}</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">{{ task.title }}</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Input Nilai Tugas</h2>
      </div>
      <div class="flex gap-2">
         <Button variant="danger" outline @click="destroy">
            Hapus Tugas
         </Button>
         <Button :disabled="form.processing" @click="submit">
            Simpan Nilai
         </Button>
      </div>
    </div>

    <Card class="p-6 border-t-4 border-t-orange-500 border-x-0 border-b-0 rounded-t-lg bg-orange-50/30">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
                <h3 class="text-lg font-bold text-slate-900">{{ task.title }}</h3>
                <p class="text-sm font-medium text-slate-600 mt-1">{{ task.subject?.name }}</p>
                <div class="mt-4 text-sm text-slate-700">
                    <p class="mb-1"><span class="font-medium text-slate-500 inline-block w-32">Diberikan pada:</span> {{ formatDate(task.task_date) }}</p>
                    <p class="mb-1"><span class="font-medium text-slate-500 inline-block w-32">Batas waktu:</span> {{ formatDate(task.due_date) }}</p>
                    <p><span class="font-medium text-slate-500 inline-block w-32">Nilai Maksimal:</span> {{ task.max_score }}</p>
                </div>
            </div>
            <div v-if="task.description">
                <p class="text-sm font-medium text-slate-500 mb-1">Deskripsi Tugas</p>
                <p class="text-sm text-slate-700 whitespace-pre-wrap">{{ task.description }}</p>
            </div>
        </div>
    </Card>

    <Card class="overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-sm text-left">
                <thead class="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100">
                    <tr>
                        <th class="px-5 py-3 w-12 text-center">No</th>
                        <th class="px-5 py-3">Nama Siswa</th>
                        <th class="px-5 py-3" style="width: 280px">Status Pengumpulan</th>
                        <th class="px-5 py-3 text-right" style="width: 130px">Nilai (Maks: {{ task.max_score }})</th>
                        <th class="px-5 py-3">Catatan Opsional</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(student, index) in students" :key="student.id" class="bg-white border-b border-slate-50 hover:bg-slate-50/50">
                        <td class="px-5 py-4 font-mono text-slate-500 text-center">{{ index + 1 }}</td>
                        <td class="px-5 py-4 font-medium text-slate-900">{{ student.name }}</td>
                        <td class="px-5 py-4">
                            <div class="inline-flex rounded-lg bg-slate-100 p-0.5 text-xs font-medium" role="group">
                                <button
                                    v-for="opt in STATUS_OPTIONS"
                                    :key="opt.value"
                                    type="button"
                                    @click="setStatus(index, opt.value)"
                                    class="px-3 py-1.5 rounded-md transition-all"
                                    :class="form.scores[index].submission_status === opt.value
                                        ? opt.activeClass
                                        : 'text-slate-600 hover:text-slate-900'"
                                >
                                    {{ opt.label }}
                                </button>
                            </div>
                        </td>
                        <td class="px-5 py-4">
                            <input
                                type="number"
                                v-model="form.scores[index].score"
                                :disabled="form.scores[index].submission_status === 'tidak_kumpul'"
                                class="block w-full text-right rounded-md py-1.5 text-slate-900 shadow-sm ring-1 ring-inset placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
                                :class="[
                                    form.scores[index].score > task.max_score ? 'ring-red-300 border-red-300 focus:ring-red-500 text-red-600 bg-red-50' : 'ring-slate-300 border-0',
                                    form.scores[index].submission_status === 'tidak_kumpul' ? 'bg-slate-50 text-slate-400 cursor-not-allowed' : '',
                                ]"
                                :max="task.max_score"
                                min="0"
                                step="0.01"
                                :placeholder="form.scores[index].submission_status === 'tidak_kumpul' ? '—' : '0'"
                            >
                        </td>
                        <td class="px-5 py-4">
                            <input type="text" v-model="form.scores[index].notes" class="block w-full rounded-md border-0 py-1.5 text-slate-900 shadow-sm ring-1 ring-inset ring-slate-300 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-xs sm:leading-6" placeholder="Bagus...">
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <div v-if="students.length === 0" class="text-center py-12">
            <p class="text-slate-500">Tidak ada siswa di kelas ini.</p>
        </div>
        
        <div class="p-4 border-t border-slate-100 bg-slate-50 flex justify-end" v-if="students.length > 0">
             <Button :disabled="form.processing" @click="submit">
                Simpan Nilai
             </Button>
        </div>
    </Card>
  </div>
</template>
