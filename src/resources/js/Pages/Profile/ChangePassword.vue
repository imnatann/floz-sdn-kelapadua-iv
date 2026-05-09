<script setup>
import { useForm, Head } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const form = useForm({
  current_password: '',
  password: '',
  password_confirmation: '',
});

const submit = () => {
  form.put('/profile/password', {
    preserveScroll: true,
    onSuccess: () => form.reset(),
  });
};
</script>

<template>
  <Head title="Ganti Password" />

  <div class="mx-auto max-w-md">
    <div class="mb-6">
      <h2 class="text-xl font-bold text-slate-800">Ganti Password</h2>
      <p class="mt-0.5 text-sm text-slate-400">Pastikan password baru minimal 8 karakter.</p>
    </div>

    <div v-if="$page.props.flash?.success" class="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-700">
      {{ $page.props.flash.success }}
    </div>

    <form @submit.prevent="submit" class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Ubah Kata Sandi</h3>
      </div>

      <div class="space-y-5 px-6 py-5">
        <!-- Current Password -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">
            Password Saat Ini <span class="text-red-500">*</span>
          </label>
          <input
            v-model="form.current_password"
            type="password"
            autocomplete="current-password"
            class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20"
            placeholder="Password lama Anda"
          />
          <p v-if="form.errors.current_password" class="mt-1 text-xs text-red-500">{{ form.errors.current_password }}</p>
        </div>

        <!-- New Password -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">
            Password Baru <span class="text-red-500">*</span>
          </label>
          <input
            v-model="form.password"
            type="password"
            autocomplete="new-password"
            class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20"
            placeholder="Minimal 8 karakter"
          />
          <p v-if="form.errors.password" class="mt-1 text-xs text-red-500">{{ form.errors.password }}</p>
        </div>

        <!-- Confirm Password -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">
            Konfirmasi Password Baru <span class="text-red-500">*</span>
          </label>
          <input
            v-model="form.password_confirmation"
            type="password"
            autocomplete="new-password"
            class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20"
            placeholder="Ulangi password baru"
          />
        </div>
      </div>

      <div class="flex items-center justify-end gap-3 rounded-b-xl border-t border-slate-100 bg-slate-50/50 px-6 py-4">
        <button
          type="submit"
          :disabled="form.processing"
          class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-emerald-700 disabled:opacity-50"
        >
          <svg v-if="form.processing" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
          </svg>
          Simpan Password Baru
        </button>
      </div>
    </form>
  </div>
</template>
