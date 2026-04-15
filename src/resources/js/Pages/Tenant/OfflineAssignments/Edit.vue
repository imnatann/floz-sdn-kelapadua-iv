<script setup>
import { useForm, Head, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormInput from '@/Components/UI/FormInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import FormTextarea from '@/Components/UI/FormTextarea.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  assignment: Object,
  subjects: Array,
  classes: Array,
});

const form = useForm({
  subject_id: props.assignment.subject_id,
  classes: props.assignment.classes.map(c => c.id),
  title: props.assignment.title,
  description: props.assignment.description || '',
  due_date: props.assignment.due_date ? new Date(props.assignment.due_date).toISOString().slice(0, 16) : '',
  status: props.assignment.status,
  file: null,
  _method: 'put',
});

const toggleClass = (classId) => {
  const index = form.classes.indexOf(classId);
  if (index === -1) form.classes.push(classId);
  else form.classes.splice(index, 1);
};

const submit = () => {
    form.post(`/tenant/offline-assignments/${props.assignment.id}`);
};
</script>

<template>
  <Head title="Edit Data Tugas" />

  <div class="max-w-4xl mx-auto space-y-6 pb-24">
    <!-- Header -->
    <div class="flex items-center gap-4">
        <Link href="/offline-assignments" class="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-500">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
        </Link>
        <div>
            <h1 class="text-xl font-bold text-slate-900">Edit Data Tugas</h1>
            <p class="text-sm text-slate-500">Perbarui informasi tugas</p>
        </div>
    </div>

    <form @submit.prevent="submit" class="space-y-6">
        <!-- Card 1: Informasi Dasar -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
                 <div class="flex items-center gap-3">
                     <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-100 text-sm">📝</div>
                     <div>
                         <h3 class="text-sm font-semibold text-slate-700">Informasi Tugas</h3>
                         <p class="text-xs text-slate-400">Detail utama mengenai tugas yang diberikan</p>
                     </div>
                </div>
            </div>

            <div class="p-6 space-y-4">
                <FormInput 
                    v-model="form.title" 
                    label="Judul Tugas" 
                    placeholder="Contoh: Latihan Soal Bab 1" 
                    :required="true" 
                    :error="form.errors.title" 
                />

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <FormSelect 
                        v-model="form.subject_id" 
                        label="Mata Pelajaran" 
                        :required="true" 
                        :error="form.errors.subject_id"
                    >
                        <option value="">- Pilih Mapel -</option>
                        <option v-for="s in subjects" :key="s.id" :value="s.id">{{ s.name }}</option>
                    </FormSelect>

                    <FormSelect 
                        v-model="form.status" 
                        label="Status" 
                        :required="true" 
                        :error="form.errors.status"
                    >
                        <option value="active">Aktif</option>
                        <option value="inactive">Tidak Aktif</option>
                    </FormSelect>
                </div>

                <FormTextarea
                    v-model="form.description"
                    label="Deskripsi / Petunjuk"
                    rows="4"
                    placeholder="Tuliskan deskripsi atau petunjuk pengerjaan tugas..."
                    :required="true"
                    :error="form.errors.description"
                />
            </div>
        </div>

        <!-- Card 2: Pengaturan Kelas & Dokumen -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
             <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
                 <div class="flex items-center gap-3">
                     <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-orange-100 text-sm">📚</div>
                     <div>
                         <h3 class="text-sm font-semibold text-slate-700">Kelas & Dokumen</h3>
                         <p class="text-xs text-slate-400">Target kelas dan file lampiran</p>
                     </div>
                </div>
            </div>

            <div class="p-6 space-y-6">
                <!-- Kelas Selection -->
                <div>
                    <label class="block text-xs font-medium text-slate-600 mb-2">
                        Pilih Kelas Target <span class="text-orange-500">*</span>
                    </label>
                    <div class="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-5 gap-3 max-h-48 overflow-y-auto p-1">
                        <div 
                            v-for="cls in classes" 
                            :key="cls.id" 
                            @click="toggleClass(cls.id)"
                            class="cursor-pointer border rounded-lg px-3 py-2 text-sm text-center transition-all duration-200 select-none flex items-center justify-center gap-2"
                            :class="form.classes.includes(cls.id) 
                                ? 'border-emerald-500 bg-emerald-50 text-emerald-700 font-semibold shadow-sm ring-1 ring-emerald-500' 
                                : 'border-slate-200 text-slate-600 hover:border-emerald-300 hover:bg-slate-50'"
                        >
                            <span>{{ cls.name }}</span>
                            <svg v-if="form.classes.includes(cls.id)" class="w-4 h-4 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                        </div>
                    </div>
                    <div v-if="form.errors.classes" class="text-red-500 text-xs mt-1">{{ form.errors.classes }}</div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <!-- Due Date -->
                     <FormInput
                       type="datetime-local"
                       v-model="form.due_date"
                       label="Batas Pengumpulan"
                       :required="true"
                       :error="form.errors.due_date"
                     />

                    <!-- File Upload -->
                    <div>
                        <label class="block text-xs font-medium text-slate-600 mb-2">
                            Lampiran File (Opsional)
                        </label>
                        <div class="relative">
                            <input 
                              type="file" 
                              @input="form.file = $event.target.files[0]"
                              class="block w-full text-sm text-slate-500
                                file:mr-4 file:py-2.5 file:px-4
                                file:rounded-lg file:border-0
                                file:text-sm file:font-semibold
                                file:bg-emerald-50 file:text-emerald-700
                                hover:file:bg-emerald-100
                                cursor-pointer border border-slate-200 rounded-lg"
                              accept=".doc,.docx,.xls,.xlsx,.ppt,.pptx,.pdf,.jpg,.jpeg,.png"
                            />
                             <div v-if="form.errors.file" class="text-red-500 text-xs mt-1">{{ form.errors.file }}</div>
                        </div>
                         <p v-if="assignment.files.length > 0" class="text-xs text-blue-600 mt-2">
                            File saat ini: {{ assignment.files[0].file_name }}
                        </p>
                        <p class="text-[10px] text-slate-400 mt-1">Format: PDF, Office, Gambar. Max 100MB.</p>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- Floating Footer -->
    <div class="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 p-4 shadow-lg z-10 md:pl-64">
        <div class="max-w-4xl mx-auto flex justify-end gap-3">
             <Link href="/offline-assignments">
                <Button variant="ghost">Batal</Button>
             </Link>
             <Button variant="primary" :disabled="form.processing" @click="submit">
                 {{ form.processing ? 'Menyimpan...' : 'Simpan Perubahan' }}
             </Button>
        </div>
    </div>
  </div>
</template>
