<script setup>
import { useForm, Head } from '@inertiajs/vue3';
import { ref, watch } from 'vue';
import Modal from '@/Components/UI/Modal.vue';
import axios from 'axios';

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

// Tenant Search Logic
const isSearchModalOpen = ref(false);
const searchQuery = ref('');
const searchResults = ref([]);
const validSearch = ref(false); // To prevent spamming
const isLoading = ref(false);

let debounceTimer = null;

watch(searchQuery, (newQuery) => {
    if (debounceTimer) clearTimeout(debounceTimer);
    
    if (newQuery.length < 3) {
        searchResults.value = [];
        validSearch.value = false;
        return;
    }

    isLoading.value = true;
    validSearch.value = true;

    debounceTimer = setTimeout(() => {
        axios.get('/api/tenants/search', { params: { q: newQuery } })
            .then(response => {
                searchResults.value = response.data;
            })
            .catch(error => {
                console.error("Search error:", error);
                searchResults.value = [];
            })
            .finally(() => {
                isLoading.value = false;
            });
    }, 300);
});

const openSearchModal = () => {
    isSearchModalOpen.value = true;
    setTimeout(() => {
        document.getElementById('tenant-search-input')?.focus();
    }, 100);
};

const closeSearchModal = () => {
    isSearchModalOpen.value = false;
    searchQuery.value = '';
    searchResults.value = [];
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
          Kelola rapor siswa SD, SMP, dan SMA dengan mudah. Otomatisasi perhitungan nilai, cetak rapor PDF, dan pantau perkembangan akademik secara real-time.
        </p>
        <div class="flex items-center gap-6 pt-2">
          <div class="flex flex-col">
            <span class="text-2xl font-bold">500+</span>
            <span class="text-xs text-white/60">Sekolah</span>
          </div>
          <div class="h-8 w-px bg-white/20" />
          <div class="flex flex-col">
            <span class="text-2xl font-bold">50K+</span>
            <span class="text-xs text-white/60">Siswa</span>
          </div>
          <div class="h-8 w-px bg-white/20" />
          <div class="flex flex-col">
            <span class="text-2xl font-bold">99.9%</span>
            <span class="text-xs text-white/60">Uptime</span>
          </div>
        </div>
      </div>

      <p class="relative z-10 text-xs text-white/40">
        &copy; {{ new Date().getFullYear() }} FLOZ — Platform Rapor Digital Indonesia
      </p>
    </div>

    <!-- Right Panel - Login Form -->
    <div class="flex flex-1 items-center justify-center bg-slate-50 p-6">
      <div class="w-full max-w-sm">
        <!-- Mobile Logo -->
        <div class="mb-8 text-center lg:hidden">
          <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-orange-500 to-orange-600 text-white text-lg font-bold shadow-lg shadow-orange-600/30">F</div>
          <h1 class="text-lg font-bold text-slate-800" style="font-family: 'Space Grotesk', sans-serif">FLOZ</h1>
        </div>

        <!-- Form Header -->
        <div class="mb-6">
          <h1 class="text-xl font-bold text-slate-800">Selamat Datang 👋</h1>
          <p class="mt-1 text-sm text-slate-400">Masuk ke akun Anda untuk melanjutkan</p>
          <button 
            type="button" 
            @click="openSearchModal"
            class="mt-3 text-sm text-orange-600 font-medium hover:text-orange-700 flex items-center gap-1 transition-colors"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
            Bukan sekolah Anda? Cari sekolah lain
          </button>
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
    <Modal :show="isSearchModalOpen" @close="closeSearchModal">
        <div class="p-6">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-bold text-slate-900">Cari Sekolah</h3>
                <button @click="closeSearchModal" class="text-slate-400 hover:text-slate-600">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>

            <div class="relative mb-6">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                </div>
                <input
                    id="tenant-search-input"
                    v-model="searchQuery"
                    type="text"
                    class="block w-full pl-10 pr-3 py-3 border border-slate-300 rounded-lg leading-5 bg-white placeholder-slate-400 focus:outline-none focus:placeholder-slate-500 focus:border-orange-500 focus:ring-1 focus:ring-orange-500 sm:text-sm transition duration-150 ease-in-out"
                    placeholder="Ketik nama sekolah (minimal 3 karakter)..."
                    autocomplete="off"
                />
            </div>

            <div class="min-h-[150px]">
                <!-- Loading -->
                <div v-if="isLoading" class="flex justify-center py-8">
                    <svg class="animate-spin h-8 w-8 text-orange-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                    </svg>
                </div>

                <!-- Empty State (No Query) -->
                <div v-else-if="!validSearch && !isLoading" class="text-center py-8 text-slate-400">
                    <p>Mulai ketik nama sekolah untuk mencari</p>
                </div>

                <!-- No Results -->
                <div v-else-if="validSearch && searchResults.length === 0 && !isLoading" class="text-center py-8 text-slate-500">
                    <p>Sekolah tidak ditemukan.</p>
                </div>

                <!-- Results -->
                <ul v-else class="space-y-2 max-h-[300px] overflow-y-auto">
                    <li v-for="tenant in searchResults" :key="tenant.id">
                        <a 
                            :href="tenant.url" 
                            class="flex items-center gap-3 p-3 rounded-lg border border-slate-100 hover:border-orange-200 hover:bg-orange-50 transition-all group"
                        >
                            <div class="h-10 w-10 flex-shrink-0 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 font-bold overflow-hidden border border-slate-200">
                                <img v-if="tenant.logo_url" :src="tenant.logo_url" alt="" class="h-full w-full object-cover" />
                                <span v-else>{{ tenant.name.charAt(0) }}</span>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-sm font-medium text-slate-900 group-hover:text-orange-700 truncate">
                                    {{ tenant.name }}
                                </p>
                                <p class="text-xs text-slate-500 truncate">
                                    {{ tenant.domain }}
                                </p>
                            </div>
                            <svg class="h-5 w-5 text-slate-300 group-hover:text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                        </a>
                    </li>
                </ul>
            </div>
            
            <div class="mt-4 pt-4 border-t border-slate-100 text-center">
                 <button @click="closeSearchModal" class="text-sm text-slate-500 hover:text-slate-800">Tutup</button>
            </div>
        </div>
    </Modal>
</template>
