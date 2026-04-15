<script setup>
import { computed } from 'vue';

const props = defineProps({
  student: Object,
});

const infoItems = [
  { label: 'NIS / NISN', value: () => `${props.student.nis} / ${props.student.nisn || '-'}` },
  { label: 'NIK', value: () => props.student.nik || '—' },
  { label: 'No. KK', value: () => props.student.family_card_number || '—' },
  { label: 'Jenis Kelamin', value: () => props.student.gender === 'male' ? 'Laki-laki' : props.student.gender === 'female' ? 'Perempuan' : '—' },
  { label: 'Agama', value: () => props.student.religion || '—' },
  { label: 'Tempat Lahir', value: () => props.student.birth_place || '—' },
  { label: 'Tanggal Lahir', value: () => props.student.birth_date || '—' },
  { label: 'Email', value: () => props.student.email || '—' },
  { label: 'Nama Orang Tua', value: () => props.student.parent_name || '—' },
  { label: 'Telepon Orang Tua', value: () => props.student.parent_phone || '—' },
];

const health = computed(() => props.student.health_record || {});

const healthItems = [
  { label: 'Golongan Darah', value: () => health.value.blood_type || '—' },
  { label: 'Tinggi Badan', value: () => health.value.height ? `${health.value.height} cm` : '—' },
  { label: 'Berat Badan', value: () => health.value.weight ? `${health.value.weight} kg` : '—' },
  { label: 'Alergi', value: () => health.value.allergies || '—' },
  { label: 'Berkebutuhan Khusus', value: () => health.value.special_needs || 'Tidak' },
];
</script>

<template>
  <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
    <!-- Personal Info -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Data Pribadi</h3>
      </div>
      <div class="grid grid-cols-1 gap-px bg-slate-100 p-px sm:grid-cols-2">
        <div v-for="item in infoItems" :key="item.label" class="bg-white p-4">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">{{ item.label }}</p>
          <p class="mt-1 text-sm font-medium text-slate-700">{{ item.value() }}</p>
        </div>
        <div class="col-span-1 sm:col-span-2 bg-white p-4">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Alamat</p>
          <p class="mt-1 text-sm font-medium text-slate-700">{{ student.address || '—' }}</p>
        </div>
      </div>
    </div>

    <!-- Health Record -->
    <div class="space-y-6">
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
          <h3 class="text-sm font-semibold text-slate-700">Rekam Kesehatan</h3>
        </div>
        <div class="grid grid-cols-1 gap-px bg-slate-100 p-px sm:grid-cols-2">
          <div v-for="item in healthItems" :key="item.label" class="bg-white p-4">
            <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">{{ item.label }}</p>
            <p class="mt-1 text-sm font-medium text-slate-700">{{ item.value() }}</p>
          </div>
          <div class="col-span-1 sm:col-span-2 bg-white p-4">
             <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Riwayat Penyakit</p>
             <p class="mt-1 text-sm font-medium text-slate-700">{{ health.value?.medical_history || '—' }}</p>
          </div>
        </div>
      </div>

      <!-- Siblings -->
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
          <h3 class="text-sm font-semibold text-slate-700">Saudara Kandung (Satu Sekolah)</h3>
        </div>
        <div v-if="student.siblings && student.siblings.length" class="divide-y divide-slate-100">
          <div v-for="sibling in student.siblings" :key="sibling.id" class="flex items-center gap-3 p-4">
             <div class="flex h-10 w-10 items-center justify-center rounded-full bg-slate-100 text-sm font-bold text-slate-500">
                {{ sibling.name.charAt(0) }}
             </div>
             <div>
                <p class="text-sm font-medium text-slate-700">{{ sibling.name }}</p>
                <p class="text-xs text-slate-400">{{ sibling.class?.name || 'No Class' }}</p>
             </div>
          </div>
        </div>
        <div v-else class="p-6 text-center text-sm text-slate-400">
          Tidak ada data saudara kandung
        </div>
      </div>
    </div>
  </div>
</template>
