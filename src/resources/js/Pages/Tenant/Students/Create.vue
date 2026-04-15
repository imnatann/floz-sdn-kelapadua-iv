<script setup>
import { useForm, Head } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormInput from '@/Components/UI/FormInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import FormTextarea from '@/Components/UI/FormTextarea.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({ classes: Array });

const form = useForm({
  nis: '', nisn: '', name: '', gender: '', birth_place: '', birth_date: '',
  religion: '', address: '', parent_name: '', parent_phone: '', email: '', class_id: '',
  create_account: false,
});

const submit = () => form.post('/students');
</script>

<template>
  <Head title="Tambah Siswa" />
  <div class="mx-auto max-w-3xl space-y-6">
    <!-- Header -->
    <div class="flex items-center gap-4">
      <Button href="/students" variant="outline" size="sm">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        Kembali
      </Button>
      <div>
        <h2 class="text-xl font-bold text-slate-800">Tambah Siswa Baru</h2>
        <p class="mt-0.5 text-sm text-slate-400">Daftarkan siswa baru ke dalam sistem</p>
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
            <FormInput v-model="form.nis" label="NIS" placeholder="Nomor Induk Siswa" :required="true" :error="form.errors.nis" />
            <FormInput v-model="form.nisn" label="NISN" placeholder="Nomor Induk Siswa Nasional" hint="Opsional" :error="form.errors.nisn" />
          </div>
          <FormInput v-model="form.name" label="Nama Lengkap" placeholder="Nama lengkap siswa" :required="true" :error="form.errors.name" />
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormSelect v-model="form.gender" label="Jenis Kelamin" :error="form.errors.gender">
              <option value="">— Pilih —</option>
              <option value="male">Laki-laki</option>
              <option value="female">Perempuan</option>
            </FormSelect>
            <FormSelect v-model="form.religion" label="Agama" :error="form.errors.religion">
              <option value="">— Pilih —</option>
              <option v-for="r in ['Islam','Kristen','Katolik','Hindu','Buddha','Konghucu']" :key="r" :value="r">{{ r }}</option>
            </FormSelect>
          </div>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormInput v-model="form.birth_place" label="Tempat Lahir" placeholder="Kota kelahiran" />
            <FormInput v-model="form.birth_date" label="Tanggal Lahir" type="date" :error="form.errors.birth_date" />
          </div>
          <FormTextarea v-model="form.address" label="Alamat" placeholder="Alamat lengkap siswa" :rows="2" />
        </div>
      </div>

      <!-- Section 2: Kelas & Wali -->
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
          <div class="flex items-center gap-3">
            <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-100 text-sm">🏫</div>
            <div>
              <h3 class="text-sm font-semibold text-slate-700">Kelas & Orang Tua</h3>
              <p class="text-xs text-slate-400">Penempatan kelas dan kontak wali</p>
            </div>
          </div>
        </div>
        <div class="space-y-4 p-6">
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormSelect v-model="form.class_id" label="Kelas" :error="form.errors.class_id">
              <option value="">— Belum Ditempatkan —</option>
              <option v-for="c in classes" :key="c.id" :value="c.id">{{ c.name }}</option>
            </FormSelect>
            <FormInput v-model="form.email" label="Email" type="email" placeholder="siswa@email.com" hint="Opsional" :error="form.errors.email" />
          </div>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormInput v-model="form.parent_name" label="Nama Orang Tua" placeholder="Nama lengkap wali" :error="form.errors.parent_name" />
            <FormInput v-model="form.parent_phone" label="Telepon Orang Tua" placeholder="0812-xxxx-xxxx" :error="form.errors.parent_phone" />
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
                <p class="text-xs text-slate-400">Akses masuk aplikasi untuk siswa</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
               <input type="checkbox" id="create_account" v-model="form.create_account" class="h-4 w-4 rounded border-slate-300 text-primary-600 focus:ring-primary-500">
               <label for="create_account" class="text-sm font-medium text-slate-700">Buat Akun Otomatis</label>
            </div>
          </div>
        </div>
        <div v-if="form.create_account" class="space-y-4 p-6 transition-all duration-300">
          <div class="rounded-lg bg-blue-50 p-4 text-sm text-blue-700">
            <p class="font-medium">Akun akan dibuat secara otomatis dengan detail berikut:</p>
            <ul class="mt-2 list-disc list-inside space-y-1 ml-2">
                <li>Username: <strong>{NIS}@siswa.sekolah.id</strong> (Contoh: 12345@siswa.sekolah.id)</li>
                <li>Password Default: <strong>password</strong></li>
            </ul>
            <p class="mt-2 text-xs">Email pada data orang tua di atas tetap bersifat opsional dan terpisah dari akun login siswa.</p>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-end gap-3 rounded-xl border border-slate-200 bg-white px-6 py-4 shadow-sm">
        <Button href="/students" variant="ghost">Batal</Button>
        <Button type="submit" :loading="form.processing">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
          Simpan Siswa
        </Button>
      </div>
    </form>
  </div>
</template>
