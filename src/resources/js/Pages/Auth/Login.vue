<script setup>
import { useForm, Head } from '@inertiajs/vue3';

const form = useForm({
  email: '',
  password: '',
  remember: false,
});

const submit = () => {
  form.post('/login', {
    onFinish: () => form.reset('password'),
  });
};
</script>

<template>
  <Head title="Masuk" />

  <div class="flex min-h-screen">
    <!-- Left Panel - Branding -->
    <div class="hidden lg:flex lg:w-[45%] flex-col justify-between bg-gradient-to-br from-orange-600 via-orange-500 to-amber-500 p-10 text-white relative overflow-hidden">
      <!-- Decorative shapes -->
      <div class="absolute -top-20 -right-20 h-72 w-72 rounded-full bg-white/10 blur-sm" />
      <div class="absolute -bottom-16 -left-16 h-56 w-56 rounded-full bg-white/10 blur-sm" />
      <div class="absolute top-1/2 right-10 h-32 w-32 rounded-2xl bg-white/5 rotate-12" />

      <!-- Logo -->
      <div class="relative z-10">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20 text-lg font-bold backdrop-blur-sm">F</div>
          <span class="text-xl font-bold tracking-wide" style="font-family: 'Space Grotesk', sans-serif">FLOZ</span>
        </div>
      </div>

      <!-- Hero Text -->
      <div class="relative z-10 space-y-4">
        <h2 class="text-3xl font-bold leading-tight" style="font-family: 'Space Grotesk', sans-serif">
          Sistem Rapor<br />Digital Modern
        </h2>
        <p class="max-w-sm text-sm leading-relaxed text-white/80">
          Kelola rapor siswa dengan mudah. Otomatisasi perhitungan nilai, cetak rapor PDF, dan pantau perkembangan akademik secara real-time.
        </p>
      </div>

      <p class="relative z-10 text-xs text-white/40">
        &copy; {{ new Date().getFullYear() }} SDN Kelapadua IV
      </p>
    </div>

    <!-- Right Panel - Login Form -->
    <div class="flex flex-1 items-center justify-center bg-slate-50 p-6">
      <div class="w-full max-w-sm">
        <!-- Mobile Logo -->
        <div class="mb-8 text-center lg:hidden">
          <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-orange-500 to-orange-600 text-white text-lg font-bold shadow-lg shadow-orange-600/30">F</div>
          <h1 class="text-lg font-bold text-slate-800" style="font-family: 'Space Grotesk', sans-serif">SDN Kelapadua IV</h1>
        </div>

        <!-- Form Header -->
        <div class="mb-6">
          <h1 class="text-xl font-bold text-slate-800">Selamat Datang 👋</h1>
          <p class="mt-1 text-sm text-slate-400">Masuk ke akun Anda untuk melanjutkan</p>
        </div>

        <!-- Login Form -->
        <form @submit.prevent="submit" class="space-y-4">
          <!-- Email -->
          <div>
            <label class="mb-1.5 block text-xs font-medium text-slate-600">Email</label>
            <input
              v-model="form.email"
              type="email"
              placeholder="nama@email.com"
              required
              autofocus
              class="w-full rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-700 placeholder:text-slate-300 transition-all focus:border-orange-400 focus:outline-none focus:ring-2 focus:ring-orange-100"
            />
            <p v-if="form.errors.email" class="mt-1.5 text-xs text-red-500">{{ form.errors.email }}</p>
          </div>

          <!-- Password -->
          <div>
            <label class="mb-1.5 block text-xs font-medium text-slate-600">Password</label>
            <input
              v-model="form.password"
              type="password"
              placeholder="••••••••"
              required
              class="w-full rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-700 placeholder:text-slate-300 transition-all focus:border-orange-400 focus:outline-none focus:ring-2 focus:ring-orange-100"
            />
          </div>

          <!-- Remember -->
          <div class="flex items-center gap-2">
            <input
              v-model="form.remember"
              type="checkbox"
              id="remember"
              class="h-3.5 w-3.5 rounded border-slate-300 text-orange-600 focus:ring-orange-500"
            />
            <label for="remember" class="text-xs text-slate-500 cursor-pointer">Ingat saya</label>
          </div>

          <!-- Submit -->
          <button
            type="submit"
            :disabled="form.processing"
            class="flex w-full items-center justify-center gap-2 rounded-lg bg-orange-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-orange-600/20 transition-all hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-1 disabled:opacity-60"
          >
            <svg v-if="form.processing" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            {{ form.processing ? 'Memproses...' : 'Masuk' }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
