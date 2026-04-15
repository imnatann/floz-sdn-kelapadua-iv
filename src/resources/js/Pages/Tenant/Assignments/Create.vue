<script setup>
import { useForm, Head, Link } from '@inertiajs/vue3';
import { ref, computed } from 'vue';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormInput from '@/Components/UI/FormInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import FormTextarea from '@/Components/UI/FormTextarea.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  subjects: Array,
  classes: Array,
  meeting: { type: Object, default: null },
});

// When creating from meeting context, pre-fill subject/class
const meetingContext = computed(() => !!props.meeting);
const meetingSubjectId = computed(() => props.meeting?.teaching_assignment?.subject_id || '');
const meetingClassId = computed(() => props.meeting?.teaching_assignment?.class_id || null);

const form = useForm({
  subject_id: meetingSubjectId.value || '',
  classes: meetingClassId.value ? [meetingClassId.value] : [],
  meeting_id: props.meeting?.id || null,
  title: '',
  description: '',
  due_date: '',
  status: 'active',
  type: 'manual',
  file: null,
  questions: [],
});

const toggleClass = (classId) => {
  if (meetingContext.value) return; // Can't change class when in meeting context
  const index = form.classes.indexOf(classId);
  if (index === -1) form.classes.push(classId);
  else form.classes.splice(index, 1);
};

const addQuestion = () => {
  form.questions.push({
    question_text: '',
    question_type: 'multiple_choice',
    options: ['', '', '', ''],
    correct_answer: '',
    points: 10,
  });
};

const removeQuestion = (index) => {
  form.questions.splice(index, 1);
};

const addOption = (qIndex) => {
  form.questions[qIndex].options.push('');
};

const removeOption = (qIndex, oIndex) => {
  form.questions[qIndex].options.splice(oIndex, 1);
  // Clear correct answer if it was the removed option
  if (form.questions[qIndex].correct_answer === String.fromCharCode(65 + oIndex)) {
    form.questions[qIndex].correct_answer = '';
  }
};

const submit = () => {
  form.post('/assignments');
};

const isQuiz = computed(() => form.type === 'quiz');
</script>

<template>
  <Head title="Tambah Tugas Baru" />

  <div class="max-w-4xl mx-auto space-y-6 pb-24">
    <!-- Header -->
    <div class="flex items-center gap-4">
        <Link href="/assignments" class="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-500">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
        </Link>
        <div>
            <h1 class="text-xl font-bold text-slate-900">Tambah Tugas Baru</h1>
            <p class="text-sm text-slate-500">Buat tugas baru untuk siswa</p>
        </div>
    </div>

    <form @submit.prevent="submit" class="space-y-6">
        <!-- Card 1: Tipe Tugas -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
                 <div class="flex items-center gap-3">
                     <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-100 text-sm">🎯</div>
                     <div>
                         <h3 class="text-sm font-semibold text-slate-700">Tipe Tugas</h3>
                         <p class="text-xs text-slate-400">Pilih jenis tugas yang ingin dibuat</p>
                     </div>
                </div>
            </div>
            <div class="p-6">
                <div class="grid grid-cols-2 gap-4">
                    <div 
                        @click="form.type = 'manual'" 
                        class="cursor-pointer border-2 rounded-xl p-5 transition-all duration-200"
                        :class="form.type === 'manual' 
                            ? 'border-blue-500 bg-blue-50 ring-1 ring-blue-500' 
                            : 'border-slate-200 hover:border-blue-300 hover:bg-slate-50'"
                    >
                        <div class="text-3xl mb-2">📄</div>
                        <h4 class="font-semibold text-slate-900">Tugas Manual</h4>
                        <p class="text-xs text-slate-500 mt-1">Siswa mengumpulkan jawaban berupa teks, link, atau file</p>
                    </div>
                    <div 
                        @click="form.type = 'quiz'" 
                        class="cursor-pointer border-2 rounded-xl p-5 transition-all duration-200"
                        :class="form.type === 'quiz' 
                            ? 'border-emerald-500 bg-emerald-50 ring-1 ring-emerald-500' 
                            : 'border-slate-200 hover:border-emerald-300 hover:bg-slate-50'"
                    >
                        <div class="text-3xl mb-2">📝</div>
                        <h4 class="font-semibold text-slate-900">Tugas Quiz</h4>
                        <p class="text-xs text-slate-500 mt-1">Pilihan ganda, benar/salah, dan essay dengan auto-grading</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Card 2: Informasi Tugas -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
                 <div class="flex items-center gap-3">
                     <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-100 text-sm">📝</div>
                     <div>
                         <h3 class="text-sm font-semibold text-slate-700">Informasi Tugas</h3>
                         <p class="text-xs text-slate-400">Detail utama mengenai tugas yang diberikan</p>
                     </div>
                </div>
            </div>

            <div class="p-6 space-y-4">
                <FormInput 
                    v-model="form.title" 
                    label="Judul Tugas" 
                    placeholder="Contoh: Latihan Soal Bab 1" 
                    :required="true" 
                    :error="form.errors.title" 
                />

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <FormSelect 
                        v-model="form.subject_id" 
                        label="Mata Pelajaran" 
                        :required="true" 
                        :error="form.errors.subject_id"
                    >
                        <option value="">- Pilih Mapel -</option>
                        <option v-for="s in subjects" :key="s.id" :value="s.id">{{ s.name }}</option>
                    </FormSelect>

                    <FormSelect 
                        v-model="form.status" 
                        label="Status" 
                        :required="true" 
                        :error="form.errors.status"
                    >
                        <option value="active">Aktif</option>
                        <option value="inactive">Tidak Aktif</option>
                    </FormSelect>
                </div>

                <FormTextarea
                    v-model="form.description"
                    label="Deskripsi / Petunjuk"
                    rows="4"
                    placeholder="Tuliskan deskripsi atau petunjuk pengerjaan tugas..."
                    :required="true"
                    :error="form.errors.description"
                />
            </div>
        </div>

        <!-- Card 3: Kelas & Dokumen -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
             <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
                 <div class="flex items-center gap-3">
                     <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-orange-100 text-sm">📚</div>
                     <div>
                         <h3 class="text-sm font-semibold text-slate-700">Kelas & Dokumen</h3>
                         <p class="text-xs text-slate-400">Target kelas dan file lampiran</p>
                     </div>
                </div>
            </div>

            <div class="p-6 space-y-6">
                <!-- Kelas Selection -->
                <div>
                    <label class="block text-xs font-medium text-slate-600 mb-2">
                        Pilih Kelas Target <span class="text-orange-500">*</span>
                    </label>
                    <div class="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-5 gap-3 max-h-48 overflow-y-auto p-1">
                        <div 
                            v-for="cls in classes" 
                            :key="cls.id" 
                            @click="toggleClass(cls.id)"
                            class="cursor-pointer border rounded-lg px-3 py-2 text-sm text-center transition-all duration-200 select-none flex items-center justify-center gap-2"
                            :class="form.classes.includes(cls.id) 
                                ? 'border-emerald-500 bg-emerald-50 text-emerald-700 font-semibold shadow-sm ring-1 ring-emerald-500' 
                                : 'border-slate-200 text-slate-600 hover:border-emerald-300 hover:bg-slate-50'"
                        >
                            <span>{{ cls.name }}</span>
                            <svg v-if="form.classes.includes(cls.id)" class="w-4 h-4 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                        </div>
                    </div>
                    <div v-if="form.errors.classes" class="text-red-500 text-xs mt-1">{{ form.errors.classes }}</div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <!-- Due Date -->
                     <FormInput
                       type="datetime-local"
                       v-model="form.due_date"
                       label="Batas Pengumpulan"
                       :required="true"
                       :error="form.errors.due_date"
                     />

                    <!-- File Upload -->
                    <div>
                        <label class="block text-xs font-medium text-slate-600 mb-2">
                            Lampiran File (Opsional)
                        </label>
                        <div class="relative">
                            <input 
                              type="file" 
                              @input="form.file = $event.target.files[0]"
                              class="block w-full text-sm text-slate-500
                                file:mr-4 file:py-2.5 file:px-4
                                file:rounded-lg file:border-0
                                file:text-sm file:font-semibold
                                file:bg-emerald-50 file:text-emerald-700
                                hover:file:bg-emerald-100
                                cursor-pointer border border-slate-200 rounded-lg"
                              accept=".doc,.docx,.xls,.xlsx,.ppt,.pptx,.pdf,.jpg,.jpeg,.png"
                            />
                             <div v-if="form.errors.file" class="text-red-500 text-xs mt-1">{{ form.errors.file }}</div>
                        </div>
                        <p class="text-[10px] text-slate-400 mt-1">Format: PDF, Office, Gambar. Max 100MB.</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Card 4: Quiz Builder (only for quiz type) -->
        <div v-if="isQuiz" class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-100 text-sm">❓</div>
                        <div>
                            <h3 class="text-sm font-semibold text-slate-700">Soal Quiz</h3>
                            <p class="text-xs text-slate-400">Buat soal-soal untuk quiz ini</p>
                        </div>
                    </div>
                    <button type="button" @click="addQuestion" class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-emerald-700 bg-emerald-50 rounded-lg border border-emerald-200 hover:bg-emerald-100 transition-colors">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                        Tambah Soal
                    </button>
                </div>
            </div>

            <div class="p-6 space-y-6">
                <div v-if="form.questions.length === 0" class="text-center py-8 text-slate-400">
                    <div class="text-4xl mb-2">📋</div>
                    <p class="text-sm">Belum ada soal. Klik "Tambah Soal" untuk mulai.</p>
                </div>

                <div v-for="(question, qIndex) in form.questions" :key="qIndex" class="border border-slate-200 rounded-xl p-5 space-y-4 relative bg-slate-50/50">
                    <div class="flex items-start justify-between gap-3">
                        <span class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-blue-100 text-blue-700 text-xs font-bold flex-shrink-0 mt-1">{{ qIndex + 1 }}</span>
                        <button type="button" @click="removeQuestion(qIndex)" class="p-1.5 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors flex-shrink-0">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                        </button>
                    </div>

                    <FormTextarea
                        v-model="question.question_text"
                        label="Pertanyaan"
                        rows="2"
                        placeholder="Tulis pertanyaan..."
                        :required="true"
                        :error="form.errors[`questions.${qIndex}.question_text`]"
                    />

                    <div class="grid grid-cols-2 gap-4">
                        <FormSelect 
                            v-model="question.question_type" 
                            label="Tipe Soal"
                        >
                            <option value="multiple_choice">Pilihan Ganda</option>
                            <option value="true_false">Benar/Salah</option>
                            <option value="essay">Essay</option>
                        </FormSelect>

                        <FormInput 
                            v-model="question.points" 
                            type="number" 
                            label="Poin" 
                            :min="0"
                            placeholder="10"
                        />
                    </div>

                    <!-- Multiple Choice Options -->
                    <div v-if="question.question_type === 'multiple_choice'" class="space-y-3">
                        <label class="block text-xs font-medium text-slate-600">Pilihan Jawaban</label>
                        <div v-for="(opt, oIndex) in question.options" :key="oIndex" class="flex items-center gap-2">
                            <span class="w-7 h-7 flex items-center justify-center rounded-full text-xs font-bold flex-shrink-0"
                                :class="question.correct_answer === String.fromCharCode(65 + oIndex) 
                                    ? 'bg-emerald-100 text-emerald-700' 
                                    : 'bg-slate-100 text-slate-500'">
                                {{ String.fromCharCode(65 + oIndex) }}
                            </span>
                            <input 
                                v-model="question.options[oIndex]" 
                                type="text" 
                                :placeholder="`Opsi ${String.fromCharCode(65 + oIndex)}`"
                                class="flex-1 rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none"
                            />
                            <button 
                                type="button" 
                                @click="question.correct_answer = String.fromCharCode(65 + oIndex)"
                                class="p-1.5 rounded-lg transition-colors"
                                :class="question.correct_answer === String.fromCharCode(65 + oIndex) 
                                    ? 'text-emerald-600 bg-emerald-50' 
                                    : 'text-slate-300 hover:text-emerald-500'"
                                title="Tandai sebagai jawaban benar"
                            >
                                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"></path></svg>
                            </button>
                            <button v-if="question.options.length > 2" type="button" @click="removeOption(qIndex, oIndex)" class="p-1.5 text-slate-300 hover:text-red-500 transition-colors">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                            </button>
                        </div>
                        <button 
                            type="button" 
                            @click="addOption(qIndex)"
                            class="text-xs text-blue-600 hover:text-blue-700 font-medium flex items-center gap-1"
                        >
                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                            Tambah Opsi
                        </button>
                    </div>

                    <!-- True/False -->
                    <div v-if="question.question_type === 'true_false'" class="space-y-2">
                        <label class="block text-xs font-medium text-slate-600">Jawaban Benar</label>
                        <div class="flex gap-3">
                            <button 
                                type="button" 
                                @click="question.correct_answer = 'true'"
                                class="flex-1 py-2.5 rounded-lg border-2 text-sm font-medium transition-all"
                                :class="question.correct_answer === 'true' 
                                    ? 'border-emerald-500 bg-emerald-50 text-emerald-700' 
                                    : 'border-slate-200 text-slate-500 hover:border-emerald-300'"
                            >
                                ✅ Benar
                            </button>
                            <button 
                                type="button" 
                                @click="question.correct_answer = 'false'"
                                class="flex-1 py-2.5 rounded-lg border-2 text-sm font-medium transition-all"
                                :class="question.correct_answer === 'false' 
                                    ? 'border-red-500 bg-red-50 text-red-700' 
                                    : 'border-slate-200 text-slate-500 hover:border-red-300'"
                            >
                                ❌ Salah
                            </button>
                        </div>
                    </div>

                    <!-- Essay (no correct answer needed) -->
                    <div v-if="question.question_type === 'essay'" class="bg-amber-50 text-amber-700 text-xs px-3 py-2 rounded-lg border border-amber-200">
                        ⚠️ Soal essay akan dinilai manual oleh guru
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- Floating Footer -->
    <div class="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 p-4 shadow-lg z-10 md:pl-64">
        <div class="max-w-4xl mx-auto flex justify-end gap-3">
             <Link href="/assignments">
                <Button variant="ghost">Batal</Button>
             </Link>
             <Button variant="primary" :disabled="form.processing" @click="submit">
                 {{ form.processing ? 'Menyimpan...' : 'Simpan Tugas' }}
             </Button>
        </div>
    </div>
  </div>
</template>
