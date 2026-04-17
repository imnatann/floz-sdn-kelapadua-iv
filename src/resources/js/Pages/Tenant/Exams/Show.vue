<script setup>
import { useForm, Link, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  exam: Object,
  students: Array,
  scores: Object,
});

const STATUS_OPTIONS = [
  { value: 'kumpul',       label: 'Hadir',       activeClass: 'bg-emerald-500 text-white shadow-sm' },
  { value: 'terlambat',    label: 'Telat',       activeClass: 'bg-amber-500 text-white shadow-sm' },
  { value: 'tidak_kumpul', label: 'Tidak Hadir', activeClass: 'bg-rose-500 text-white shadow-sm' },
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
  form.post(route('exams.scores.store', props.exam.id), {
      preserveScroll: true,
  });
};

const destroy = () => {
    if (confirm('Apakah Anda yakin ingin menghapus ujian ini? Semua data nilai akan ikut terhapus permanen.')) {
        router.delete(route('exams.destroy', props.exam.id));
    }
};

const examTypeBadge = (type) => {
    switch(type) {
        case 'ulangan_harian': return 'bg-emerald-100 text-emerald-800 ring-emerald-600/20';
        case 'uts': return 'bg-amber-100 text-amber-800 ring-amber-600/20';
        case 'uas': return 'bg-rose-100 text-rose-800 ring-rose-600/20';
        default: return 'bg-slate-100 text-slate-800 ring-slate-600/20';
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
            <Link :href="route('exams.class', exam.class_id)" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Kelas {{ exam.school_class?.name }}</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">{{ exam.title }}</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Input Nilai Ujian</h2>
      </div>
      <div class="flex gap-2">
         <Button variant="danger" outline @click="destroy">
            Hapus Ujian
         </Button>
         <Button :disabled="form.processing" @click="submit">
            Simpan Nilai
         </Button>
      </div>
    </div>

    <Card class="p-6 border-t-4 border-t-blue-500 border-x-0 border-b-0 rounded-t-lg bg-blue-50/30">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
                <div class="flex items-center gap-3">
                    <h3 class="text-lg font-bold text-slate-900">{{ exam.title }}</h3>
                    <span :class="['inline-flex items-center px-2 py-1 rounded text-xs font-bold ring-1 ring-inset', examTypeBadge(exam.exam_type)]">
                        {{ examTypeLabel(exam.exam_type) }}
                    </span>
                </div>
                <p class="text-sm font-medium text-slate-600 mt-1">{{ exam.subject?.name }}</p>
                
                <div class="mt-4 text-sm text-slate-700">
                    <p class="mb-1"><span class="font-medium text-slate-500 inline-block w-36">Tanggal Pelaksanaan:</span> <span class="font-bold">{{ exam.exam_date }}</span></p>
                    <p><span class="font-medium text-slate-500 inline-block w-36">Nilai Maksimal:</span> {{ exam.max_score }}</p>
                </div>
            </div>
            <div class="bg-white p-4 rounded-lg border border-slate-200 self-start">
                <p class="text-xs font-medium text-slate-500 mb-2 uppercase">Informasi Penilaian</p>
                <p class="text-sm text-slate-600" v-if="exam.exam_type === 'ulangan_harian'">
                    Nilai Ulangan Harian (Asesmen Formatif) digunakan untuk mengevaluasi pemahaman siswa per bab materi dan <strong class="text-slate-800">tidak dimasukkan</strong> ke dalam hitungan otomatis rapor akhir semester berdasar aturan Kurikulum Merdeka terbaru.
                </p>
                <p class="text-sm text-slate-600" v-else-if="exam.exam_type === 'uts'">
                    Nilai sumatif ini (ASLM) adalah komponen penting perhitungan rapor. Rata-rata dari nilai-nilai UTS/ASLM akan digunakan dalam proporsi <strong class="text-slate-800">50%</strong> (menurut formula) pembentuk Rapor Akhir.
                </p>
                <p class="text-sm text-slate-600" v-else-if="exam.exam_type === 'uas'">
                    Nilai Sumatif Akhir Semester (SAS) akan langsung dicantumkan ke dalam rumus kalkulasi Rapor Final. Pastikan tidak ada kesalahan saat menginput karena ini berkontribusi besar ke nilai akhir rapor siswa.
                </p>
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
                        <th class="px-5 py-3" style="width: 280px">Status Kehadiran</th>
                        <th class="px-5 py-3 text-right" style="width: 130px">Nilai (Maks: {{ exam.max_score }})</th>
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
                                class="block w-full text-right rounded-md py-1.5 text-slate-900 shadow-sm ring-1 ring-inset placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
                                :class="[
                                    form.scores[index].score > exam.max_score ? 'ring-red-300 border-red-300 focus:ring-red-500 text-red-600 bg-red-50' : 'ring-slate-300 border-0',
                                    form.scores[index].submission_status === 'tidak_kumpul' ? 'bg-slate-50 text-slate-400 cursor-not-allowed' : '',
                                ]"
                                :max="exam.max_score"
                                min="0"
                                step="0.01"
                                :placeholder="form.scores[index].submission_status === 'tidak_kumpul' ? '—' : '0'"
                            >
                        </td>
                        <td class="px-5 py-4">
                            <input type="text" v-model="form.scores[index].notes" class="block w-full rounded-md border-0 py-1.5 text-slate-900 shadow-sm ring-1 ring-inset ring-slate-300 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-xs sm:leading-6" placeholder="Keterangan...">
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
