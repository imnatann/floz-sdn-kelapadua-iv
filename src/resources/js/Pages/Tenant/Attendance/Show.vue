<script setup>
import { Link, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
    schoolClass: Object,
    students: Array,
    meetings: Array,
    attendances: Object,
    activeSemester: Object,
});

const getAttendanceStatus = (studentId, meetingNumber) => {
    if (!props.attendances[studentId]) return null;
    return props.attendances[studentId].find(a => a.meeting_number === meetingNumber);
};

const getStatusBadgeClass = (status) => {
    switch (status) {
        case 'present': return 'bg-emerald-100 text-emerald-800';
        case 'sick': return 'bg-blue-100 text-blue-800';
        case 'permit': return 'bg-amber-100 text-amber-800';
        case 'absent': return 'bg-rose-100 text-rose-800';
        default: return 'bg-slate-100 text-slate-800';
    }
};

const getStatusLabel = (status) => {
    switch (status) {
        case 'present': return 'H';
        case 'sick': return 'S';
        case 'permit': return 'I';
        case 'absent': return 'A';
        default: return '-';
    }
};

const getStudentSummary = (studentId) => {
     let summary = { present: 0, sick: 0, permit: 0, absent: 0 };
     if (!props.attendances[studentId]) return summary;
     
     props.attendances[studentId].forEach(a => {
         if (summary[a.status] !== undefined) {
             summary[a.status]++;
         }
     });
     return summary;
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
      <div>
        <div class="flex items-center gap-2 mb-1">
            <Link :href="route('attendance.index')" class="text-sm font-medium text-slate-500 hover:text-slate-700 hover:underline">Absensi</Link>
            <span class="text-slate-300">/</span>
            <span class="text-sm font-medium text-slate-900">Kelas {{ schoolClass.name }}</span>
        </div>
        <h2 class="text-xl font-bold text-slate-800">Rekap Absensi: {{ schoolClass.name }}</h2>
        <p class="mt-0.5 text-sm text-slate-400">Semester Aktif: {{ activeSemester?.semester_number || '-' }} - {{ activeSemester?.academic_year?.name || 'Sekarang' }}</p>
      </div>
      <div>
         <Link :href="route('attendance.create', schoolClass.id)">
             <Button>
                Absen Pertemuan Baru
             </Button>
         </Link>
      </div>
    </div>

    <Card class="overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-sm text-left whitespace-nowrap">
                <thead class="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100">
                    <tr>
                        <th class="px-4 py-3 sticky left-0 bg-slate-50 z-10 w-12 border-r border-slate-100">No</th>
                        <th class="px-4 py-3 sticky left-[3rem] bg-slate-50 z-10 border-r border-slate-200">Nama Siswa</th>
                        
                        <th v-for="meeting in meetings" :key="meeting.meeting_number" class="px-3 py-3 text-center border-r border-slate-100 min-w-[3rem]">
                            <div class="flex flex-col items-center group relative cursor-pointer" @click="router.get(route('attendance.edit', {class: schoolClass.id, meeting: meeting.meeting_number}))">
                                <span class="font-bold text-slate-700 group-hover:text-orange-600 transition-colors">P{{ meeting.meeting_number }}</span>
                                <span class="text-[10px] font-normal text-slate-400 mt-1">{{ meeting.date }}</span>
                                <!-- Tooltip -->
                                <div class="absolute bottom-full mb-1 hidden group-hover:block bg-slate-800 text-white text-[10px] rounded px-2 py-1 z-20 whitespace-nowrap">
                                    Edit P{{ meeting.meeting_number }}
                                </div>
                            </div>
                        </th>

                        <!-- Summary Columns -->
                        <th class="px-3 py-3 text-center bg-emerald-50 text-emerald-700 border-l border-emerald-100 min-w-[3rem]">H</th>
                        <th class="px-3 py-3 text-center bg-blue-50 text-blue-700 min-w-[3rem]">S</th>
                        <th class="px-3 py-3 text-center bg-amber-50 text-amber-700 min-w-[3rem]">I</th>
                        <th class="px-3 py-3 text-center bg-rose-50 text-rose-700 min-w-[3rem]">A</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(student, index) in students" :key="student.id" class="bg-white border-b border-slate-50 hover:bg-slate-50/50">
                        <td class="px-4 py-3 font-mono text-slate-500 sticky left-0 bg-white border-r border-slate-100 group-hover:bg-slate-50/50">{{ index + 1 }}</td>
                        <td class="px-4 py-3 font-medium text-slate-900 sticky left-[3rem] bg-white border-r border-slate-200 group-hover:bg-slate-50/50">{{ student.name }}</td>
                        
                        <td v-for="meeting in meetings" :key="meeting.meeting_number" class="px-3 py-3 text-center border-r border-slate-50">
                            <span v-if="getAttendanceStatus(student.id, meeting.meeting_number)" 
                                  class="inline-flex items-center justify-center w-6 h-6 rounded text-xs font-bold"
                                  :class="getStatusBadgeClass(getAttendanceStatus(student.id, meeting.meeting_number).status)"
                                  :title="getAttendanceStatus(student.id, meeting.meeting_number).notes || 'Telah diabsen'"
                            >
                                {{ getStatusLabel(getAttendanceStatus(student.id, meeting.meeting_number).status) }}
                            </span>
                            <span v-else class="text-slate-300">-</span>
                        </td>

                        <td class="px-3 py-3 text-center bg-slate-50 border-r border-slate-100 font-medium text-slate-700">{{ getStudentSummary(student.id).present }}</td>
                        <td class="px-3 py-3 text-center bg-slate-50 border-r border-slate-100 font-medium text-slate-700">{{ getStudentSummary(student.id).sick }}</td>
                        <td class="px-3 py-3 text-center bg-slate-50 border-r border-slate-100 font-medium text-slate-700">{{ getStudentSummary(student.id).permit }}</td>
                        <td class="px-3 py-3 text-center bg-slate-50 font-medium text-slate-700">{{ getStudentSummary(student.id).absent }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <div v-if="meetings.length === 0" class="text-center py-12 p-4">
            <p class="text-slate-500">Belum ada data absensi untuk kelas ini di semester aktif.</p>
        </div>
    </Card>
    
    <div class="mt-4 flex flex-wrap gap-4 text-xs text-slate-500">
        <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded block bg-emerald-100"></span> Hadir</div>
        <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded block bg-blue-100"></span> Sakit</div>
        <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded block bg-amber-100"></span> Izin</div>
        <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded block bg-rose-100"></span> Alpha</div>
        <div class="flex items-center gap-1.5 ml-4 text-slate-400">P = Pertemuan</div>
    </div>
  </div>
</template>
