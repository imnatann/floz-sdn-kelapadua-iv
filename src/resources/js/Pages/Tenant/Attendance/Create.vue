<script setup>
import { ref, watch } from 'vue';
import { useForm, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Label from '@/Components/UI/Label.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  schoolClass: Object,
  students: Array,
  nextMeetingNumber: Number,
  todayDate: String,
  existingMeetings: {
    type: Array,
    default: () => []
  }
});

const form = useForm({
  meeting_number: props.nextMeetingNumber,
  date: props.todayDate,
  attendances: props.students.map(s => ({
      student_id: s.id,
      status: 'present',
      notes: ''
  })),
});

const statusOptions = [
  { value: 'present', label: 'Hadir', class: 'bg-emerald-100 text-emerald-800 ring-emerald-500' },
  { value: 'sick', label: 'Sakit', class: 'bg-blue-100 text-blue-800 ring-blue-500' },
  { value: 'permit', label: 'Izin', class: 'bg-amber-100 text-amber-800 ring-amber-500' },
  { value: 'absent', label: 'Alpha', class: 'bg-rose-100 text-rose-800 ring-rose-500' },
];

const submit = () => {
  form.post(route('attendance.store', props.schoolClass.id));
};

const markAll = (status) => {
  form.attendances.forEach(a => Object.assign(a, {status: status}));
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <div class="flex items-center gap-2 mb-1">
            <Link :href="route('attendance.index')" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Absensi</Link>
            <span class="text-slate-300">/</span>
            <Link :href="route('attendance.show', schoolClass.id)" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Kelas {{ schoolClass.name }}</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">Pertemuan Baru</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Absen Pertemuan Kelas {{ schoolClass.name }}</h2>
      </div>
      <div>
         <Button :disabled="form.processing" @click="submit">
            Simpan Absensi
         </Button>
      </div>
    </div>

    <!-- Error Alert -->
    <div v-if="Object.keys(form.errors).length > 0" class="rounded-lg bg-red-50 p-4 border border-red-200">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">Terdapat kesalahan pada isian Anda:</h3>
          <div class="mt-2 text-sm text-red-700">
            <ul role="list" class="list-disc space-y-1 pl-5">
              <li v-for="(error, key) in form.errors" :key="key">{{ error }}</li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <Card class="p-5">
        <div class="flex flex-col gap-4">
            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 items-end">
                 <div>
                    <Label for="meeting_number">Pertemuan Ke-</Label>
                    <input type="number" id="meeting_number" v-model="form.meeting_number" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" min="1">
                 </div>
                 <div>
                    <Label for="date">Tanggal</Label>
                    <input type="date" id="date" v-model="form.date" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                 </div>
                 
                 <div class="lg:col-span-2 flex justify-end gap-3 pb-2">
                     <button @click="markAll('present')" class="text-sm font-medium text-emerald-600 hover:text-emerald-800 hover:underline">Tandai Semua Hadir</button>
                 </div>
            </div>
            <div v-if="existingMeetings?.length > 0" class="text-xs text-slate-500 bg-slate-50 p-2 rounded border border-slate-100">
                <span class="font-semibold text-slate-700">Info:</span> Pertemuan yang sudah diisi absennya: 
                <span class="font-mono text-blue-600 font-medium">
                    {{ existingMeetings.map(m => 'P' + m.meeting_number).join(', ') }}
                </span>
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
                        <th class="px-5 py-3 text-center w-80">Status Kehadiran</th>
                        <th class="px-5 py-3">Catatan</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(student, index) in students" :key="student.id" class="bg-white border-b border-slate-50 hover:bg-slate-50/50">
                        <td class="px-5 py-4 font-mono text-slate-500 text-center">{{ index + 1 }}</td>
                        <td class="px-5 py-4 font-medium text-slate-900">{{ student.name }}</td>
                        <td class="px-5 py-4">
                            <div class="flex justify-center gap-1.5">
                                 <label v-for="status in statusOptions" :key="status.value" 
                                    class="cursor-pointer select-none rounded-md px-3 py-1.5 text-xs font-bold transition-all border"
                                    :class="form.attendances[index].status === status.value 
                                        ? `${status.class} ring-2 ring-offset-1 border-transparent` 
                                        : 'border-slate-200 text-slate-500 hover:bg-slate-50'"
                                 >
                                    <input type="radio" :name="`status-${student.id}`" :value="status.value" v-model="form.attendances[index].status" class="sr-only">
                                    {{ status.label }}
                                 </label>
                            </div>
                        </td>
                        <td class="px-5 py-4">
                            <input type="text" v-model="form.attendances[index].notes" class="block w-full rounded-md border-0 py-1.5 text-slate-900 shadow-sm ring-1 ring-inset ring-slate-300 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-xs sm:leading-6" placeholder="Opsional...">
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
                Simpan Absensi
             </Button>
        </div>
    </Card>
  </div>
</template>
