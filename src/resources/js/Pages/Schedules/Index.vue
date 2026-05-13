<script setup>
import AppLayout from '@/Layouts/AppLayout.vue';
import { Head, useForm, router, Link, usePage } from '@inertiajs/vue3';
import { ref, computed, watch } from 'vue';
import Modal from '@/Components/UI/Modal.vue';
import FormInput from '@/Components/UI/FormInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
  classes: Array,
  schedules: [Array, Object], // Grouped by day_of_week
  teachingAssignments: Array,
  academicYears: { type: Array, default: () => [] },
  filters: Object,
  selectedClass: Object,
});

const page = usePage();
const canManage = computed(() => !!page.props.auth?.permissions?.manage_classes);

const academicYearId = ref(props.filters?.academic_year_id ?? '');

watch(academicYearId, () => {
  router.get(
    '/schedules',
    { academic_year_id: academicYearId.value || undefined },
    { preserveState: true, preserveScroll: true, replace: true }
  );
});

const isModalOpen = ref(false);
const selectedDay = ref(1);
const editingScheduleId = ref(null);
const isEditMode = computed(() => editingScheduleId.value !== null);

const form = useForm({
  day_of_week: 1,
  items: [{ teaching_assignment_id: '', start_time: '07:00', end_time: '08:00' }],
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
  router.delete(route('schedules.destroy', schedule.id), { preserveScroll: true });
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

const assignmentOptions = computed(() =>
  props.teachingAssignments.map(a => ({
    label: `${a.subject?.name ?? 'Unknown'} (${a.teacher?.name ?? 'Unknown'})`,
    value: a.id,
  }))
);

const openAddModal = (dayId) => {
  if (!props.selectedClass) {
    alert('Pilih kelas terlebih dahulu!');
    return;
  }
  selectedDay.value = dayId;
  form.day_of_week = dayId;
  form.items = [{ teaching_assignment_id: '', start_time: '07:00', end_time: '08:00' }];
  isModalOpen.value = true;
};

const addItem = () => form.items.push({ teaching_assignment_id: '', start_time: '08:00', end_time: '09:00' });
const removeItem = (index) => form.items.splice(index, 1);

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

// --- Calendar State (Month View) ---
const currentDate = ref(new Date());

const monthYear = computed(() =>
  currentDate.value.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })
);

const calendarDays = computed(() => {
  const year = currentDate.value.getFullYear();
  const month = currentDate.value.getMonth();
  const firstDayOfMonth = new Date(year, month, 1);
  const lastDayOfMonth = new Date(year, month + 1, 0);
  const daysInMonth = lastDayOfMonth.getDate();
  let startDay = firstDayOfMonth.getDay();
  if (startDay === 0) startDay = 7;
  const daysArr = [];
  for (let i = 1; i < startDay; i++) daysArr.push({ id: `prev-${i}`, date: '', isPadding: true });
  for (let i = 1; i <= daysInMonth; i++) {
    const date = new Date(year, month, i);
    let dayOfWeek = date.getDay();
    if (dayOfWeek === 0) dayOfWeek = 7;
    daysArr.push({
      id: i,
      date: i,
      fullDate: date,
      day_of_week: dayOfWeek,
      isPadding: false,
      isToday: new Date().toDateString() === date.toDateString(),
      isWeekend: dayOfWeek === 6 || dayOfWeek === 7,
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

const weekHeaders = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
</script>

<template>
  <Head title="Jadwal Pelajaran" />

  <div class="space-y-6">
    <!-- ─── Class Selection View ────────────────────────────────────── -->
    <div v-if="!selectedClass" class="space-y-6">
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-xl font-bold text-slate-800">Jadwal Pelajaran</h2>
          <p class="mt-0.5 text-sm text-slate-400">Pilih kelas untuk mengelola jadwal pelajaran.</p>
        </div>
        <div class="w-full sm:w-72">
          <FormSelect v-model="academicYearId" label="Tahun Ajaran">
            <option v-for="ay in academicYears" :key="ay.id" :value="ay.id">{{ ay.name }}{{ ay.is_active ? ' (Aktif)' : '' }}</option>
          </FormSelect>
        </div>
      </div>

      <div v-if="classes.length === 0" class="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 py-12 text-center">
        <p class="text-sm text-slate-500">Tidak ada kelas untuk tahun ajaran yang dipilih.</p>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <Link
          v-for="cls in classes"
          :key="cls.id"
          :href="route('schedules.index', { class_id: cls.id })"
          class="group block rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:shadow-md hover:border-orange-200"
        >
          <div class="flex items-start justify-between gap-2">
            <h3 class="text-lg font-bold text-slate-800 group-hover:text-orange-600 transition-colors">{{ cls.name }}</h3>
            <span v-if="cls.academic_year?.name" class="shrink-0 inline-flex items-center rounded-md bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-600">
              {{ cls.academic_year.name }}{{ cls.academic_year.is_active ? ' · Aktif' : '' }}
            </span>
          </div>
          <p v-if="cls.homeroom_teacher" class="mt-1 truncate text-xs text-slate-500">Wali: {{ cls.homeroom_teacher.name }}</p>
          <p v-else class="mt-1 text-xs italic text-slate-400">Belum ada Wali Kelas</p>

          <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3">
            <div class="flex flex-col gap-1 text-xs text-slate-500">
              <span class="flex items-center gap-1.5">
                <svg class="h-3.5 w-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                {{ cls.students_count }} Siswa
              </span>
              <span class="flex items-center gap-1.5">
                <svg class="h-3.5 w-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
                {{ cls.teaching_assignments_count ?? 0 }} Mapel
              </span>
            </div>
            <span class="flex h-7 w-7 items-center justify-center rounded-full bg-slate-100 text-slate-400 transition-colors group-hover:bg-orange-50 group-hover:text-orange-600">
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </span>
          </div>
        </Link>
      </div>
    </div>

    <!-- ─── Calendar View ───────────────────────────────────────────── -->
    <div v-else class="space-y-5">
      <!-- Breadcrumb + Header -->
      <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div class="mb-1 flex items-center gap-2 text-sm">
            <Link :href="route('schedules.index')" class="font-medium text-slate-500 hover:text-slate-700 hover:underline">Jadwal Pelajaran</Link>
            <span class="text-slate-300">/</span>
            <span class="font-medium text-slate-900">{{ selectedClass.name }}</span>
          </div>
          <h2 class="text-xl font-bold text-slate-800">Jadwal {{ selectedClass.name }}</h2>
          <p class="mt-0.5 text-sm text-slate-400">Atur jadwal pelajaran per hari dalam seminggu.</p>
        </div>

        <!-- Month navigator -->
        <div class="inline-flex items-stretch overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          <button @click="prevMonth" class="px-3 py-2 text-slate-500 transition-colors hover:bg-slate-50 hover:text-slate-700" title="Bulan sebelumnya">
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
          </button>
          <button @click="goToToday" class="border-x border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50">Hari Ini</button>
          <span class="min-w-[180px] px-4 py-2 text-center text-sm font-semibold capitalize text-slate-800">{{ monthYear }}</span>
          <button @click="nextMonth" class="border-l border-slate-200 px-3 py-2 text-slate-500 transition-colors hover:bg-slate-50 hover:text-slate-700" title="Bulan berikutnya">
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
          </button>
        </div>
      </div>

      <!-- Calendar Grid -->
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <!-- Weekday Headers -->
        <div class="grid grid-cols-7 border-b border-slate-200 bg-slate-50">
          <div
            v-for="(header, idx) in weekHeaders"
            :key="header"
            class="px-2 py-2.5 text-center text-[11px] font-semibold uppercase tracking-wider"
            :class="idx >= 5 ? 'text-orange-500' : 'text-slate-500'"
          >
            {{ header }}
          </div>
        </div>

        <!-- Day Cells -->
        <div class="grid grid-cols-7">
          <div
            v-for="(day, index) in calendarDays"
            :key="index"
            class="group/cell min-h-[180px] border-b border-r border-slate-100 p-2 transition-colors last:border-r-0"
            :class="[
              day.isPadding ? 'bg-slate-50/60' : 'bg-white hover:bg-slate-50/50',
              day.isToday ? 'bg-orange-50/30' : '',
              (index + 1) % 7 === 0 ? 'border-r-0' : '',
            ]"
          >
            <template v-if="!day.isPadding">
              <!-- Date Header -->
              <div class="mb-2 flex items-center justify-between">
                <span
                  class="flex h-6 min-w-[1.5rem] items-center justify-center rounded-full px-1.5 text-xs font-semibold leading-none"
                  :class="day.isToday
                    ? 'bg-orange-600 text-white'
                    : day.isWeekend
                      ? 'text-orange-500'
                      : 'text-slate-700'"
                >
                  {{ day.date }}
                </span>

                <button
                  v-if="canManage"
                  @click="openAddModal(day.day_of_week)"
                  class="flex h-5 w-5 items-center justify-center rounded-full text-slate-400 opacity-0 transition-all hover:bg-orange-100 hover:text-orange-600 group-hover/cell:opacity-100"
                  title="Tambah jadwal pada hari ini"
                >
                  <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
                </button>
              </div>

              <!-- Schedule Cards -->
              <div class="space-y-1.5">
                <div
                  v-for="schedule in (schedules[day.day_of_week] || [])"
                  :key="schedule.id"
                  class="group/card rounded-md border border-slate-200 bg-white p-2 shadow-sm transition-all hover:shadow-md hover:border-orange-200"
                >
                  <div class="flex items-center gap-1 text-[10px] font-semibold text-orange-600">
                    <svg class="h-3 w-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    <span>{{ schedule.start_time.substring(0,5) }} – {{ schedule.end_time.substring(0,5) }}</span>
                  </div>
                  <p
                    class="mt-1 line-clamp-2 text-xs font-semibold leading-tight text-slate-800"
                    :title="schedule.teaching_assignment.subject.name"
                  >
                    {{ schedule.teaching_assignment.subject.name }}
                  </p>
                  <p class="mt-0.5 truncate text-[10px] text-slate-500">{{ schedule.teaching_assignment.teacher.name }}</p>

                  <div
                    v-if="canManage"
                    class="mt-1.5 flex gap-1 border-t border-slate-100 pt-1.5 opacity-0 transition-opacity group-hover/card:opacity-100"
                  >
                    <button
                      @click.stop="openEditModal(schedule)"
                      class="flex flex-1 items-center justify-center gap-1 rounded-md py-0.5 text-[10px] font-medium text-blue-600 transition-colors hover:bg-blue-50"
                      title="Edit jadwal"
                    >
                      <svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                      Edit
                    </button>
                    <button
                      @click.stop="deleteSchedule(schedule)"
                      class="flex flex-1 items-center justify-center gap-1 rounded-md py-0.5 text-[10px] font-medium text-rose-600 transition-colors hover:bg-rose-50"
                      title="Hapus jadwal"
                    >
                      <svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                      Hapus
                    </button>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    </div>

    <!-- ─── Add/Edit Modal ──────────────────────────────────────────── -->
    <Modal :show="isModalOpen" @close="closeModal">
      <div class="p-6">
        <div class="mb-5">
          <h2 class="text-lg font-bold text-slate-800">
            {{ isEditMode ? `Edit Jadwal — ${selectedClass?.name}` : `Tambah Jadwal ${days.find(d => d.id === selectedDay)?.name} — ${selectedClass?.name}` }}
          </h2>
          <p class="mt-0.5 text-xs text-slate-500">
            {{ isEditMode ? 'Perbarui mapel atau jam pelajaran ini.' : 'Tambahkan satu atau beberapa sesi mapel sekaligus.' }}
          </p>
        </div>

        <!-- EDIT FORM -->
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
          <div class="mt-6 flex justify-end gap-3 border-t border-slate-100 pt-4">
            <Button variant="outline" @click="closeModal">Batal</Button>
            <Button type="submit" :loading="editForm.processing">Simpan Perubahan</Button>
          </div>
        </form>

        <!-- ADD FORM -->
        <form v-else @submit.prevent="submit" class="space-y-4">
          <div class="max-h-[60vh] space-y-4 overflow-y-auto pr-2">
            <div
              v-for="(item, index) in form.items"
              :key="index"
              class="relative flex items-start gap-3 border-b border-slate-100 pb-4 last:border-0 last:pb-0"
            >
              <span class="pt-3 font-mono text-xs font-semibold text-slate-400">#{{ index + 1 }}</span>
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
                    <div class="mb-1 flex items-center gap-2 font-semibold">
                      <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                      Belum ada mapel
                    </div>
                    <p class="mb-3 text-xs">Tidak ada mata pelajaran yang ditugaskan ke guru untuk kelas ini. Atur penugasan dulu sebelum membuat jadwal.</p>
                    <a
                      :href="`/teaching-assignments?class_id=${props.filters.class_id}`"
                      class="inline-flex items-center gap-1 rounded-md bg-amber-100 px-3 py-1.5 text-xs font-medium text-amber-900 transition-colors hover:bg-amber-200"
                    >
                      Atur Penugasan Guru
                      <svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                    </a>
                  </div>
                </template>

                <div v-if="assignmentOptions.length > 0" class="grid grid-cols-2 gap-3">
                  <FormInput label="Mulai" type="time" v-model="item.start_time" :error="form.errors[`items.${index}.start_time`]" />
                  <FormInput label="Selesai" type="time" v-model="item.end_time" :error="form.errors[`items.${index}.end_time`]" />
                </div>
              </div>
              <button
                v-if="form.items.length > 1"
                type="button"
                @click="removeItem(index)"
                class="mt-8 text-slate-400 transition-colors hover:text-rose-500"
                title="Hapus baris"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
              </button>
            </div>
          </div>

          <div v-if="assignmentOptions.length > 0" class="border-t border-slate-100 pt-2">
            <button
              type="button"
              @click="addItem"
              class="inline-flex items-center gap-1 text-sm font-medium text-orange-600 transition-colors hover:text-orange-700 hover:underline"
            >
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
              Tambah Mapel Lain
            </button>
          </div>

          <div class="mt-6 flex justify-end gap-3 border-t border-slate-100 pt-4">
            <Button variant="outline" @click="closeModal">Batal</Button>
            <Button type="submit" :loading="form.processing" :disabled="assignmentOptions.length === 0">Simpan Semua</Button>
          </div>
        </form>
      </div>
    </Modal>
  </div>
</template>
