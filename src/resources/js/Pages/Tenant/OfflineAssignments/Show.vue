<script setup>
import { ref } from 'vue';
import { Head, Link, useForm, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Pagination from '@/Components/UI/Pagination.vue';
import Label from '@/Components/UI/Label.vue';
import Input from '@/Components/UI/Input.vue';
import Textarea from '@/Components/UI/Textarea.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  assignment: Object,
  students: Object, // Paginator (Teacher only)
  is_student: Boolean,
  is_past_due: Boolean,
  submission: Object, // Student only
});

const formatDate = (dateString, withTime = true) => {
  if (!dateString) return '-';
  const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
  if (withTime) {
      options.hour = '2-digit';
      options.minute = '2-digit';
  }
  return new Date(dateString).toLocaleString('id-ID', options);
};

const formatClasses = (classes) => {
    return classes.map(c => c.name).join(', ');
};

// -- STUDENT SUBMISSION FORM --
const form = useForm({
    answer_text: props.submission?.answer_text || '',
    answer_link: props.submission?.answer_link || '',
    file: null,
});

const submitAssignment = () => {
    form.post(`/tenant/offline-assignments/${props.assignment.id}/submit`, {
        preserveScroll: true,
        onSuccess: () => {
            form.reset('file');
            // Toast notification handling usually in Layout or global
        }
    });
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
          <Link href="/offline-assignments" class="hover:text-blue-600">Tugas Offline</Link>
          <span class="mx-2">/</span>
          <span class="text-slate-800 font-medium">{{ assignment.title }}</span>
        </nav>
      </div>
    </div>
    
    <!-- Card 1: Detail Tugas (Shared) -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div class="flex items-center gap-2 mb-4">
            <div class="p-2 bg-blue-100 rounded-lg text-blue-600">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
            </div>
            <h2 class="text-lg font-bold text-slate-800">Informasi Tugas</h2>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-4">
                <div>
                    <div class="text-sm text-slate-500 mb-1">Judul Tugas</div>
                    <div class="font-medium text-slate-800">{{ assignment.title }}</div>
                </div>
                 <div>
                    <div class="text-sm text-slate-500 mb-1">Kelas</div>
                    <div class="font-medium text-slate-800">{{ formatClasses(assignment.classes) }}</div>
                </div>
                 <div>
                    <div class="text-sm text-slate-500 mb-1">Mata Pelajaran</div>
                    <div class="font-medium text-slate-800">{{ assignment.subject?.name }}</div>
                </div>
            </div>
            <div class="space-y-4">
                <div>
                    <div class="text-sm text-slate-500 mb-1">Tanggal Pembuatan</div>
                    <div class="font-medium text-slate-800">{{ formatDate(assignment.created_at) }}</div>
                </div>
                 <div>
                    <div class="text-sm text-slate-500 mb-1">Batas Pengumpulan</div>
                    <div class="font-medium text-slate-800">{{ formatDate(assignment.due_date) }}</div>
                </div>
                 <div>
                    <div class="text-sm text-slate-500 mb-1">Status</div>
                    <Badge :variant="assignment.status === 'active' ? 'success' : 'secondary'">
                        {{ assignment.status === 'active' ? 'Aktif' : 'Nonaktif' }}
                    </Badge>
                </div>
            </div>
        </div>
        
        <div class="mt-6 pt-6 border-t border-slate-100">
             <div class="text-sm text-slate-500 mb-2">Deskripsi</div>
             <div class="prose text-sm text-slate-800 max-w-none whitespace-pre-wrap">{{ assignment.description }}</div>
        </div>
    </div>

    <!-- Deadline Warning Banner -->
    <div v-if="is_past_due" class="bg-red-50 border border-red-200 rounded-xl p-4 flex items-center gap-3">
        <div class="p-2 bg-red-100 rounded-lg text-red-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        </div>
        <div>
            <h3 class="font-semibold text-red-800 text-sm">Batas Waktu Telah Lewat</h3>
            <p class="text-red-600 text-xs">Tugas ini sudah melewati batas pengumpulan.</p>
        </div>
    </div>

    <!-- Card 2: List File Lampiran (Shared) -->
    <div v-if="assignment.files && assignment.files.length > 0" class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 font-bold text-slate-800">
            File Lampiran
        </div>
        <table class="w-full text-left text-sm">
            <thead class="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                <tr>
                    <th class="px-6 py-3">Nama Item</th>
                    <th class="px-6 py-3">Format</th>
                    <th class="px-6 py-3 text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-200">
                <tr v-for="file in assignment.files" :key="file.id">
                    <td class="px-6 py-3">{{ file.file_name }}</td>
                    <td class="px-6 py-3 uppercase">{{ file.file_type.split('/').pop() }}</td>
                    <td class="px-6 py-3 text-right">
                        <a :href="`/storage/${file.file_path}`" target="_blank" class="text-blue-600 hover:text-blue-800 font-medium">
                            Download
                        </a>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- TEACHER VIEW: Hasil Siswa -->
    <div v-if="!is_student" class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 font-bold text-slate-800">
            Hasil Siswa
        </div>
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
                        <td class="px-6 py-3 text-slate-800 font-bold">
                            {{ student.submission?.grade ?? '-' }}
                        </td>
                        <td class="px-6 py-3 text-slate-500">
                             {{ formatDate(student.submission?.submitted_at) }}
                        </td>
                        <td class="px-6 py-3">
                            <Badge v-if="student.submission?.grade" variant="success">Dinilai</Badge>
                            <Badge v-else-if="student.submission" variant="info">Mengumpulkan</Badge>
                            <Badge v-else variant="secondary">Belum</Badge>
                        </td>
                        <td class="px-6 py-3 text-right">
                             <Link :href="`/offline-assignments/${assignment.id}/student/${student.id}`" class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors">
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

    <!-- STUDENT VIEW: Submission Form & Status -->
    <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <!-- Header -->
        <div class="px-6 py-4 border-b border-slate-200 bg-gradient-to-r from-indigo-50 to-blue-50">
            <div class="flex items-center gap-3">
                <div class="p-2.5 bg-indigo-100 rounded-xl text-indigo-600 shadow-sm">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
                </div>
                <div>
                    <h2 class="text-lg font-bold text-slate-800">Pengumpulan Tugas</h2>
                    <p class="text-xs text-slate-500">Kirim jawaban kamu melalui teks, link, atau file</p>
                </div>
            </div>
        </div>

        <div class="p-6 space-y-5">
            <!-- Grade Status if Graded -->
            <div v-if="submission?.grade" class="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-xl p-5">
                <div class="flex items-center gap-3 mb-3">
                    <div class="p-2 bg-green-100 rounded-lg">
                        <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    </div>
                    <div>
                        <h3 class="font-bold text-green-800">Sudah Dinilai</h3>
                        <p class="text-2xl font-extrabold text-green-700 mt-1">{{ submission.grade }}<span class="text-sm font-normal text-green-500"> / 100</span></p>
                    </div>
                </div>
                <p v-if="submission.correction_note" class="text-green-700 text-sm bg-white/60 rounded-lg p-3 mt-2">
                    <strong>Catatan Guru:</strong> {{ submission.correction_note }}
                </p>
                <div v-if="submission.correction_file" class="mt-3">
                    <a :href="`/storage/${submission.correction_file}`" target="_blank" class="inline-flex items-center gap-2 text-sm text-green-700 bg-white/70 hover:bg-white rounded-lg px-3 py-2 transition-colors">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                        Download File Koreksi
                    </a>
                </div>
            </div>

            <!-- Submission Details if Submitted -->
            <div v-if="submission" class="bg-blue-50/50 border border-blue-100 rounded-xl p-5">
                <div class="flex items-center gap-3 mb-3">
                    <div class="p-2 bg-blue-100 rounded-lg">
                        <svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                    </div>
                    <div>
                        <h3 class="font-semibold text-blue-800 text-sm">Tugas Sudah Dikumpulkan</h3>
                        <p class="text-xs text-blue-500">{{ formatDate(submission.submitted_at) }}</p>
                    </div>
                </div>
                <div class="space-y-2 ml-12">
                    <p v-if="submission.answer_text" class="text-sm text-slate-700 bg-white rounded-lg p-3 border border-slate-100 italic">"{{ submission.answer_text }}"</p>
                    <div v-if="submission.answer_link" class="flex items-center gap-2">
                        <svg class="w-4 h-4 text-blue-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"></path></svg>
                        <a :href="submission.answer_link" target="_blank" class="text-blue-600 hover:text-blue-800 hover:underline text-sm truncate">{{ submission.answer_link }}</a>
                    </div>
                    <div v-if="submission.files && submission.files.length > 0" class="flex flex-wrap gap-2">
                        <a v-for="file in submission.files" :key="file.id" :href="`/storage/${file.file_path}`" target="_blank" class="inline-flex items-center gap-1.5 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-slate-700 transition-colors">
                            <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"></path></svg>
                            {{ file.file_name }}
                        </a>
                    </div>
                </div>
                
                <div v-if="!is_past_due" class="mt-4 pt-4 border-t border-blue-100 ml-12">
                    <p class="text-xs text-blue-400 flex items-center gap-1">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
                        Ingin mengubah jawaban? Kirim ulang di bawah ini.
                    </p>
                </div>
            </div>

            <!-- Past Due Warning for Students -->
            <div v-if="is_past_due && !submission" class="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl">
                <div class="p-2 bg-red-100 rounded-lg flex-shrink-0">
                    <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                </div>
                <p class="font-semibold text-red-700 text-sm">Anda belum mengumpulkan tugas ini dan batas waktu sudah lewat.</p>
            </div>

            <!-- Submission Form -->
            <form v-if="!is_past_due" @submit.prevent="submitAssignment" class="space-y-5">
                <!-- Divider if there was previous submission -->
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
                    <Textarea id="answer_text" v-model="form.answer_text" class="mt-1 block w-full" rows="4" placeholder="Tulis jawaban kamu di sini..." />
                    <div v-if="form.errors.answer_text" class="text-red-500 text-xs flex items-center gap-1">
                        <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>
                        {{ form.errors.answer_text }}
                    </div>
                </div>

                <!-- Answer Link -->
                <div class="space-y-2">
                    <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">
                        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"></path></svg>
                        Link Jawaban
                        <span class="text-xs font-normal text-slate-400">(Google Drive / Docs / dll)</span>
                    </label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <svg class="w-4 h-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path></svg>
                        </div>
                        <Input id="answer_link" v-model="form.answer_link" type="url" class="mt-0 block w-full !pl-10" placeholder="https://drive.google.com/..." />
                    </div>
                    <div v-if="form.errors.answer_link" class="text-red-500 text-xs flex items-center gap-1">
                        <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>
                        {{ form.errors.answer_link }}
                    </div>
                </div>
                
                <!-- File Upload -->
                <div class="space-y-2">
                    <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">
                        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path></svg>
                        Upload File Jawaban
                        <span class="text-xs font-normal text-slate-400">(maks. 100MB)</span>
                    </label>
                    <label class="flex flex-col items-center justify-center w-full h-28 border-2 border-dashed border-slate-200 rounded-xl cursor-pointer bg-slate-50/50 hover:bg-indigo-50/50 hover:border-indigo-300 transition-all duration-200 group">
                        <div class="flex flex-col items-center justify-center py-4">
                            <svg class="w-8 h-8 text-slate-300 group-hover:text-indigo-400 transition-colors mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path></svg>
                            <p class="text-xs text-slate-400 group-hover:text-indigo-500 transition-colors"><span class="font-semibold">Klik untuk pilih file</span> atau drag & drop</p>
                            <p v-if="form.file" class="text-xs text-indigo-600 font-medium mt-1">{{ form.file.name }}</p>
                        </div>
                        <input type="file" class="hidden" @change="form.file = $event.target.files[0]" />
                    </label>
                    <div v-if="form.errors.file" class="text-red-500 text-xs flex items-center gap-1">
                        <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>
                        {{ form.errors.file }}
                    </div>
                </div>

                <!-- Submit Button -->
                <div class="flex items-center justify-between pt-4 border-t border-slate-100">
                    <p class="text-xs text-slate-400">Isi minimal salah satu: teks, link, atau file</p>
                    <Button type="submit" :disabled="form.processing" variant="primary" class="px-6">
                        <svg v-if="!form.processing" class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path></svg>
                        <svg v-else class="animate-spin w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                        {{ submission ? 'Update Jawaban' : 'Kirim Tugas' }}
                    </Button>
                </div>
            </form>

            <!-- Past Due & Already Submitted -->
            <div v-else-if="is_past_due && submission" class="flex items-center gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl">
                <div class="p-2 bg-amber-100 rounded-lg flex-shrink-0">
                    <svg class="w-5 h-5 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>
                </div>
                <p class="text-amber-700 text-sm">Batas waktu telah lewat. Anda tidak dapat mengubah jawaban lagi.</p>
            </div>
        </div>
    </div>
  </div>
</template>
