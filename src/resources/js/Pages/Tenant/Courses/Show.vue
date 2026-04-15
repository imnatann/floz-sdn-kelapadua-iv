<script setup>
import { ref, reactive, computed } from 'vue';
import { Head, Link, router, useForm } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Badge from '@/Components/UI/Badge.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  course: Object,
  meetings: Array,
  is_teacher: Boolean,
  is_student: Boolean,
});

// ---- MEETING EDIT STATE (teacher) ----
const editingMeetingId = ref(null);
const editForm = reactive({ title: '', description: '' });

const startEditMeeting = (meeting) => {
  editingMeetingId.value = meeting.id;
  editForm.title = meeting.title;
  editForm.description = meeting.description || '';
};

const cancelEditMeeting = () => { editingMeetingId.value = null; };

const saveEditMeeting = (meeting) => {
  router.put(`/tenant/meetings/${meeting.id}`, {
    title: editForm.title,
    description: editForm.description,
  }, { 
    preserveScroll: true,
    onSuccess: () => { editingMeetingId.value = null; },
  });
};

// ---- LOCK/UNLOCK ----
const toggleLock = (meeting) => {
  router.put(`/tenant/meetings/${meeting.id}`, {
    is_locked: !meeting.is_locked,
  }, { preserveScroll: true });
};

// ---- ADD MATERIAL MODAL ----
const showMaterialModal = ref(false);
const activeMeetingId = ref(null);
const materialForm = useForm({
  title: '',
  type: 'file',
  content: '',
  url: '',
  file: null,
});

const openMaterialModal = (meeting) => {
  activeMeetingId.value = meeting.id;
  showMaterialModal.value = true;
  materialForm.reset();
};

const closeMaterialModal = () => {
  showMaterialModal.value = false;
  activeMeetingId.value = null;
  materialForm.reset();
};

const submitMaterial = () => {
  materialForm.post(`/tenant/meetings/${activeMeetingId.value}/materials`, {
    preserveScroll: true,
    forceFormData: true,
    onSuccess: () => closeMaterialModal(),
  });
};

// ---- HELPERS ----
const getMeetingLabel = (meeting) => {
  if (meeting.meeting_number === 15) return 'UTS';
  if (meeting.meeting_number === 16) return 'UAS';
  return `P${meeting.meeting_number}`;
};

const getMeetingColor = (meeting) => {
  if (meeting.meeting_number === 15) return 'bg-orange-700'; 
  if (meeting.meeting_number === 16) return 'bg-red-500'; 
  return 'bg-orange-500';
};

const visibleMeetings = computed(() => {
  if (props.is_teacher) return props.meetings;
  return props.meetings;
});
</script>

<template>
  <Head :title="course.subject?.name" />

  <div class="space-y-6">
    <!-- Header -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <div class="h-2 bg-gradient-to-r from-orange-500 to-orange-600"></div>
      <div class="p-6">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <nav class="flex text-xs text-slate-400 mb-2">
              <Link href="/courses" class="hover:text-orange-600">Kursus</Link>
              <span class="mx-1.5">/</span>
              <span class="text-slate-600">{{ course.subject?.name }}</span>
            </nav>
            <h1 class="text-2xl font-bold text-slate-800">{{ course.subject?.name }}</h1>
            <div class="flex flex-wrap items-center gap-3 mt-2">
              <Badge variant="info">{{ course.school_class?.name }}</Badge>
              <span class="text-sm text-slate-500">{{ course.teacher?.name }}</span>
              <span class="text-xs text-slate-400">{{ course.academic_year?.name }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Meetings Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
      <div
        v-for="meeting in visibleMeetings"
        :key="meeting.id"
        class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden transition-all duration-200 flex flex-col group relative"
        :class="(is_student && meeting.is_locked) ? 'opacity-60 grayscale-[50%]' : 'hover:shadow-md hover:border-orange-300'"
      >
        <!-- Card Header Banner -->
        <div class="h-16 flex items-center px-4 relative overflow-hidden" :class="getMeetingColor(meeting)">
          <!-- Abstract Background Pattern (just a subtle overlay) -->
          <div class="absolute inset-0 opacity-10 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGNpcmNsZSBjeD0iMiIgY3k9IjIiIHI9IjIiIGZpbGw9IiNmZmYiLz48L3N2Zz4=')]"></div>
          
          <h3 class="text-white font-bold text-lg relative z-10 tracking-widest">{{ getMeetingLabel(meeting) }}</h3>
          
          <!-- Teacher Quick Actions (overlay on top right) -->
          <div v-if="is_teacher" class="absolute top-2 right-2 flex items-center gap-1 z-20">
            <button @click.prevent="toggleLock(meeting)" class="p-1.5 rounded-lg bg-white/20 hover:bg-white/40 text-white backdrop-blur-sm transition-colors" :title="meeting.is_locked ? 'Buka kunci' : 'Kunci'">
              <svg v-if="meeting.is_locked" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>
              <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z"></path></svg>
            </button>
            <button v-if="editingMeetingId !== meeting.id" @click.prevent="startEditMeeting(meeting)" class="p-1.5 rounded-lg bg-white/20 hover:bg-white/40 text-white backdrop-blur-sm transition-colors" title="Edit">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
            </button>
          </div>
        </div>

        <!-- Card Body -->
        <div class="p-4 flex-1 flex flex-col relative z-10">
          <!-- Inline Edit Mode -->
          <div v-if="editingMeetingId === meeting.id" class="space-y-3 mb-4">
            <div>
              <label class="text-xs font-medium text-slate-500 mb-1 block">Judul</label>
              <input v-model="editForm.title" class="text-sm font-semibold border border-orange-300 rounded-lg px-3 py-1.5 w-full focus:ring-1 focus:ring-orange-400 outline-none" />
            </div>
            <div>
              <label class="text-xs font-medium text-slate-500 mb-1 block">Deskripsi</label>
              <textarea v-model="editForm.description" rows="2" class="w-full text-sm border border-orange-200 rounded-lg px-3 py-2 focus:ring-1 focus:ring-orange-400 outline-none resize-none" placeholder="Deskripsi..."></textarea>
            </div>
            <div class="flex gap-2">
              <button @click="saveEditMeeting(meeting)" class="flex-1 py-1.5 bg-emerald-50 text-emerald-600 rounded-lg text-xs font-semibold hover:bg-emerald-100 transition-colors">Simpan</button>
              <button @click="cancelEditMeeting()" class="flex-1 py-1.5 bg-red-50 text-red-500 rounded-lg text-xs font-semibold hover:bg-red-100 transition-colors">Batal</button>
            </div>
          </div>
          
          <!-- Normal Display Mode -->
          <div v-else class="flex-1 flex flex-col">
            <h4 class="font-bold text-slate-800 line-clamp-2 mb-1 group-hover:text-orange-600 transition-colors flex items-center gap-2">
              {{ meeting.title }}
              <svg v-if="meeting.is_locked && is_student" class="w-4 h-4 text-slate-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>
            </h4>
            <p v-if="meeting.description" class="text-xs text-slate-500 line-clamp-2 mb-3">{{ meeting.description }}</p>
            <p v-else class="text-xs text-slate-400 italic mb-3">Tidak ada deskripsi</p>
            
            <div class="mt-auto pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500 font-medium relative z-20">
              <div class="flex items-center gap-4 pointer-events-none">
                <div class="flex items-center gap-1.5">
                  <span class="w-5 h-5 flex items-center justify-center rounded-md bg-blue-50 text-blue-500">
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                  </span>
                  <span>{{ meeting.materials?.length || 0 }}</span>
                </div>
                <div class="flex items-center gap-1.5">
                  <span class="w-5 h-5 flex items-center justify-center rounded-md bg-orange-50 text-orange-500">
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
                  </span>
                  <span>{{ meeting.assignments?.length || 0 }}</span>
                </div>
              </div>
              
              <div v-if="is_teacher && editingMeetingId !== meeting.id" class="flex items-center gap-1">
                <button @click.prevent="openMaterialModal(meeting)" class="p-1.5 rounded-md hover:bg-blue-50 text-slate-400 hover:text-blue-600 transition-colors" title="Tambah Materi">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                </button>
                <Link :href="`/assignments/create?meeting_id=${meeting.id}`" class="p-1.5 rounded-md hover:bg-orange-50 text-slate-400 hover:text-orange-600 transition-colors" title="Buat Tugas">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
                  <span class="absolute -top-1 -right-1 flex h-3 w-3"><span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75"></span><span class="relative inline-flex rounded-full h-3 w-3 bg-orange-500 flex items-center justify-center text-[8px] text-white">+</span></span>
                </Link>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Link Overlay (Make entire card clickable unless editing) -->
        <Link 
          v-if="editingMeetingId !== meeting.id && !(is_student && meeting.is_locked)"
          :href="`/courses/${course.id}/meetings/${meeting.id}`"
          class="absolute inset-0 z-0"
        ></Link>
      </div>
    </div>
  </div>

  <!-- ADD MATERIAL MODAL -->
  <Teleport to="body">
    <div v-if="showMaterialModal" class="fixed inset-0 z-[100] flex items-center justify-center">
      <div class="fixed inset-0 bg-black/40 backdrop-blur-sm" @click="closeMaterialModal"></div>
      <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden">
        <div class="p-6 border-b border-slate-100">
          <h3 class="text-lg font-bold text-slate-800">Tambah Materi</h3>
          <p class="text-xs text-slate-400 mt-1">Tambahkan file, link, atau catatan teks</p>
        </div>
        <form @submit.prevent="submitMaterial" class="p-6 space-y-4">
          <!-- Form fields (Title, Type, File/URL/Text) -->
          <div>
            <label class="text-sm font-semibold text-slate-700 mb-1 block">Judul Materi *</label>
            <input v-model="materialForm.title" type="text" class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:border-blue-400 focus:ring-1 focus:ring-blue-400 outline-none" placeholder="e.g. Slide Presentasi BAB 1" required />
            <div v-if="materialForm.errors.title" class="text-red-500 text-xs mt-1">{{ materialForm.errors.title }}</div>
          </div>

          <div>
            <label class="text-sm font-semibold text-slate-700 mb-2 block">Jenis Materi</label>
            <div class="grid grid-cols-3 gap-2">
              <button type="button" @click="materialForm.type = 'file'" class="py-2.5 rounded-lg border-2 text-sm font-medium transition-all text-center" :class="materialForm.type === 'file' ? 'border-blue-500 bg-blue-50 text-blue-700' : 'border-slate-200 text-slate-500 hover:border-blue-200'">📄 File</button>
              <button type="button" @click="materialForm.type = 'link'" class="py-2.5 rounded-lg border-2 text-sm font-medium transition-all text-center" :class="materialForm.type === 'link' ? 'border-blue-500 bg-blue-50 text-blue-700' : 'border-slate-200 text-slate-500 hover:border-blue-200'">🔗 Link</button>
              <button type="button" @click="materialForm.type = 'text'" class="py-2.5 rounded-lg border-2 text-sm font-medium transition-all text-center" :class="materialForm.type === 'text' ? 'border-blue-500 bg-blue-50 text-blue-700' : 'border-slate-200 text-slate-500 hover:border-blue-200'">📝 Teks</button>
            </div>
          </div>

          <div v-if="materialForm.type === 'file'">
            <label class="flex flex-col items-center justify-center w-full h-24 border-2 border-dashed border-slate-200 rounded-xl cursor-pointer bg-slate-50/50 hover:bg-blue-50/50 hover:border-blue-300 transition-all">
              <svg v-if="!materialForm.file" class="w-6 h-6 text-slate-300 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path></svg>
              <p class="text-xs text-slate-400"><span class="font-semibold">Klik untuk pilih file</span></p>
              <p v-if="materialForm.file" class="text-xs text-blue-600 font-medium mt-1">{{ materialForm.file.name }}</p>
              <input type="file" class="hidden" @change="materialForm.file = $event.target.files[0]" />
            </label>
            <div v-if="materialForm.errors.file" class="text-red-500 text-xs mt-1">{{ materialForm.errors.file }}</div>
          </div>

          <div v-if="materialForm.type === 'link'">
            <input v-model="materialForm.url" type="url" class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:border-blue-400" placeholder="https://..." />
            <div v-if="materialForm.errors.url" class="text-red-500 text-xs mt-1">{{ materialForm.errors.url }}</div>
          </div>

          <div v-if="materialForm.type === 'text'">
            <textarea v-model="materialForm.content" rows="4" class="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:border-blue-400 resize-y" placeholder="Tulis catatan materi..."></textarea>
            <div v-if="materialForm.errors.content" class="text-red-500 text-xs mt-1">{{ materialForm.errors.content }}</div>
          </div>

          <div class="flex justify-end gap-3 pt-2">
            <button type="button" @click="closeMaterialModal" class="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800 transition-colors">Batal</button>
            <Button type="submit" :disabled="materialForm.processing" variant="primary" class="px-6">Simpan</Button>
          </div>
        </form>
      </div>
    </div>
  </Teleport>
</template>
