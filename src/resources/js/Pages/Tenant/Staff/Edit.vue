<script setup>
import { useForm, Head, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  teacher: Object,
});

const form = useForm({
  name: props.teacher.name || '',
  nip: props.teacher.nip || '',
  nuptk: props.teacher.nuptk || '',
  email: props.teacher.email || '',
  phone: props.teacher.phone || '',
  gender: props.teacher.gender || 'male',
  birth_place: props.teacher.birth_place || '',
  birth_date: props.teacher.birth_date ? props.teacher.birth_date.split('T')[0] : '',
  address: props.teacher.address || '',
  status: props.teacher.status || 'active',
});

const submit = () => {
  form.put(`/tenant/staff/${props.teacher.id}`, {
    preserveScroll: true,
  });
};
</script>

<template>
  <Head title="Edit Guru" />

  <div class="max-w-3xl mx-auto">
    <!-- Header -->
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Edit Data Guru</h2>
        <p class="text-sm text-slate-500 mt-0.5">Perbarui data {{ teacher.name }}</p>
      </div>
      <Link
        href="/staff"
        class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3.5 py-2 text-xs font-medium text-slate-600 shadow-sm transition-colors hover:bg-slate-50"
      >
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
        Kembali
      </Link>
    </div>

    <!-- Form Card -->
    <form @submit.prevent="submit" class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <!-- Personal Info -->
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Informasi Pribadi</h3>
      </div>
      <div class="grid grid-cols-1 gap-5 px-6 py-5 sm:grid-cols-2">
        <!-- Name -->
        <div class="sm:col-span-2">
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Nama Lengkap <span class="text-red-500">*</span></label>
          <input v-model="form.name" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="Masukkan nama lengkap" />
          <p v-if="form.errors.name" class="mt-1 text-xs text-red-500">{{ form.errors.name }}</p>
        </div>
        <!-- NIP -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">NIP</label>
          <input v-model="form.nip" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="Nomor Induk Pegawai" />
          <p v-if="form.errors.nip" class="mt-1 text-xs text-red-500">{{ form.errors.nip }}</p>
        </div>
        <!-- NUPTK -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">NUPTK</label>
          <input v-model="form.nuptk" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="Nomor Unik Pendidik Tenaga Kependidikan" />
          <p v-if="form.errors.nuptk" class="mt-1 text-xs text-red-500">{{ form.errors.nuptk }}</p>
        </div>
        <!-- Email -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Email</label>
          <input v-model="form.email" type="email" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="email@sekolah.id" />
          <p v-if="form.errors.email" class="mt-1 text-xs text-red-500">{{ form.errors.email }}</p>
        </div>
        <!-- Phone -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">No. Telepon</label>
          <input v-model="form.phone" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="08xxxxxxxxx" />
          <p v-if="form.errors.phone" class="mt-1 text-xs text-red-500">{{ form.errors.phone }}</p>
        </div>
        <!-- Gender -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Jenis Kelamin <span class="text-red-500">*</span></label>
          <select v-model="form.gender" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="male">Laki-laki</option>
            <option value="female">Perempuan</option>
          </select>
          <p v-if="form.errors.gender" class="mt-1 text-xs text-red-500">{{ form.errors.gender }}</p>
        </div>
        <!-- Status -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Status <span class="text-red-500">*</span></label>
          <select v-model="form.status" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="active">Aktif</option>
            <option value="inactive">Nonaktif</option>
          </select>
          <p v-if="form.errors.status" class="mt-1 text-xs text-red-500">{{ form.errors.status }}</p>
        </div>
        <!-- Birth Place -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Tempat Lahir</label>
          <input v-model="form.birth_place" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="Kota/Kabupaten" />
          <p v-if="form.errors.birth_place" class="mt-1 text-xs text-red-500">{{ form.errors.birth_place }}</p>
        </div>
        <!-- Birth Date -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Tanggal Lahir</label>
          <input v-model="form.birth_date" type="date" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
          <p v-if="form.errors.birth_date" class="mt-1 text-xs text-red-500">{{ form.errors.birth_date }}</p>
        </div>
        <!-- Address -->
        <div class="sm:col-span-2">
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Alamat</label>
          <textarea v-model="form.address" rows="3" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm transition-colors placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="Alamat lengkap" />
          <p v-if="form.errors.address" class="mt-1 text-xs text-red-500">{{ form.errors.address }}</p>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-end gap-3 border-t border-slate-100 bg-slate-50/50 px-6 py-4 rounded-b-xl">
        <Link
          href="/staff"
          class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 shadow-sm transition-colors hover:bg-slate-50"
        >
          Batal
        </Link>
        <button
          type="submit"
          :disabled="form.processing"
          class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-all hover:bg-emerald-700 disabled:opacity-50"
        >
          <svg v-if="form.processing" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
          Simpan Perubahan
        </button>
      </div>
    </form>
  </div>
</template>
