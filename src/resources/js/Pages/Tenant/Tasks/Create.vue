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
  description: '',
  task_date: props.todayDate,
  due_date: '',
  max_score: 100,
});

const submit = () => {
  form.post(route('tasks.store'));
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <div class="flex items-center gap-2 mb-1">
            <Link :href="route('tasks.index')" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Tugas & Nilai</Link>
            <span class="text-slate-300">/</span>
            <Link :href="route('tasks.class', schoolClass.id)" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Kelas {{ schoolClass.name }}</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">Tugas Baru</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Buat Tugas Baru</h2>
      </div>
    </div>

    <Card class="p-6 max-w-2xl">
        <form @submit.prevent="submit" class="space-y-6">
             <div>
                <Label for="subject_id" class="mb-1">Mata Pelajaran <span class="text-red-500">*</span></Label>
                <select id="subject_id" v-model="form.subject_id" required class="block w-full rounded-md border-gray-300 shadow-sm focus:border-orange-500 focus:ring-orange-500 sm:text-sm">
                    <option value="" disabled>Pilih Mata Pelajaran...</option>
                    <option v-for="subject in subjects" :key="subject.id" :value="subject.id">{{ subject.name }}</option>
                </select>
                <p v-if="form.errors.subject_id" class="mt-1 text-sm text-red-600">{{ form.errors.subject_id }}</p>
             </div>

             <div>
                <Label for="title" class="mb-1">Judul Tugas <span class="text-red-500">*</span></Label>
                <input type="text" id="title" v-model="form.title" required placeholder="Contoh: Latihan Pecahan Bab 3" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-orange-500 focus:ring-orange-500 sm:text-sm">
                <p v-if="form.errors.title" class="mt-1 text-sm text-red-600">{{ form.errors.title }}</p>
             </div>

             <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                 <div>
                    <Label for="task_date" class="mb-1">Tanggal Diberikan <span class="text-red-500">*</span></Label>
                    <input type="date" id="task_date" v-model="form.task_date" required class="block w-full rounded-md border-gray-300 shadow-sm focus:border-orange-500 focus:ring-orange-500 sm:text-sm">
                    <p v-if="form.errors.task_date" class="mt-1 text-sm text-red-600">{{ form.errors.task_date }}</p>
                 </div>
                 <div>
                    <Label for="due_date" class="mb-1">Tenggat Waktu / Deadline (Opsional)</Label>
                    <input type="date" id="due_date" v-model="form.due_date" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-orange-500 focus:ring-orange-500 sm:text-sm">
                    <p v-if="form.errors.due_date" class="mt-1 text-sm text-red-600">{{ form.errors.due_date }}</p>
                 </div>
             </div>

             <div>
                <Label for="max_score" class="mb-1">Nilai Maksimum <span class="text-red-500">*</span></Label>
                <input type="number" id="max_score" v-model="form.max_score" required min="1" max="1000" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-orange-500 focus:ring-orange-500 sm:text-sm max-w-[150px]">
                <p class="text-xs text-slate-500 mt-1">Standar nilai maksimum biasanya 100.</p>
                <p v-if="form.errors.max_score" class="mt-1 text-sm text-red-600">{{ form.errors.max_score }}</p>
             </div>

             <div>
                <Label for="description" class="mb-1">Deskripsi/Catatan (Opsional)</Label>
                <textarea id="description" v-model="form.description" rows="3" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-orange-500 focus:ring-orange-500 sm:text-sm"></textarea>
                <p v-if="form.errors.description" class="mt-1 text-sm text-red-600">{{ form.errors.description }}</p>
             </div>
             
             <div class="flex justify-end pt-4 border-t border-slate-100">
                 <Link :href="route('tasks.class', schoolClass.id)" class="mr-3 px-4 py-2 text-sm font-medium text-slate-700 hover:text-slate-900 border border-transparent">Batal</Link>
                 <Button type="submit" :disabled="form.processing">
                    Buat Tugas
                 </Button>
             </div>
        </form>
    </Card>
  </div>
</template>
