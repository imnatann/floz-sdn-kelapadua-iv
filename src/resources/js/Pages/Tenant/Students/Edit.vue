<script setup>
import { useForm, Head } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormInput from '@/Components/UI/FormInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import FormTextarea from '@/Components/UI/FormTextarea.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({ student: Object, classes: Array });

const form = useForm({
  nis: props.student.nis, nisn: props.student.nisn || '', name: props.student.name,
  gender: props.student.gender || '', birth_place: props.student.birth_place || '',
  birth_date: props.student.birth_date || '', religion: props.student.religion || '',
  address: props.student.address || '', parent_name: props.student.parent_name || '',
  parent_phone: props.student.parent_phone || '', email: props.student.email || '',
  class_id: props.student.class_id || '', status: props.student.status,
  update_account: false,
});

const submit = () => form.put(`/tenant/students/${props.student.id}`);

import { router, usePage } from '@inertiajs/vue3';
const permissions = usePage().props.auth.permissions;

const deleteStudent = () => {
    if (confirm('Apakah Anda yakin ingin menghapus siswa ini? Semua data terkait (nilai, absensi) akan ikut terhapus dan tidak dapat dikembalikan.')) {
        router.delete(`/students/${props.student.id}`);
    }
};
</script>

<template>
  <Head :title="`Edit ${student.name}`" />
  <div class="mx-auto max-w-3xl space-y-6">
    <!-- Header -->
    <div class="flex items-center gap-4">
      <Button :href="`/students/${student.id}`" variant="outline" size="sm">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        Kembali
      </Button>
      <div>
        <h2 class="text-xl font-bold text-slate-800">Edit {{ student.name }}</h2>
        <p class="mt-0.5 text-sm text-slate-400">NIS: {{ student.nis }}</p>
      </div>
    </div>

    <form @submit.prevent="submit" class="space-y-6">
      <!-- Section 1: Data Pribadi -->
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
          <div class="flex items-center gap-3">
            <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-100 text-sm">👤</div>
            <div>
              <h3 class="text-sm font-semibold text-slate-700">Data Pribadi</h3>
              <p class="text-xs text-slate-400">Informasi identitas siswa</p>
            </div>
          </div>
        </div>
        <div class="space-y-4 p-6">
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormInput v-model="form.nis" label="NIS" :required="true" :error="form.errors.nis" />
            <FormInput v-model="form.nisn" label="NISN" hint="Opsional" :error="form.errors.nisn" />
          </div>
          <FormInput v-model="form.name" label="Nama Lengkap" :required="true" :error="form.errors.name" />
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormSelect v-model="form.gender" label="Jenis Kelamin">
              <option value="">— Pilih —</option>
              <option value="male">Laki-laki</option>
              <option value="female">Perempuan</option>
            </FormSelect>
            <FormSelect v-model="form.religion" label="Agama">
              <option value="">— Pilih —</option>
              <option v-for="r in ['Islam','Kristen','Katolik','Hindu','Buddha','Konghucu']" :key="r" :value="r">{{ r }}</option>
            </FormSelect>
          </div>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormInput v-model="form.birth_place" label="Tempat Lahir" />
            <FormInput v-model="form.birth_date" label="Tanggal Lahir" type="date" />
          </div>
          <FormTextarea v-model="form.address" label="Alamat" :rows="2" />
        </div>
      </div>

      <!-- Section 2: Kelas & Status -->
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
          <div class="flex items-center gap-3">
            <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-100 text-sm">🏫</div>
            <div>
              <h3 class="text-sm font-semibold text-slate-700">Kelas, Status & Orang Tua</h3>
              <p class="text-xs text-slate-400">Penempatan dan kontak wali</p>
            </div>
          </div>
        </div>
        <div class="space-y-4 p-6">
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormSelect v-model="form.class_id" label="Kelas">
              <option value="">— Belum Ditempatkan —</option>
              <option v-for="c in classes" :key="c.id" :value="c.id">{{ c.name }}</option>
            </FormSelect>
            <FormSelect v-model="form.status" label="Status" :required="true">
              <option value="active">Aktif</option>
              <option value="graduated">Lulus</option>
              <option value="transferred">Pindah</option>
              <option value="dropout">Putus Sekolah</option>
            </FormSelect>
          </div>
          <FormInput v-model="form.email" label="Email" type="email" hint="Opsional" />
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormInput v-model="form.parent_name" label="Nama Orang Tua" />
            <FormInput v-model="form.parent_phone" label="Telepon Orang Tua" />
          </div>
        </div>
      </div>

      <!-- Section 3: Akun Login -->
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-100 text-sm">🔐</div>
              <div>
                <h3 class="text-sm font-semibold text-slate-700">Akun Login</h3>
                <p class="text-xs text-slate-400">Kelola akses masuk aplikasi untuk siswa</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
               <input type="checkbox" id="update_account" v-model="form.update_account" class="h-4 w-4 rounded border-slate-300 text-primary-600 focus:ring-primary-500">
               <label for="update_account" class="text-sm font-medium text-slate-700">Reset Password / Buat Akun</label>
            </div>
          </div>
        </div>
        <div v-if="form.update_account" class="space-y-4 p-6 transition-all duration-300">
          <div class="rounded-lg bg-blue-50 p-4 text-sm text-blue-700">
             <p class="font-medium">Tindakan ini akan mereset password atau membuat akun baru (jika belum ada) dengan detail:</p>
            <ul class="mt-2 list-disc list-inside space-y-1 ml-2">
                <li>Username: <strong>{{ form.nis }}@siswa.sekolah.id</strong></li>
                <li>Password Baru: <strong>password</strong></li>
            </ul>
             <p class="mt-2 text-xs">Pastikan NIS sudah benar sebelum menyimpan.</p>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white px-6 py-4 shadow-sm">
        <div>
           <Button v-if="permissions?.manage_students" @click.prevent="deleteStudent" variant="danger" type="button" class="bg-red-50 text-red-600 hover:bg-red-100 hover:text-red-700 border-none">
             <svg class="h-4 w-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
             Hapus Siswa
           </Button>
        </div>
        <div class="flex gap-3">
            <Button :href="`/students/${student.id}`" variant="ghost">Batal</Button>
            <Button type="submit" :loading="form.processing">
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Simpan Perubahan
            </Button>
        </div>
      </div>
    </form>
  </div>
</template>
