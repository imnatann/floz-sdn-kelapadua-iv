<script setup>
import { ref, reactive, computed } from 'vue';
import { Head, Link, useForm, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Pagination from '@/Components/UI/Pagination.vue';
import Textarea from '@/Components/UI/Textarea.vue';
import Input from '@/Components/UI/Input.vue';
import ActivityNavigation from '@/Components/UI/ActivityNavigation.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  assignment: Object,
  students: Object,
  is_student: Boolean,
  is_past_due: Boolean,
  submission: Object,
  meeting: Object,
  questions: { type: Array, default: () => [] },
  answers: { type: Object, default: () => ({}) },
});

const isQuiz = computed(() => props.assignment.type === 'quiz');

const formatDate = (dateString, withTime = true) => {
  if (!dateString) return '-';
  const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
  if (withTime) { options.hour = '2-digit'; options.minute = '2-digit'; }
  return new Date(dateString).toLocaleString('id-ID', options);
};

const formatClasses = (classes) => classes.map(c => c.name).join(', ');

// -- MANUAL SUBMISSION FORM --
const manualForm = useForm({
  answer_text: props.submission?.answer_text || '',
  answer_link: props.submission?.answer_link || '',
  file: null,
});

// -- QUIZ SUBMISSION --
const quizAnswers = reactive({});
// Populate existing answers
if (props.answers) {
  Object.keys(props.answers).forEach(qId => {
    quizAnswers[qId] = props.answers[qId]?.answer || '';
  });
}

const submitManual = () => {
  manualForm.post(`/tenant/assignments/${props.assignment.id}/submit`, {
    preserveScroll: true,
    onSuccess: () => manualForm.reset('file'),
  });
};

const submitQuiz = () => {
  const answersArr = props.questions.map(q => ({
    question_id: q.id,
    answer: quizAnswers[q.id] || '',
  }));
  router.post(`/tenant/assignments/${props.assignment.id}/submit`, {
    answers: answersArr,
  }, { preserveScroll: true });
};
</script>

<template>
  <Head title="Detail Tugas" />

  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-800">Detail Tugas</h1>
        <nav class="flex text-sm text-slate-500 mt-1">
          <Link href="/dashboard" class="hover:text-blue-600">Home</Link>
          <span class="mx-2">/</span>
          <Link href="/assignments" class="hover:text-blue-600">Tugas</Link>
          <span class="mx-2">/</span>
          <span class="text-slate-800 font-medium">{{ assignment.title }}</span>
        </nav>
      </div>
    </div>
    
    <!-- Card 1: Detail Tugas -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div class="flex items-center gap-2 mb-4">
            <div class="p-2 bg-blue-100 rounded-lg text-blue-600">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
            </div>
            <h2 class="text-lg font-bold text-slate-800">Informasi Tugas</h2>
            <Badge v-if="isQuiz" variant="info" class="ml-2">Quiz</Badge>
            <Badge v-else variant="secondary" class="ml-2">Manual</Badge>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-4">
                <div><div class="text-sm text-slate-500 mb-1">Judul Tugas</div><div class="font-medium text-slate-800">{{ assignment.title }}</div></div>
                <div><div class="text-sm text-slate-500 mb-1">Kelas</div><div class="font-medium text-slate-800">{{ formatClasses(assignment.classes) }}</div></div>
                <div><div class="text-sm text-slate-500 mb-1">Mata Pelajaran</div><div class="font-medium text-slate-800">{{ assignment.subject?.name }}</div></div>
            </div>
            <div class="space-y-4">
                <div><div class="text-sm text-slate-500 mb-1">Tanggal Pembuatan</div><div class="font-medium text-slate-800">{{ formatDate(assignment.created_at) }}</div></div>
                <div><div class="text-sm text-slate-500 mb-1">Batas Pengumpulan</div><div class="font-medium text-slate-800">{{ formatDate(assignment.due_date) }}</div></div>
                <div>
                    <div class="text-sm text-slate-500 mb-1">Status</div>
                    <Badge :variant="assignment.status === 'active' ? 'success' : 'secondary'">{{ assignment.status === 'active' ? 'Aktif' : 'Nonaktif' }}</Badge>
                </div>
            </div>
        </div>
        
        <div class="mt-6 pt-6 border-t border-slate-100">
             <div class="text-sm text-slate-500 mb-2">Deskripsi</div>
             <div class="prose text-sm text-slate-800 max-w-none whitespace-pre-wrap">{{ assignment.description }}</div>
        </div>
    </div>

    <!-- Deadline Warning -->
    <div v-if="is_past_due" class="bg-red-50 border border-red-200 rounded-xl p-4 flex items-center gap-3">
        <div class="p-2 bg-red-100 rounded-lg text-red-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        </div>
        <div>
            <h3 class="font-semibold text-red-800 text-sm">Batas Waktu Telah Lewat</h3>
            <p class="text-red-600 text-xs">Tugas ini sudah melewati batas pengumpulan.</p>
        </div>
    </div>

    <!-- File Attachments -->
    <div v-if="assignment.files && assignment.files.length > 0" class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 font-bold text-slate-800">File Lampiran</div>
        <table class="w-full text-left text-sm">
            <thead class="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                <tr><th class="px-6 py-3">Nama</th><th class="px-6 py-3">Format</th><th class="px-6 py-3 text-right">Aksi</th></tr>
            </thead>
            <tbody class="divide-y divide-slate-200">
                <tr v-for="file in assignment.files" :key="file.id">
                    <td class="px-6 py-3">{{ file.file_name }}</td>
                    <td class="px-6 py-3 uppercase">{{ file.file_type.split('/').pop() }}</td>
                    <td class="px-6 py-3 text-right"><a :href="`/storage/${file.file_path}`" target="_blank" class="text-blue-600 hover:text-blue-800 font-medium">Download</a></td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- ==================== TEACHER VIEW ==================== -->
    <div v-if="!is_student" class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 font-bold text-slate-800">Hasil Siswa</div>
        <div class="overflow-x-auto">
             <table class="w-full text-left text-sm">
                <thead class="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                    <tr>
                        <th class="px-6 py-3">Nama</th>
                        <th class="px-6 py-3">Nilai</th>
                        <th class="px-6 py-3">Di Jawab</th>
                        <th class="px-6 py-3">Status</th>
                        <th class="px-6 py-3 text-right">Detail</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-200">
                    <tr v-for="student in students.data" :key="student.id" class="hover:bg-slate-50">
                        <td class="px-6 py-3 font-medium text-slate-800">{{ student.name }}</td>
                        <td class="px-6 py-3 text-slate-800 font-bold">{{ student.submission?.grade ?? '-' }}</td>
                        <td class="px-6 py-3 text-slate-500">{{ formatDate(student.submission?.submitted_at) }}</td>
                        <td class="px-6 py-3">
                            <Badge v-if="student.submission?.grade" variant="success">Dinilai</Badge>
                            <Badge v-else-if="student.submission" variant="info">Mengumpulkan</Badge>
                            <Badge v-else variant="secondary">Belum</Badge>
                        </td>
                        <td class="px-6 py-3 text-right">
                             <Link :href="`/assignments/${assignment.id}/student/${student.id}`" class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                             </Link>
                        </td>
                    </tr>
                </tbody>
             </table>
        </div>
        <div v-if="students.total > 0" class="px-6 py-4 border-t border-slate-200 bg-slate-50">
            <Pagination :links="students.links" :from="students.from" :to="students.to" :total="students.total" />
        </div>
    </div>

    <!-- ==================== STUDENT VIEW ==================== -->
    <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 bg-gradient-to-r from-indigo-50 to-blue-50">
            <div class="flex items-center gap-3">
                <div class="p-2.5 bg-indigo-100 rounded-xl text-indigo-600 shadow-sm">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
                </div>
                <div>
                    <h2 class="text-lg font-bold text-slate-800">Pengumpulan Tugas</h2>
                    <p class="text-xs text-slate-500">{{ isQuiz ? 'Jawab soal-soal quiz berikut' : 'Kirim jawaban via teks, link, atau file' }}</p>
                </div>
            </div>
        </div>

        <div class="p-6 space-y-5">
            <!-- Grade Status -->
            <div v-if="submission?.grade" class="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-xl p-5">
                <div class="flex items-center gap-3 mb-3">
                    <div class="p-2 bg-green-100 rounded-lg"><svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg></div>
                    <div>
                        <h3 class="font-bold text-green-800">Sudah Dinilai</h3>
                        <p class="text-2xl font-extrabold text-green-700 mt-1">{{ submission.grade }}<span class="text-sm font-normal text-green-500"> / 100</span></p>
                    </div>
                </div>
                <p v-if="submission.correction_note" class="text-green-700 text-sm bg-white/60 rounded-lg p-3 mt-2"><strong>Catatan Guru:</strong> {{ submission.correction_note }}</p>
            </div>

            <!-- Previous Submission Info -->
            <div v-if="submission && !isQuiz" class="bg-blue-50/50 border border-blue-100 rounded-xl p-5">
                <div class="flex items-center gap-3 mb-3">
                    <div class="p-2 bg-blue-100 rounded-lg"><svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg></div>
                    <div>
                        <h3 class="font-semibold text-blue-800 text-sm">Tugas Sudah Dikumpulkan</h3>
                        <p class="text-xs text-blue-500">{{ formatDate(submission.submitted_at) }}</p>
                    </div>
                </div>
                <div class="space-y-2 ml-12">
                    <p v-if="submission.answer_text" class="text-sm text-slate-700 bg-white rounded-lg p-3 border border-slate-100 italic">"{{ submission.answer_text }}"</p>
                    <div v-if="submission.answer_link" class="flex items-center gap-2">
                        <a :href="submission.answer_link" target="_blank" class="text-blue-600 hover:text-blue-800 hover:underline text-sm truncate">{{ submission.answer_link }}</a>
                    </div>
                    <div v-if="submission.files && submission.files.length > 0" class="flex flex-wrap gap-2">
                        <a v-for="file in submission.files" :key="file.id" :href="`/storage/${file.file_path}`" target="_blank" class="inline-flex items-center gap-1.5 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-slate-700 transition-colors">{{ file.file_name }}</a>
                    </div>
                </div>
            </div>

            <!-- Past Due & No Submission -->
            <div v-if="is_past_due && !submission" class="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl">
                <div class="p-2 bg-red-100 rounded-lg flex-shrink-0"><svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg></div>
                <p class="font-semibold text-red-700 text-sm">Anda belum mengumpulkan tugas ini dan batas waktu sudah lewat.</p>
            </div>

            <!-- ===== QUIZ SUBMISSION FORM ===== -->
            <div v-if="isQuiz && !is_past_due && !submission?.grade">
                <div v-if="submission" class="bg-blue-50/50 border border-blue-100 rounded-xl p-4 mb-4">
                    <p class="text-sm text-blue-700 font-medium">✅ Quiz sudah dikumpulkan pada {{ formatDate(submission.submitted_at) }}</p>
                    <p class="text-xs text-blue-500 mt-1">Anda masih bisa mengubah jawaban sebelum dinilai atau batas waktu habis.</p>
                </div>

                <div class="space-y-6">
                    <div v-for="(question, qIndex) in questions" :key="question.id" class="border border-slate-200 rounded-xl overflow-hidden">
                        <div class="bg-slate-50 px-5 py-3 border-b border-slate-200 flex items-center justify-between">
                            <div class="flex items-center gap-2">
                                <span class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-blue-100 text-blue-700 text-xs font-bold">{{ qIndex + 1 }}</span>
                                <Badge v-if="question.question_type === 'multiple_choice'" variant="info">Pilihan Ganda</Badge>
                                <Badge v-else-if="question.question_type === 'true_false'" variant="warning">Benar/Salah</Badge>
                                <Badge v-else variant="secondary">Essay</Badge>
                            </div>
                            <span class="text-xs text-slate-400">{{ question.points }} poin</span>
                        </div>
                        <div class="p-5 space-y-4">
                            <p class="text-sm text-slate-800 font-medium whitespace-pre-wrap">{{ question.question_text }}</p>

                            <!-- Existing answer result (if graded) -->
                            <div v-if="answers[question.id]?.is_correct !== null && answers[question.id]?.is_correct !== undefined" class="text-xs px-3 py-1.5 rounded-lg" :class="answers[question.id].is_correct ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-red-50 text-red-700 border border-red-200'">
                                {{ answers[question.id].is_correct ? '✅ Jawaban Benar' : '❌ Jawaban Salah' }} — {{ answers[question.id].points_earned }}/{{ question.points }} poin
                            </div>

                            <!-- Multiple Choice -->
                            <div v-if="question.question_type === 'multiple_choice'" class="space-y-2">
                                <div v-for="(opt, oIndex) in question.options" :key="oIndex"
                                    @click="quizAnswers[question.id] = String.fromCharCode(65 + oIndex)"
                                    class="cursor-pointer flex items-center gap-3 border rounded-lg px-4 py-3 text-sm transition-all duration-200"
                                    :class="quizAnswers[question.id] === String.fromCharCode(65 + oIndex) 
                                        ? 'border-blue-500 bg-blue-50 text-blue-800 ring-1 ring-blue-500' 
                                        : 'border-slate-200 text-slate-600 hover:border-blue-300 hover:bg-slate-50'">
                                    <span class="w-7 h-7 flex items-center justify-center rounded-full text-xs font-bold flex-shrink-0"
                                        :class="quizAnswers[question.id] === String.fromCharCode(65 + oIndex) ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-500'">
                                        {{ String.fromCharCode(65 + oIndex) }}
                                    </span>
                                    <span>{{ opt }}</span>
                                </div>
                            </div>

                            <!-- True/False -->
                            <div v-if="question.question_type === 'true_false'" class="flex gap-3">
                                <button type="button" @click="quizAnswers[question.id] = 'true'"
                                    class="flex-1 py-3 rounded-lg border-2 text-sm font-medium transition-all"
                                    :class="quizAnswers[question.id] === 'true' ? 'border-emerald-500 bg-emerald-50 text-emerald-700' : 'border-slate-200 text-slate-500 hover:border-emerald-300'">
                                    ✅ Benar
                                </button>
                                <button type="button" @click="quizAnswers[question.id] = 'false'"
                                    class="flex-1 py-3 rounded-lg border-2 text-sm font-medium transition-all"
                                    :class="quizAnswers[question.id] === 'false' ? 'border-red-500 bg-red-50 text-red-700' : 'border-slate-200 text-slate-500 hover:border-red-300'">
                                    ❌ Salah
                                </button>
                            </div>

                            <!-- Essay -->
                            <div v-if="question.question_type === 'essay'">
                                <textarea 
                                    v-model="quizAnswers[question.id]"
                                    rows="4"
                                    class="w-full rounded-lg border border-slate-200 px-4 py-3 text-sm focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none resize-y"
                                    placeholder="Tulis jawaban essay kamu..."
                                ></textarea>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="flex justify-end pt-4">
                    <Button @click="submitQuiz" variant="primary" class="px-8">
                        <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path></svg>
                        {{ submission ? 'Update Jawaban Quiz' : 'Kirim Jawaban Quiz' }}
                    </Button>
                </div>
            </div>

            <!-- Past Due or Graded Quiz -->
            <div v-if="isQuiz && submission && (is_past_due || submission.grade)" class="space-y-4">
                <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 text-amber-700 text-sm">
                    <span v-if="submission.grade">✅ Quiz telah dinilai. Jawaban tidak bisa diubah.</span>
                    <span v-else>⏰ Batas waktu telah lewat. Jawaban tidak bisa diubah.</span>
                </div>
                <div v-for="(question, qIndex) in questions" :key="question.id" class="border border-slate-200 rounded-xl p-4 space-y-2">
                    <div class="flex items-center gap-2">
                        <span class="inline-flex items-center justify-center w-6 h-6 rounded-full bg-slate-100 text-slate-600 text-xs font-bold">{{ qIndex + 1 }}</span>
                        <p class="text-sm text-slate-800 font-medium">{{ question.question_text }}</p>
                    </div>
                    <p class="text-sm text-slate-600 ml-8">Jawaban: <span class="font-medium">{{ answers[question.id]?.answer || '-' }}</span></p>
                    <div v-if="answers[question.id]?.is_correct !== null && answers[question.id]?.is_correct !== undefined" class="ml-8 text-xs" :class="answers[question.id].is_correct ? 'text-emerald-600' : 'text-red-600'">
                        {{ answers[question.id].is_correct ? '✅ Benar' : '❌ Salah' }} — {{ answers[question.id].points_earned }}/{{ question.points }} poin
                    </div>
                </div>
            </div>

            <!-- ===== MANUAL SUBMISSION FORM ===== -->
            <form v-if="!isQuiz && !is_past_due && !submission?.grade" @submit.prevent="submitManual" class="space-y-5">
                <div v-if="submission" class="flex items-center gap-3">
                    <div class="flex-1 h-px bg-slate-200"></div>
                    <span class="text-xs font-medium text-slate-400 uppercase tracking-wider">Kirim Ulang</span>
                    <div class="flex-1 h-px bg-slate-200"></div>
                </div>

                <!-- Answer Text -->
                <div class="space-y-2">
                    <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">
                        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                        Jawaban Tekstual
                    </label>
                    <Textarea v-model="manualForm.answer_text" rows="4" placeholder="Tulis jawaban kamu di sini..." />
                    <div v-if="manualForm.errors.answer_text" class="text-red-500 text-xs">{{ manualForm.errors.answer_text }}</div>
                </div>

                <!-- Answer Link -->
                <div class="space-y-2">
                    <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">
                        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"></path></svg>
                        Link Jawaban
                    </label>
                    <Input v-model="manualForm.answer_link" type="url" placeholder="https://drive.google.com/..." />
                    <div v-if="manualForm.errors.answer_link" class="text-red-500 text-xs">{{ manualForm.errors.answer_link }}</div>
                </div>
                
                <!-- File Upload -->
                <div class="space-y-2">
                    <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">Upload File Jawaban</label>
                    <label class="flex flex-col items-center justify-center w-full h-28 border-2 border-dashed border-slate-200 rounded-xl cursor-pointer bg-slate-50/50 hover:bg-indigo-50/50 hover:border-indigo-300 transition-all group">
                        <div class="flex flex-col items-center justify-center py-4">
                            <svg class="w-8 h-8 text-slate-300 group-hover:text-indigo-400 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path></svg>
                            <p class="text-xs text-slate-400"><span class="font-semibold">Klik untuk pilih file</span> atau drag & drop</p>
                            <p v-if="manualForm.file" class="text-xs text-indigo-600 font-medium mt-1">{{ manualForm.file.name }}</p>
                        </div>
                        <input type="file" class="hidden" @change="manualForm.file = $event.target.files[0]" />
                    </label>
                </div>

                <div class="flex items-center justify-between pt-4 border-t border-slate-100">
                    <p class="text-xs text-slate-400">Isi minimal salah satu: teks, link, atau file</p>
                    <Button type="submit" :disabled="manualForm.processing" variant="primary" class="px-6">
                        {{ submission ? 'Update Jawaban' : 'Kirim Tugas' }}
                    </Button>
                </div>
            </form>

            <!-- Past Due or Graded Manual -->
            <div v-else-if="!isQuiz && submission && (is_past_due || submission.grade)" class="flex items-center gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl">
                <p class="text-amber-700 text-sm">
                    <span v-if="submission.grade">Tugas telah dinilai. Jawaban tidak dapat diubah lagi.</span>
                    <span v-else>Batas waktu telah lewat. Anda tidak dapat mengubah jawaban lagi.</span>
                </p>
            </div>
        </div>
    </div>
    
    <!-- Bottom Navigation Bar for Next/Prev inside a Meeting Session -->
    <div v-if="meeting" class="mt-8">
        <ActivityNavigation 
            :meeting="meeting" 
            :currentActivityId="assignment.id" 
            currentActivityType="assignment" 
        />
    </div>
  </div>
</template>
