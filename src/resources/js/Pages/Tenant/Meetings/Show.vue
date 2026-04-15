<script setup>
import { Head, Link, useForm, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Badge from '@/Components/UI/Badge.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  course: Object,
  meeting: Object,
  is_teacher: Boolean,
  is_student: Boolean,
});

// ---- HELPERS ----
const getMeetingLabel = (meetingNumber) => {
  if (meetingNumber === 15) return 'UTS';
  if (meetingNumber === 16) return 'UAS';
  return `Pertemuan ${meetingNumber}`;
};

const getFileIcon = (fileName) => {
  if (!fileName) return '📄';
  const ext = fileName.split('.').pop()?.toLowerCase();
  if (['pdf'].includes(ext)) return '📕';
  if (['doc', 'docx'].includes(ext)) return '📘';
  if (['xls', 'xlsx'].includes(ext)) return '📗';
  if (['ppt', 'pptx'].includes(ext)) return '📙';
  if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext)) return '🖼️';
  if (['mp4', 'avi', 'mov'].includes(ext)) return '🎬';
  if (['zip', 'rar', '7z'].includes(ext)) return '📦';
  return '📄';
};

const formatBytes = (bytes) => {
  if (!bytes) return '';
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / 1048576).toFixed(1) + ' MB';
};

// Combine materials and assignments into a single timeline/list
// Sorting logic: materials first (by sort_order), then assignments
const activities = computed(() => {
  let list = [];
  if (props.meeting.materials) {
    props.meeting.materials.forEach(m => {
      list.push({ ...m, itemType: 'material' });
    });
  }
  if (props.meeting.assignments) {
    props.meeting.assignments.forEach(a => {
      list.push({ ...a, itemType: 'assignment' });
    });
  }
  return list;
});

// ---- ADD MATERIAL MODAL ----
const showMaterialModal = ref(false);
const materialForm = useForm({
  title: '',
  type: 'file',
  content: '',
  url: '',
  file: null,
});

const openMaterialModal = () => {
  showMaterialModal.value = true;
  materialForm.reset();
};

const closeMaterialModal = () => {
  showMaterialModal.value = false;
  materialForm.reset();
};

const submitMaterial = () => {
  materialForm.post(`/tenant/meetings/${props.meeting.id}/materials`, {
    preserveScroll: true,
    forceFormData: true,
    onSuccess: () => closeMaterialModal(),
  });
};

const deleteMaterial = (materialId) => {
  if (!confirm('Hapus materi ini?')) return;
  router.delete(`/tenant/materials/${materialId}`, { preserveScroll: true });
};
</script>

<template>
  <Head :title="`${getMeetingLabel(meeting.meeting_number)} - ${course.subject?.name}`" />

  <div class="max-w-5xl mx-auto space-y-6">
    <!-- Breadcrumbs -->
    <nav class="flex text-xs text-slate-400">
      <Link href="/dashboard" class="hover:text-blue-600 transition-colors">Dashboard</Link>
      <span class="mx-1.5">/</span>
      <Link href="/courses" class="hover:text-blue-600 transition-colors">Courses</Link>
      <span class="mx-1.5">/</span>
      <Link :href="`/courses/${course.id}`" class="hover:text-blue-600 transition-colors">{{ course.subject?.name }}</Link>
      <span class="mx-1.5">/</span>
      <span class="text-slate-600 font-medium">{{ getMeetingLabel(meeting.meeting_number) }}. {{ meeting.title }}</span>
    </nav>

    <!-- Meeting Banner Header (Referencing provided UI) -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <!-- Banner Image Area -->
      <div class="relative h-48 sm:h-64 bg-slate-800 overflow-hidden flex items-center justify-center">
        <!-- Background Pattern -->
        <div class="absolute inset-0 bg-[#74b9ff] opacity-80 bg-[radial-gradient(#ffffff_1px,transparent_1px)] [background-size:20px_20px]"></div>
        
        <!-- Center Ribbon Banner Graphic -->
        <div class="relative z-10 w-full text-center px-4">
          <div class="inline-block px-8 py-3 bg-white/10 backdrop-blur-md rounded-2xl border border-white/20 shadow-lg transform -skew-x-6">
            <h1 class="text-3xl sm:text-5xl font-black text-white italic truncate tracking-tight uppercase" style="text-shadow: 2px 2px 0px rgba(0,0,0,0.2);">
              {{ meeting.title }}
            </h1>
          </div>
        </div>

        <!-- Completion Progress overlay right top -->
        <div v-if="is_student" class="absolute top-4 right-4 bg-white/90 backdrop-blur rounded-lg px-3 py-1.5 flex items-center gap-2 shadow-sm">
          <svg class="w-4 h-4 text-emerald-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>
          <span class="text-xs font-bold text-slate-700">0 / {{ activities.length }} Selesai</span>
        </div>
      </div>

      <!-- Detail Area -->
      <div class="p-6 sm:p-8">
        <h2 class="text-xl font-bold text-slate-800 mb-2">
          {{ getMeetingLabel(meeting.meeting_number) }}: {{ meeting.title }}
        </h2>
        
        <p class="text-slate-600 leading-relaxed text-sm">
          {{ meeting.description || 'Tidak ada deskripsi untuk pertemuan ini.' }}
        </p>

        <div class="mt-6 flex flex-wrap gap-4 text-xs font-medium text-slate-500">
          <div class="flex items-center gap-1.5">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
            {{ meeting.materials?.length || 0 }} Materi
          </div>
          <div class="flex items-center gap-1.5">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
            {{ meeting.assignments?.length || 0 }} Tugas
          </div>
        </div>

        <div v-if="is_teacher" class="mt-6 flex flex-wrap gap-3 border-t border-slate-100 pt-6">
          <Button @click="openMaterialModal" variant="secondary" size="sm" class="flex items-center gap-1.5">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            Tambah Materi
          </Button>
          <Link :href="`/assignments/create?meeting_id=${meeting.id}`" class="px-3 py-1.5 text-xs font-semibold rounded-lg bg-orange-50 text-orange-600 hover:bg-orange-100 transition-colors flex items-center gap-1.5">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            Buat Tugas Baru
          </Link>
        </div>
      </div>
    </div>

    <!-- Activities List (Flat Style with Checkboxes) -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <div class="bg-slate-50 border-b border-slate-200 px-6 py-4 flex items-center justify-between">
        <h3 class="font-bold text-slate-700">Daftar Kegiatan</h3>
      </div>
      
      <div v-if="activities.length > 0" class="divide-y divide-slate-100">
        <div v-for="activity in activities" :key="`${activity.itemType}-${activity.id}`" 
             class="group flex items-center gap-4 px-6 py-4 hover:bg-slate-50/50 transition-colors relative">
          
          <!-- Checkbox Status -->
          <div class="flex-shrink-0 pt-0.5">
            <div class="w-5 h-5 rounded border-2 border-slate-300 flex items-center justify-center bg-white group-hover:border-slate-400 transition-colors cursor-help group-hover:bg-slate-50">
               <!-- Future Checkmark Logic Here -->
               <!-- <svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg> -->
            </div>
          </div>

          <!-- Icon & Info -->
          <div class="flex items-start gap-4 flex-1 min-w-0">
            <!-- Type Icon -->
            <div class="flex-shrink-0 w-8 h-8 flex items-center justify-center text-xl bg-slate-100 rounded-lg">
              <template v-if="activity.itemType === 'material'">
                <template v-if="activity.type === 'link'">🔗</template>
                <template v-else-if="activity.type === 'text'">📝</template>
                <template v-else>{{ getFileIcon(activity.file_name) }}</template>
              </template>
              <template v-else>
                <span v-if="activity.type === 'quiz'">🧠</span>
                <span v-else>📝</span>
              </template>
            </div>

            <!-- Title & Meta -->
            <div class="flex-1 min-w-0 pt-0.5">
              <a href="#" class="font-semibold text-blue-600 hover:text-blue-800 hover:underline transition-colors block truncate text-sm">
                {{ activity.itemType === 'material' ? (activity.type === 'file' ? '[File] ' : activity.type === 'link' ? '[Link] ' : '[Teks] ') : (activity.type === 'quiz' ? '[Quiz] ' : '[Tugas] ') }} 
                {{ activity.title }}
              </a>
              <div class="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-500">
                <!-- Material Meta -->
                <template v-if="activity.itemType === 'material'">
                  <span v-if="activity.type === 'file'">{{ formatBytes(activity.file_size) }}</span>
                  <span v-if="activity.type === 'link'" class="truncate max-w-[200px]">{{ activity.url }}</span>
                </template>
                <!-- Assignment Meta -->
                <template v-else>
                  <span v-if="activity.due_date" class="text-rose-500 font-medium opacity-80">
                    Deadline: {{ new Date(activity.due_date).toLocaleDateString('id-ID') }}
                  </span>
                  <Badge v-if="is_student && activity.student_submission?.grade" variant="success" class="text-[10px]">Nilai: {{ activity.student_submission.grade }}</Badge>
                  <Badge v-else-if="is_student && activity.student_submission" variant="info" class="text-[10px]">Dikirim</Badge>
                </template>
              </div>

              <!-- Inline Text Material Display -->
              <div v-if="activity.itemType === 'material' && activity.type === 'text' && activity.content" 
                   class="mt-3 text-sm text-slate-600 bg-white border border-slate-200 rounded-lg p-3 whitespace-pre-wrap shadow-sm">
                {{ activity.content }}
              </div>
            </div>
          </div>
          
          <!-- Actions (Download, Delete) -->
          <div class="flex items-center gap-2 flex-shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
            <template v-if="activity.itemType === 'material'">
              <a v-if="activity.type === 'file'" :href="`/storage/${activity.file_path}`" target="_blank" class="p-2 bg-white border border-slate-200 rounded-lg hover:bg-blue-50 hover:text-blue-600 hover:border-blue-200 transition-all text-slate-400 shadow-sm" title="Download">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
              </a>
              <a v-if="activity.type === 'link'" :href="activity.url" target="_blank" class="p-2 bg-white border border-slate-200 rounded-lg hover:bg-blue-50 hover:text-blue-600 hover:border-blue-200 transition-all text-slate-400 shadow-sm" title="Buka Link">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
              </a>
              <button v-if="is_teacher" @click="deleteMaterial(activity.id)" class="p-2 bg-white border border-slate-200 rounded-lg hover:bg-red-50 hover:text-red-500 hover:border-red-200 transition-all text-slate-400 shadow-sm" title="Hapus">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
              </button>
            </template>
            <template v-else>
               <Link :href="`/assignments/${activity.id}`" class="p-2 bg-white border border-slate-200 rounded-lg hover:bg-blue-50 hover:text-blue-600 hover:border-blue-200 transition-all text-slate-400 font-medium text-xs shadow-sm">
                 Buka Tugas
               </Link>
            </template>
          </div>
          
        </div>
      </div>
      
      <!-- Empty State -->
      <div v-else class="p-10 text-center flex flex-col items-center justify-center">
        <div class="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mb-3">
          <svg class="w-8 h-8 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 002-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
        </div>
        <h4 class="text-sm font-bold text-slate-700">Belum Ada Kegiatan</h4>
        <p class="text-xs text-slate-400 mt-1 max-w-sm">Daftar materi, slide, video, dan tugas akan muncul di sini.</p>
      </div>
    </div>
  </div>

  <!-- ADD MATERIAL MODAL -->
  <Teleport to="body">
    <div v-if="showMaterialModal" class="fixed inset-0 z-50 flex items-center justify-center">
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
