<script setup>
import { useForm, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Label from '@/Components/UI/Label.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  schoolClass: Object,
  students: Array,
  meetingNumber: [Number, String],
  meetingDate: String,
  existingAttendances: Object,
});

const form = useForm({
  date: props.meetingDate,
  attendances: props.students.map(s => {
      const existing = props.existingAttendances[s.id] || [];
      const record = existing.length > 0 ? existing[0] : null; // Assuming existingAttendances might be grouped
      // Handling object vs array. In controller: ->keyBy('student_id') makes it an object where key is student_id and value is the record itself.
      const actualExisting = props.existingAttendances[s.id] 
        ? (Array.isArray(props.existingAttendances[s.id]) ? props.existingAttendances[s.id][0] : props.existingAttendances[s.id]) 
        : null;

      return {
          student_id: s.id,
          status: actualExisting ? actualExisting.status : 'absent',
          notes: actualExisting ? actualExisting.notes : ''
      };
  }),
});

const statusOptions = [
  { value: 'present', label: 'Hadir', class: 'bg-emerald-100 text-emerald-800 ring-emerald-500' },
  { value: 'sick', label: 'Sakit', class: 'bg-blue-100 text-blue-800 ring-blue-500' },
  { value: 'permit', label: 'Izin', class: 'bg-amber-100 text-amber-800 ring-amber-500' },
  { value: 'absent', label: 'Alpha', class: 'bg-rose-100 text-rose-800 ring-rose-500' },
];

const submit = () => {
  form.put(route('attendance.update', { class: props.schoolClass.id, meeting: props.meetingNumber }));
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
            <span class="text-sm font-medium text-slate-900">Edit Pertemuan {{ meetingNumber }}</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Edit Absen P{{ meetingNumber }} Kelas {{ schoolClass.name }}</h2>
      </div>
      <div>
         <Button :disabled="form.processing" @click="submit">
            Update Absensi
         </Button>
      </div>
    </div>

    <Card class="p-5">
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 items-end">
             <div>
                <Label for="meeting_number">Pertemuan Ke-</Label>
                <input type="number" id="meeting_number" :value="meetingNumber" disabled class="mt-1 block w-full rounded-md border-slate-200 bg-slate-50 shadow-sm sm:text-sm text-slate-500">
             </div>
             <div>
                <Label for="date">Tanggal</Label>
                <input type="date" id="date" v-model="form.date" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
             </div>
             
             <div class="lg:col-span-2 flex justify-end gap-3 pb-2">
                 <button @click="markAll('present')" class="text-sm font-medium text-emerald-600 hover:text-emerald-800 hover:underline">Tandai Semua Hadir</button>
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
        
        <div class="p-4 border-t border-slate-100 bg-slate-50 flex justify-end" v-if="students.length > 0">
             <Button :disabled="form.processing" @click="submit">
                Update Absensi
             </Button>
        </div>
    </Card>
  </div>
</template>
