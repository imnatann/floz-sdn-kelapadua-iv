<script setup>
import { Link, Head } from '@inertiajs/vue3';
</script>

<template>
  <Head title="Langganan Kadaluarsa" />
  <div class="flex min-h-screen items-center justify-center bg-gradient-to-br from-slate-50 via-white to-emerald-50/30 px-4">
    <div class="w-full max-w-lg text-center">
      <!-- Icon -->
      <div class="mx-auto flex h-20 w-20 items-center justify-center rounded-2xl bg-amber-100 shadow-lg shadow-amber-200/30">
        <svg class="h-10 w-10 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 9v2m0 4h.01M5.07 19h13.86c1.5 0 2.47-1.6 1.73-2.88l-6.93-12c-.74-1.28-2.6-1.28-3.34 0l-6.93 12C2.6 17.4 3.57 19 5.07 19z"/>
        </svg>
      </div>

      <!-- Content -->
      <h1 class="mt-6 text-2xl font-bold text-slate-800">Langganan Kadaluarsa</h1>
      <p class="mx-auto mt-3 max-w-sm text-sm leading-relaxed text-slate-500">
        Langganan sekolah Anda telah berakhir. Silakan hubungi admin platform untuk memperpanjang langganan atau upgrade paket Anda.
      </p>

      <!-- Upgrade CTA Card -->
      <div class="mx-auto mt-8 max-w-sm overflow-hidden rounded-xl border border-emerald-200 bg-gradient-to-br from-emerald-50 to-teal-50 p-6 text-left shadow-sm">
        <div class="flex items-start gap-3">
          <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-100">
            <svg class="h-5 w-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
          </div>
          <div>
            <p class="text-sm font-semibold text-emerald-800">Perpanjang Langganan</p>
            <p class="mt-1 text-xs text-emerald-600">Hubungi tim support kami untuk informasi harga dan promo terkini.</p>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="mt-8 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
        <a
          href="mailto:support@floz.id"
          class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-6 py-2.5 text-sm font-medium text-white shadow-md shadow-emerald-600/20 transition-all hover:bg-emerald-700 hover:shadow-lg"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
          Hubungi Support
        </a>
        <Link
          href="/logout"
          method="post"
          as="button"
          class="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-6 py-2.5 text-sm font-medium text-slate-500 transition-all hover:bg-slate-50"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
          Keluar
        </Link>
      </div>

      <!-- Footer note -->
      <p class="mt-8 text-[10px] text-slate-400">
        support@floz.id &middot; &copy; {{ new Date().getFullYear() }} FLOZ Learning Management System
      </p>
    </div>
  </div>
</template>
