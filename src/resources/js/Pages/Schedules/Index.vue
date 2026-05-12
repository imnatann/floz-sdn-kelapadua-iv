<script setup>
import AppLayout from '@/Layouts/AppLayout.vue';
import { Head, useForm, router, Link } from '@inertiajs/vue3';
import { ref, computed } from 'vue';
import Modal from '@/Components/UI/Modal.vue';
import FormInput from '@/Components/UI/FormInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    classes: Array,
    schedules: [Array, Object], // Grouped by day_of_week
    teachingAssignments: Array, // For dropdown
    filters: Object,
    selectedClass: Object,
});

const isModalOpen = ref(false);
const selectedDay = ref(1);
const editingScheduleId = ref(null);
const isEditMode = computed(() => editingScheduleId.value !== null);

const form = useForm({
    day_of_week: 1,
    items: [
        { teaching_assignment_id: '', start_time: '07:00', end_time: '08:00' }
    ],
});

const editForm = useForm({
    day_of_week: 1,
    teaching_assignment_id: '',
    start_time: '07:00',
    end_time: '08:00',
});

const openEditModal = (schedule) => {
    editingScheduleId.value = schedule.id;
    editForm.day_of_week = schedule.day_of_week;
    editForm.teaching_assignment_id = schedule.teaching_assignment_id;
    editForm.start_time = schedule.start_time.substring(0, 5);
    editForm.end_time = schedule.end_time.substring(0, 5);
    isModalOpen.value = true;
};

const deleteSchedule = (schedule) => {
    if (!confirm(`Hapus jadwal "${schedule.teaching_assignment.subject.name}" (${schedule.start_time.substring(0,5)}-${schedule.end_time.substring(0,5)})?`)) return;
    router.delete(route('schedules.destroy', schedule.id), {
        preserveScroll: true,
    });
};

const days = [
    { id: 1, name: 'Senin' },
    { id: 2, name: 'Selasa' },
    { id: 3, name: 'Rabu' },
    { id: 4, name: 'Kamis' },
    { id: 5, name: 'Jumat' },
    { id: 6, name: 'Sabtu' },
    { id: 7, name: 'Minggu' },
];

const assignmentOptions = computed(() => {
    return props.teachingAssignments.map(assignment => ({
        label: `${assignment.subject?.name ?? 'Unknown'} (${assignment.teacher?.name ?? 'Unknown'})`,
        value: assignment.id,
    }));
});

const openAddModal = (dayId) => {
    if (!props.selectedClass) {
        alert('Pilih kelas terlebih dahulu!');
        return;
    }
    selectedDay.value = dayId;
    form.day_of_week = dayId;
    form.items = [
        { teaching_assignment_id: '', start_time: '07:00', end_time: '08:00' }
    ];
    isModalOpen.value = true;
};

const addItem = () => {
    form.items.push({ teaching_assignment_id: '', start_time: '08:00', end_time: '09:00' });
};

const removeItem = (index) => {
    form.items.splice(index, 1);
};

const submit = () => {
    if (isEditMode.value) {
        editForm.put(route('schedules.update', editingScheduleId.value), {
            preserveScroll: true,
            onSuccess: () => {
                isModalOpen.value = false;
                editingScheduleId.value = null;
                editForm.reset();
            },
        });
    } else {
        form.post(route('schedules.store'), {
            onSuccess: () => {
                isModalOpen.value = false;
                form.reset();
            },
        });
    }
};

const closeModal = () => {
    isModalOpen.value = false;
    editingScheduleId.value = null;
    form.reset();
    editForm.reset();
};

const onClassChange = (e) => {
    router.visit(route('schedules.index', { class_id: e.target.value }));
};

// --- Calendar State (Month View) ---
const currentDate = ref(new Date());

const monthYear = computed(() => {
    return currentDate.value.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
});

const calendarDays = computed(() => {
    const year = currentDate.value.getFullYear();
    const month = currentDate.value.getMonth();
    
    const firstDayOfMonth = new Date(year, month, 1);
    const lastDayOfMonth = new Date(year, month + 1, 0);
    
    const daysInMonth = lastDayOfMonth.getDate();
    // Monday as start of week (1), if Sunday (0) make it 7
    let startDay = firstDayOfMonth.getDay(); 
    if (startDay === 0) startDay = 7; 
    
    const daysArr = [];
    
    // Previous month padding
    for (let i = 1; i < startDay; i++) {
        daysArr.push({ id: `prev-${i}`, date: '', isPadding: true });
    }
    
    // Current month days
    for (let i = 1; i <= daysInMonth; i++) {
        const date = new Date(year, month, i);
        // dayOfWeek: 1 (Mon) - 7 (Sun)
        let dayOfWeek = date.getDay();
        if (dayOfWeek === 0) dayOfWeek = 7; 

        // Match existing days array for name
        const dayName = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'][date.getDay()];
        
        daysArr.push({
            id: i,
            day: dayName,
            date: i, 
            fullDate: date,
            day_of_week: dayOfWeek,
            isPadding: false,
            isToday: new Date().toDateString() === date.toDateString()
        });
    }
    
    return daysArr;
});

const prevMonth = () => {
    currentDate.value = new Date(currentDate.value.setMonth(currentDate.value.getMonth() - 1));
};

const nextMonth = () => {
    currentDate.value = new Date(currentDate.value.setMonth(currentDate.value.getMonth() + 1));
};

const goToToday = () => {
    currentDate.value = new Date();
};

const weekHeaders = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
</script>

<template>
    <Head title="Jadwal Pelajaran" />

    <div class="space-y-6">
    <div class="space-y-6">
        <!-- class Selection View -->
        <div v-if="!selectedClass" class="space-y-6">
            <div class="rounded-none border-2 border-slate-900 bg-white p-6 shadow-[4px_4px_0px_0px_rgba(15,23,42,1)]">
                <h2 class="text-2xl font-black uppercase tracking-tight text-slate-900">Pilih Kelas</h2>
                <p class="mt-1 font-mono text-sm text-slate-500">Pilih kelas untuk mengelola jadwal pelajaran.</p>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                <Link 
                    v-for="cls in classes" 
                    :key="cls.id" 
                    :href="route('schedules.index', { class_id: cls.id })"
                    class="group relative flex flex-col justify-between min-h-[140px] bg-white p-4 border-2 border-slate-900 shadow-[4px_4px_0px_0px_rgba(15,23,42,1)] hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(15,23,42,1)] transition-all"
                >
                    <div>
                        <h3 class="text-xl font-black text-slate-900 group-hover:text-orange-600 transition-colors">{{ cls.name }}</h3>
                        <p class="text-xs font-mono text-slate-500 mt-1 truncate" v-if="cls.homeroom_teacher">
                            Wali: {{ cls.homeroom_teacher.name }}
                        </p>
                        <p class="text-xs font-mono text-slate-400 mt-1 italic" v-else>
                            Belum ada Wali Kelas
                        </p>
                    </div>

                    <div class="mt-4 flex items-center justify-between">
                         <div class="flex flex-col gap-1 text-[10px] uppercase font-bold text-slate-500">
                            <span class="flex items-center gap-1">
                                👨‍🎓 {{ cls.students_count }} Siswa
                            </span>
                            <span class="flex items-center gap-1">
                                📚 {{ cls.teaching_assignments_count }} Mapel
                            </span>
                         </div>
                         <span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-slate-100 group-hover:bg-slate-900 group-hover:text-white transition-colors">
                            &rarr;
                         </span>
                    </div>
                </Link>
            </div>
        </div>

        <!-- Calendar View -->
        <div v-else class="space-y-6">
            <!-- Header & Navigation -->
            <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-none border-2 border-slate-900 bg-white p-6 shadow-[4px_4px_0px_0px_rgba(15,23,42,1)]">
                <div>
                    <div class="flex items-center gap-3 mb-1">
                        <Link :href="route('schedules.index')" class="text-slate-400 hover:text-slate-900 transition-colors">
                            &larr; Kembali
                        </Link>
                        <span class="text-slate-300">|</span>
                        <h2 class="text-2xl font-black uppercase tracking-tight text-slate-900">Jadwal {{ selectedClass.name }}</h2>
                    </div>
                    <p class="font-mono text-sm text-slate-500">Atur jadwal pelajaran minggu ini.</p>
                </div>
                
                <div class="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
                    <div class="flex items-center border-2 border-slate-900 bg-white shadow-[2px_2px_0px_0px_rgba(15,23,42,1)]">
                        <button @click="prevMonth" class="px-3 py-2 hover:bg-slate-100 font-bold border-r-2 border-slate-900">&lt;</button>
                        <button @click="goToToday" class="px-3 py-2 hover:bg-slate-100 font-bold border-r-2 border-slate-900 text-xs uppercase tracking-wider">Hari Ini</button>
                        <span class="px-4 py-2 font-black uppercase min-w-[200px] text-center text-sm">{{ monthYear }}</span>
                        <button @click="nextMonth" class="px-3 py-2 hover:bg-slate-100 font-bold border-l-2 border-slate-900">&gt;</button>
                    </div>
                </div>
            </div>

            <!-- Month Grid (Restored) -->
            <div class="border-2 border-slate-900 bg-slate-900">
            <!-- Global Headers -->
            <div class="grid grid-cols-7 bg-slate-900 gap-[2px] border-b-[2px] border-slate-900">
                 <div v-for="header in weekHeaders" :key="header" class="bg-white p-2 text-center font-black text-sm uppercase">
                    {{ header }}
                 </div>
            </div>

            <!-- Days Grid -->
            <div class="grid grid-cols-7 bg-slate-900 gap-[2px]">
                <div 
                    v-for="(day, index) in calendarDays" 
                    :key="index" 
                    class="bg-white min-h-[180px] p-2 flex flex-col relative group hover:bg-slate-50 transition-colors"
                >
                    <template v-if="!day.isPadding">
                        <!-- Date Number -->
                        <div class="flex justify-between items-start mb-2">
                            <span 
                                class="text-lg font-black leading-none"
                                :class="day.isToday ? 'text-orange-600' : 'text-slate-900'"
                            >
                                {{ day.date }}
                            </span>
                            
                            <!-- Add Button (Small) -->
                            <button 
                                v-if="$page.props.auth.permissions.manage_classes"
                                @click="openAddModal(day.day_of_week)"
                                class="opacity-0 group-hover:opacity-100 h-6 w-6 flex items-center justify-center rounded-full bg-slate-100 hover:bg-slate-900 hover:text-white transition-all text-xs font-bold"
                            >
                                +
                            </button>
                        </div>

                        <!-- Schedules List (Detailed Vertical Cards) -->
                        <div class="space-y-1 flex-1">
                            <div 
                                v-for="schedule in (schedules[day.day_of_week] || [])" 
                                :key="schedule.id"
                                class="flex flex-col gap-1 border-2 border-slate-900 bg-white p-2 shadow-[2px_2px_0px_0px_rgba(15,23,42,1)] hover:translate-x-[1px] hover:translate-y-[1px] hover:shadow-none transition-all cursor-default group/card"
                                :class="{ 'ring-2 ring-orange-500 ring-offset-1': day.isToday }"
                            >
                                <!-- Time Badge -->
                                <div class="text-[10px] font-black bg-slate-100 px-1 w-fit border border-slate-900 group-hover/card:bg-slate-900 group-hover/card:text-white transition-colors">
                                    {{ schedule.start_time.substring(0,5) }} - {{ schedule.end_time.substring(0,5) }}
                                </div>
                                
                                <!-- Subject -->
                                <div class="font-bold text-xs leading-tight text-slate-900 line-clamp-2" :title="schedule.teaching_assignment.subject.name">
                                    {{ schedule.teaching_assignment.subject.name }}
                                </div>
                                
                                <!-- Teacher -->
                                <div class="text-[10px] font-mono text-slate-500 truncate flex items-center gap-1">
                                    <span>👨‍🏫</span>
                                    {{ schedule.teaching_assignment.teacher.name }}
                                </div>

                                <!-- Edit/Delete row (admin only, on hover) -->
                                <div
                                    v-if="$page.props.auth.permissions.manage_classes"
                                    class="opacity-0 group-hover/card:opacity-100 flex gap-1 mt-1 pt-1 border-t border-slate-200 transition-opacity"
                                >
                                    <button
                                        @click.stop="openEditModal(schedule)"
                                        class="flex-1 text-[10px] font-bold py-1 bg-blue-50 hover:bg-blue-600 hover:text-white text-blue-700 border border-blue-200 hover:border-blue-700 transition-colors"
                                        title="Edit jadwal"
                                    >
                                        ✏️ Edit
                                    </button>
                                    <button
                                        @click.stop="deleteSchedule(schedule)"
                                        class="flex-1 text-[10px] font-bold py-1 bg-red-50 hover:bg-red-600 hover:text-white text-red-700 border border-red-200 hover:border-red-700 transition-colors"
                                        title="Hapus jadwal"
                                    >
                                        🗑️ Hapus
                                    </button>
                                </div>
                            </div>
                        </div>
                    </template>
                    <template v-else>
                         <div class="bg-slate-100 h-full w-full opacity-50"></div>
                    </template>
                </div>
            </div>
        </div>

        </div>
    </div>

        <!-- Add/Edit Modal -->
        <Modal :show="isModalOpen" @close="closeModal">
            <div class="p-6">
                <h2 class="text-lg font-bold text-slate-900 mb-4">
                    {{ isEditMode ? `Edit Jadwal — ${selectedClass?.name}` : `Tambah Jadwal ${days.find(d => d.id === selectedDay)?.name} - ${selectedClass?.name}` }}
                </h2>

                <!-- EDIT FORM (single row) -->
                <form v-if="isEditMode" @submit.prevent="submit" class="space-y-4">
                    <FormSelect
                        label="Hari"
                        v-model="editForm.day_of_week"
                        :options="days.map(d => ({ label: d.name, value: d.id }))"
                        required
                        :error="editForm.errors.day_of_week"
                    />
                    <FormSelect
                        label="Mapel & Guru"
                        v-model="editForm.teaching_assignment_id"
                        :options="assignmentOptions"
                        placeholder="Pilih Mapel..."
                        required
                        :error="editForm.errors.teaching_assignment_id"
                    />
                    <div class="grid grid-cols-2 gap-3">
                        <FormInput label="Mulai" type="time" v-model="editForm.start_time" :error="editForm.errors.start_time" />
                        <FormInput label="Selesai" type="time" v-model="editForm.end_time" :error="editForm.errors.end_time" />
                    </div>
                    <div class="mt-6 flex justify-end gap-3 border-t-2 border-slate-900 pt-4">
                        <Button variant="secondary" @click="closeModal">Batal</Button>
                        <Button type="submit" :loading="editForm.processing" class="rounded-none border-2 border-transparent shadow-none">
                            Simpan Perubahan
                        </Button>
                    </div>
                </form>

                <!-- ADD FORM (multi-item, original) -->
                <form v-else @submit.prevent="submit" class="space-y-4">
                    <!-- Dynamic Rows -->
                    <div class="space-y-4 max-h-[60vh] overflow-y-auto pr-2">
                        <div v-for="(item, index) in form.items" :key="index" class="relative flex gap-3 items-start border-b border-slate-200 pb-4 last:border-0 last:pb-0">
                            <!-- Number -->
                            <div class="pt-3 text-sm font-bold text-slate-400 font-mono w-6">
                                {{ index + 1 }}.
                            </div>

                            <div class="flex-1 space-y-3">
                                <template v-if="assignmentOptions.length > 0">
                                    <FormSelect
                                        label="Mapel & Guru"
                                        v-model="item.teaching_assignment_id"
                                        :options="assignmentOptions"
                                        placeholder="Pilih Mapel..."
                                        required
                                        :error="form.errors[`items.${index}.teaching_assignment_id`]"
                                    />
                                </template>
                                <template v-else>
                                    <div class="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
                                        <div class="flex items-center gap-2 font-bold mb-1">
                                            <span class="text-lg">⚠️</span>
                                            <span>Belum ada Mapel</span>
                                        </div>
                                        <p class="mb-3">
                                            Belum ada mata pelajaran yang ditugaskan ke guru untuk kelas ini. 
                                            Jadwal tidak bisa dibuat tanpa penugasan guru.
                                        </p>
                                        <a 
                                            :href="`/teaching-assignments?class_id=${props.filters.class_id}`"
                                            class="inline-flex items-center gap-1 rounded bg-amber-100 px-3 py-1.5 text-xs font-bold text-amber-900 hover:bg-amber-200 transition-colors"
                                        >
                                            Atur Penugasan Guru &rarr;
                                        </a>
                                    </div>
                                </template>

                                <div class="grid grid-cols-2 gap-3" v-if="assignmentOptions.length > 0">
                                    <FormInput
                                        label="Mulai"
                                        type="time"
                                        v-model="item.start_time"
                                        :error="form.errors[`items.${index}.start_time`]"
                                        class="block border-2" 
                                    />
                                    <FormInput
                                        label="Selesai"
                                        type="time"
                                        v-model="item.end_time"
                                        :error="form.errors[`items.${index}.end_time`]"
                                        class="block border-2"
                                    />
                                </div>
                            </div>

                            <!-- Delete Row -->
                            <button 
                                v-if="form.items.length > 1"
                                type="button"
                                @click="removeItem(index)"
                                class="mt-8 text-slate-400 hover:text-red-500 transition-colors"
                                title="Hapus baris"
                            >
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 18 12"/></svg>
                            </button>
                        </div>
                    </div>

                    <!-- Add Row Button -->
                    <div class="pt-2 border-t border-slate-100" v-if="assignmentOptions.length > 0">
                        <button 
                            type="button" 
                            @click="addItem"
                            class="text-sm font-bold text-orange-600 hover:text-orange-700 hover:underline flex items-center gap-1"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
                            Tambah Mapel Lain
                        </button>
                    </div>

                    <div class="mt-6 flex justify-end gap-3 border-t-2 border-slate-900 pt-4">
                        <Button variant="secondary" @click="closeModal">Batal</Button>
                        <Button
                            type="submit"
                            :loading="form.processing"
                            :disabled="assignmentOptions.length === 0"
                            class="rounded-none border-2 border-transparent shadow-none"
                        >
                            Simpan Semua
                        </Button>
                    </div>
                </form>
            </div>
        </Modal>
    </div>
</template>
