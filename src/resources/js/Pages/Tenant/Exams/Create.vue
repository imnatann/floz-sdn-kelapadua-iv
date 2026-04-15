<script setup>
import { useForm, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Label from '@/Components/UI/Label.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  schoolClass: Object,
  subjects: Array,
  todayDate: String,
});

const form = useForm({
  class_id: props.schoolClass.id,
  subject_id: '',
  title: '',
  exam_type: 'ulangan_harian',
  exam_date: props.todayDate,
  max_score: 100,
});

const submit = () => {
  form.post(route('exams.store'));
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <div class="flex items-center gap-2 mb-1">
            <Link :href="route('exams.index')" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Nilai Ujian</Link>
            <span class="text-slate-300">/</span>
            <Link :href="route('exams.class', schoolClass.id)" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Kelas {{ schoolClass.name }}</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">Ujian Baru</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Buat Ujian Baru</h2>
      </div>
    </div>

    <Card class="p-6 max-w-2xl">
        <form @submit.prevent="submit" class="space-y-6">
             <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                 <div class="sm:col-span-2">
                    <Label for="exam_type" class="mb-1">Tipe Ujian <span class="text-red-500">*</span></Label>
                    <select id="exam_type" v-model="form.exam_type" required class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm bg-slate-50">
                        <option value="ulangan_harian">Ulangan Harian (Asesmen Formatif)</option>
                        <option value="uts">Sumatif Tengah Semester (UTS/PTS)</option>
                        <option value="uas">Sumatif Akhir Semester (UAS/PAS)</option>
                    </select>
                    <p class="mt-1 text-xs text-slate-500">Nilai UTS dan UAS akan otomatis masuk ke formula rapor akhir.</p>
                 </div>

                 <div class="sm:col-span-2">
                    <Label for="subject_id" class="mb-1">Mata Pelajaran <span class="text-red-500">*</span></Label>
                    <select id="subject_id" v-model="form.subject_id" required class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                        <option value="" disabled>Pilih Mata Pelajaran...</option>
                        <option v-for="subject in subjects" :key="subject.id" :value="subject.id">{{ subject.name }}</option>
                    </select>
                    <p v-if="form.errors.subject_id" class="mt-1 text-sm text-red-600">{{ form.errors.subject_id }}</p>
                 </div>

                 <div class="sm:col-span-2">
                    <Label for="title" class="mb-1">Judul Ujian <span class="text-red-500">*</span></Label>
                    <input type="text" id="title" v-model="form.title" required placeholder="Contoh: Ulangan Harian Bab 1 - Pancasila" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                    <p v-if="form.errors.title" class="mt-1 text-sm text-red-600">{{ form.errors.title }}</p>
                 </div>

                 <div>
                    <Label for="exam_date" class="mb-1">Tanggal Pelaksanaan <span class="text-red-500">*</span></Label>
                    <input type="date" id="exam_date" v-model="form.exam_date" required class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                    <p v-if="form.errors.exam_date" class="mt-1 text-sm text-red-600">{{ form.errors.exam_date }}</p>
                 </div>

                 <div>
                    <Label for="max_score" class="mb-1">Nilai Maksimum <span class="text-red-500">*</span></Label>
                    <input type="number" id="max_score" v-model="form.max_score" required min="1" max="1000" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm max-w-[150px]">
                    <p class="text-xs text-slate-500 mt-1">Standar adalah 100.</p>
                    <p v-if="form.errors.max_score" class="mt-1 text-sm text-red-600">{{ form.errors.max_score }}</p>
                 </div>
             </div>
             
             <div class="flex justify-end pt-4 border-t border-slate-100">
                 <Link :href="route('exams.class', schoolClass.id)" class="mr-3 px-4 py-2 text-sm font-medium text-slate-700 hover:text-slate-900 border border-transparent">Batal</Link>
                 <Button type="submit" :disabled="form.processing">
                    Buat Ujian
                 </Button>
             </div>
        </form>
    </Card>
  </div>
</template>
