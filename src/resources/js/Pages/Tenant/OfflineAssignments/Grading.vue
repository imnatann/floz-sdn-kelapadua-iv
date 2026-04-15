<script setup>
import { useForm, Head, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Input from '@/Components/UI/Input.vue';
import Label from '@/Components/UI/Label.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  assignment: Object,
  student: Object,
  submission: Object,
});

const form = useForm({
  grade: props.submission?.grade || '',
  correction_file: null,
});

const submitCorrection = () => {
  form.post(`/tenant/offline-assignments/${props.assignment.id}/student/${props.student.id}`, {
    preserveScroll: true,
    forceFormData: true,
  });
};

const formatDate = (dateString) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleString('id-ID', {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit'
  });
};
</script>

<template>
  <Head title="Detail Jawaban Siswa" />

  <div class="space-y-6">
    <!-- Header -->
    <div>
        <h1 class="text-2xl font-bold text-slate-800">Detail Jawaban Siswa</h1>
        <nav class="text-sm text-slate-500 mt-1">
            <Link :href="`/offline-assignments`" class="hover:text-blue-600">Tugas Offline</Link>
            <span class="mx-2">/</span>
            <Link :href="`/offline-assignments/${assignment.id}`" class="hover:text-blue-600">Detail Tugas</Link>
            <span class="mx-2">/</span>
            <span class="text-slate-800 font-medium">{{ student.name }}</span>
        </nav>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Card 1: Informasi Tugas -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 h-fit">
            <h2 class="text-lg font-bold text-slate-800 mb-4 pb-2 border-b border-slate-100">Informasi Tugas</h2>
            <div class="space-y-4">
                <div>
                    <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">Judul Tugas</label>
                    <div class="mt-1 font-medium text-slate-800">{{ assignment.title }}</div>
                </div>
                <div>
                    <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">Tanggal Pembuatan</label>
                    <div class="mt-1 text-slate-800">{{ formatDate(assignment.created_at) }}</div>
                </div>
                 <div>
                    <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">Batas Pengumpulan</label>
                    <div class="mt-1 text-slate-800">{{ formatDate(assignment.due_date) }}</div>
                </div>
            </div>
        </div>

        <!-- Card 2: Informasi Jawaban Siswa -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 h-fit">
            <h2 class="text-lg font-bold text-slate-800 mb-4 pb-2 border-b border-slate-100">Informasi Jawaban Siswa</h2>
            <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">Nama Siswa</label>
                        <div class="mt-1 font-medium text-slate-800">{{ student.name }}</div>
                    </div>
                     <div>
                        <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">NIS</label>
                        <div class="mt-1 text-slate-800">{{ student.nis }}</div>
                    </div>
                </div>
                <div>
                    <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">Kelas</label>
                    <div class="mt-1 text-slate-800">{{ student.class?.name }}</div>
                </div>
                 <div>
                    <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">Waktu Submit</label>
                    <div class="mt-1">
                        <Badge v-if="submission?.submitted_at" variant="success">{{ formatDate(submission.submitted_at) }}</Badge>
                        <span v-else class="text-slate-400 italic">Belum mengumpulkan</span>
                    </div>
                </div>
                 <div>
                     <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">File Answer Link</label>
                     <div class="mt-1">
                         <a v-if="submission?.answer_link" :href="submission.answer_link" target="_blank" class="text-blue-600 hover:underline break-all">
                             {{ submission.answer_link }}
                         </a>
                         <span v-else class="text-slate-400 italic text-sm">Tidak ada jawaban URL</span>
                     </div>
                 </div>
                 <div>
                      <label class="text-xs text-slate-500 uppercase tracking-wide font-semibold">Jawaban Teks</label>
                      <div class="mt-1">
                          <p v-if="submission?.answer_text" class="text-slate-800 text-sm whitespace-pre-wrap bg-slate-50 rounded-lg p-3 border border-slate-100">{{ submission.answer_text }}</p>
                          <span v-else class="text-slate-400 italic text-sm">Tidak ada jawaban teks</span>
                      </div>
                 </div>
            </div>
        </div>
    </div>

    <!-- Card 3: List Answer File -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 font-bold text-slate-800">
            List Answer File
        </div>
        <table class="w-full text-left text-sm">
            <thead class="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                <tr>
                    <th class="px-6 py-3">Nama File</th>
                    <th class="px-6 py-3">Format</th>
                    <th class="px-6 py-3 text-right">Download</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-200">
                 <tr v-if="!submission?.files || submission.files.length === 0">
                    <td colspan="3" class="px-6 py-4 text-center text-slate-500">
                        Tidak ada file jawaban.
                    </td>
                </tr>
                <tr v-for="file in submission?.files" :key="file.id">
                    <td class="px-6 py-3 font-medium text-slate-800">{{ file.file_name }}</td>
                    <td class="px-6 py-3 text-slate-500 uppercase">{{ file.file_type.split('/').pop() }}</td>
                    <td class="px-6 py-3 text-right">
                         <Button size="sm" variant="primary" is="a" :href="`/storage/${file.file_path}`" target="_blank">
                             Download
                         </Button>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- Card 4: Informasi Koreksi -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h2 class="text-lg font-bold text-slate-800 mb-4 pb-2 border-b border-slate-100">Informasi Koreksi</h2>
        <form @submit.prevent="submitCorrection">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div>
                     <Label value="Nilai" class="mb-2" />
                     <Input v-model="form.grade" type="number" min="0" max="100" placeholder="0 - 100" class="max-w-[150px]" />
                     <div v-if="form.errors.grade" class="text-red-500 text-xs mt-1">{{ form.errors.grade }}</div>
                </div>

                <div>
                    <Label value="File Koreksi" class="mb-2" />
                    <p class="text-xs text-slate-500 mb-2">Format: .doc .docx .xls .xlsx .ppt .pptx .pdf .jpg .jpeg .png</p>
                    
                    <div class="border-2 border-dashed border-slate-300 rounded-lg p-6 flex flex-col items-center justify-center text-center hover:bg-slate-50 transition-colors relative h-32">
                        <input 
                            type="file" 
                            @input="form.correction_file = $event.target.files[0]"
                            class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                            accept=".doc,.docx,.xls,.xlsx,.ppt,.pptx,.pdf,.jpg,.jpeg,.png"
                        />
                         <div v-if="form.correction_file" class="text-sm font-medium text-blue-600">
                            {{ form.correction_file.name }}
                        </div>
                        <div v-else-if="submission?.correction_file && !form.correction_file" class="text-sm font-medium text-slate-600">
                             File saat ini: {{ submission.correction_note || 'File Tersimpan' }}
                        </div>
                        <div v-else class="text-slate-400 flex flex-col items-center">
                            <span class="text-sm">Drag & Drop file disini</span>
                        </div>
                    </div>
                     <div v-if="form.errors.correction_file" class="text-red-500 text-xs mt-1">{{ form.errors.correction_file }}</div>
                </div>
            </div>

            <div class="mt-6 flex justify-end">
                <Button variant="primary" size="lg" :disabled="form.processing">
                    {{ form.processing ? 'Menyimpan...' : 'Simpan Nilai' }}
                </Button>
            </div>
        </form>
    </div>
  </div>
</template>
