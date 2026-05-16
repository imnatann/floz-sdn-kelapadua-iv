<script setup>
import { computed } from 'vue';
import { router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Card from '@/Components/UI/Card.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
  summary: { type: Object, required: true },
  resources: { type: Object, required: true },
  database: { type: Object, required: true },
  cache: { type: Object, required: true },
  queue: { type: Object, required: true },
  runtime: { type: Array, required: true },
  directories: { type: Array, required: true },
  services: { type: Array, required: true },
});

const statusTone = {
  ok: {
    label: 'Normal',
    pill: 'border-emerald-200 bg-emerald-50 text-emerald-700',
    dot: 'bg-emerald-500',
    text: 'text-emerald-700',
    icon: 'bg-emerald-50 text-emerald-600',
  },
  warning: {
    label: 'Perlu dicek',
    pill: 'border-amber-200 bg-amber-50 text-amber-700',
    dot: 'bg-amber-500',
    text: 'text-amber-700',
    icon: 'bg-amber-50 text-amber-600',
  },
  error: {
    label: 'Bermasalah',
    pill: 'border-rose-200 bg-rose-50 text-rose-700',
    dot: 'bg-rose-500',
    text: 'text-rose-700',
    icon: 'bg-rose-50 text-rose-600',
  },
};

const metricCards = computed(() => {
  const partitionPercent = props.resources.partition?.used_percent;
  const latency = props.database?.latency_ms;
  const largestDirectory = [...(props.directories ?? [])]
    .filter((directory) => Number.isFinite(Number(directory.size_bytes)))
    .sort((a, b) => Number(b.size_bytes) - Number(a.size_bytes))[0];

  return [
    {
      key: 'partition',
      label: 'Partisi project',
      value: valueOrFallback(partitionPercent, '%'),
      subtitle: `${props.resources.partition?.free ?? 'N/A'} tersisa dari ${props.resources.partition?.total ?? 'N/A'}`,
      tone: partitionPercent >= 75 ? 'amber' : 'orange',
    },
    {
      key: 'directory',
      label: 'Folder terbesar',
      value: largestDirectory?.size ?? 'N/A',
      subtitle: largestDirectory?.label ?? 'Belum ada data folder',
      tone: 'emerald',
    },
    {
      key: 'php',
      label: 'PHP process',
      value: props.resources.php?.memory_usage ?? 'N/A',
      subtitle: `Peak ${props.resources.php?.memory_peak ?? 'N/A'} / limit ${props.resources.php?.memory_limit ?? 'N/A'}`,
      tone: 'blue',
    },
    {
      key: 'database',
      label: 'Database',
      value: latency !== null && latency !== undefined ? `${latency} ms` : 'N/A',
      subtitle: props.database?.size ? `Ukuran ${props.database.size}` : 'Ukuran tidak tersedia',
      tone: props.database?.status === 'ok' ? 'violet' : 'rose',
    },
  ];
});

const resourceRows = computed(() => [
  {
    label: 'Partisi project',
    value: valueOrFallback(props.resources.partition?.used_percent, '%'),
    percent: props.resources.partition?.used_percent,
    detail: `${props.resources.partition?.used ?? 'N/A'} terpakai dari ${props.resources.partition?.total ?? 'N/A'}`,
  },
  ...(props.directories ?? []).map((directory) => ({
    label: directory.label,
    value: directory.size,
    percent: directoryPercent(directory.size_bytes),
    detail: directory.path,
  })),
]);

const refresh = () => {
  router.reload({ preserveScroll: true });
};

function toneClasses(tone) {
  const tones = {
    blue: 'border-blue-100 bg-blue-50 text-blue-600',
    emerald: 'border-emerald-100 bg-emerald-50 text-emerald-600',
    orange: 'border-orange-100 bg-orange-50 text-orange-600',
    amber: 'border-amber-100 bg-amber-50 text-amber-600',
    violet: 'border-violet-100 bg-violet-50 text-violet-600',
    rose: 'border-rose-100 bg-rose-50 text-rose-600',
  };

  return tones[tone] ?? tones.orange;
}

function serviceTone(status) {
  return statusTone[status] ?? statusTone.warning;
}

function safePercent(value) {
  const numeric = Number(value);

  if (! Number.isFinite(numeric)) {
    return 0;
  }

  return Math.max(0, Math.min(100, numeric));
}

function barClass(value) {
  if (value === null || value === undefined || value === '') {
    return 'bg-slate-300';
  }

  const percent = Number(value);

  if (! Number.isFinite(percent)) {
    return 'bg-slate-300';
  }

  if (percent >= 90) return 'bg-rose-500';
  if (percent >= 75) return 'bg-amber-500';
  return 'bg-emerald-500';
}

function directoryPercent(size) {
  const total = Number(props.resources.partition?.total_bytes);
  const value = Number(size);

  if (! Number.isFinite(total) || total <= 0 || ! Number.isFinite(value)) {
    return null;
  }

  return Math.max(0, Math.min(100, Number(((value / total) * 100).toFixed(2))));
}

function valueOrFallback(value, suffix = '') {
  if (value === null || value === undefined || value === '') {
    return 'N/A';
  }

  return `${value}${suffix}`;
}

</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Manajemen Server</h2>
        <p class="mt-0.5 text-sm text-slate-400">Statistik partisi project dan kesehatan layanan aplikasi</p>
      </div>
      <button
        type="button"
        class="inline-flex h-10 items-center justify-center gap-2 rounded-lg border border-slate-200 bg-white px-4 text-sm font-medium text-slate-600 shadow-sm transition-colors hover:border-orange-200 hover:bg-orange-50 hover:text-orange-700"
        @click="refresh"
      >
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M4 4v6h6M20 20v-6h-6M20 9a7 7 0 00-12.04-4.9L4 10m16 4l-3.96 5.9A7 7 0 014 15" />
        </svg>
        Muat ulang
      </button>
    </div>

    <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div class="flex items-start gap-4">
          <div
            :class="[
              'flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border',
              serviceTone(summary.status).icon,
            ]"
          >
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M5 12h14M6 4h12a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2V6a2 2 0 012-2zm0 8h12a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2v-4a2 2 0 012-2z" />
            </svg>
          </div>
          <div>
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="text-base font-semibold text-slate-800">{{ summary.hostname }}</h3>
              <span
                :class="[
                  'inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-semibold',
                  serviceTone(summary.status).pill,
                ]"
              >
                <span :class="['h-1.5 w-1.5 rounded-full', serviceTone(summary.status).dot]" />
                {{ serviceTone(summary.status).label }}
              </span>
            </div>
            <p class="mt-1 text-sm text-slate-500">
              {{ summary.scope }} - Environment {{ summary.environment }} - Update {{ summary.generated_at }}
            </p>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4 lg:min-w-[520px]">
          <div class="rounded-lg border border-slate-100 bg-slate-50 px-3 py-2">
            <p class="text-xs text-slate-400">Cache</p>
            <p class="truncate font-semibold text-slate-700">{{ cache.driver }}</p>
          </div>
          <div class="rounded-lg border border-slate-100 bg-slate-50 px-3 py-2">
            <p class="text-xs text-slate-400">Queue</p>
            <p class="truncate font-semibold text-slate-700">{{ queue.connection }}</p>
          </div>
          <div class="rounded-lg border border-slate-100 bg-slate-50 px-3 py-2">
            <p class="text-xs text-slate-400">Database</p>
            <p class="truncate font-semibold text-slate-700">{{ database.driver }}</p>
          </div>
          <div class="rounded-lg border border-slate-100 bg-slate-50 px-3 py-2">
            <p class="text-xs text-slate-400">PHP RAM</p>
            <p class="truncate font-semibold text-slate-700">{{ resources.php.memory_limit }}</p>
          </div>
        </div>
      </div>
    </section>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <div
        v-for="metric in metricCards"
        :key="metric.key"
        class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="min-w-0">
            <p class="text-xs font-semibold uppercase text-slate-400">{{ metric.label }}</p>
            <p class="mt-1 text-2xl font-bold text-slate-800">{{ metric.value }}</p>
            <p class="mt-1 truncate text-xs text-slate-400">{{ metric.subtitle }}</p>
          </div>
          <div :class="['flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border', toneClasses(metric.tone)]">
            <svg v-if="metric.key === 'partition'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M4 7c0-1.66 3.58-3 8-3s8 1.34 8 3-3.58 3-8 3-8-1.34-8-3zm0 0v10c0 1.66 3.58 3 8 3s8-1.34 8-3V7M4 12c0 1.66 3.58 3 8 3s8-1.34 8-3" />
            </svg>
            <svg v-else-if="metric.key === 'directory'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M3 7.5A2.5 2.5 0 015.5 5H10l2 2h6.5A2.5 2.5 0 0121 9.5v7A2.5 2.5 0 0118.5 19h-13A2.5 2.5 0 013 16.5v-9z" />
            </svg>
            <svg v-else-if="metric.key === 'php'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M7 7h10v10H7zM4 10h3m-3 4h3m13-4h3m-3 4h3M10 4v3m4-3v3m-4 10v3m4-3v3" />
            </svg>
            <svg v-else class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M4 7h16M4 12h16M4 17h16M7 7v10m10-10v10" />
            </svg>
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <Card title="Pemakaian Partisi Project" subtitle="Partisi tempat aplikasi berada dan folder pentingnya" class="xl:col-span-2">
        <div class="space-y-5">
          <div v-for="row in resourceRows" :key="row.label">
            <div class="mb-2 flex items-center justify-between gap-3">
              <div>
                <p class="text-sm font-semibold text-slate-700">{{ row.label }}</p>
                <p class="text-xs text-slate-400">{{ row.detail }}</p>
              </div>
              <span class="text-sm font-semibold text-slate-700">{{ row.value }}</span>
            </div>
            <div class="h-2.5 overflow-hidden rounded-full bg-slate-100">
              <div
                class="h-full rounded-full transition-all"
                :class="barClass(row.percent)"
                :style="{ width: `${safePercent(row.percent)}%` }"
              />
            </div>
          </div>
        </div>
      </Card>

      <Card title="Status Layanan" subtitle="Koneksi utama aplikasi">
        <div class="divide-y divide-slate-100">
          <div v-for="service in services" :key="service.name" class="flex items-start gap-3 py-3 first:pt-0 last:pb-0">
            <span :class="['mt-1 h-2.5 w-2.5 shrink-0 rounded-full', serviceTone(service.status).dot]" />
            <div class="min-w-0 flex-1">
              <div class="flex items-center justify-between gap-3">
                <p class="text-sm font-semibold text-slate-700">{{ service.name }}</p>
                <p :class="['text-xs font-semibold', serviceTone(service.status).text]">{{ service.value }}</p>
              </div>
              <p class="mt-1 line-clamp-2 text-xs text-slate-400">{{ service.detail }}</p>
            </div>
          </div>
        </div>
      </Card>
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
      <Card title="Direktori Aplikasi" subtitle="Ukuran folder penting">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-100 text-sm">
            <thead>
              <tr class="text-left text-xs font-semibold uppercase text-slate-400">
                <th class="pb-3 pr-4">Folder</th>
                <th class="pb-3 pr-4">Ukuran</th>
                <th class="pb-3">Akses</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr v-for="directory in directories" :key="directory.path">
                <td class="py-3 pr-4">
                  <p class="font-semibold text-slate-700">{{ directory.label }}</p>
                  <p class="max-w-[360px] truncate text-xs text-slate-400">{{ directory.path }}</p>
                </td>
                <td class="py-3 pr-4 font-medium text-slate-700">{{ directory.size }}</td>
                <td class="py-3">
                  <span
                    :class="[
                      'inline-flex rounded-full border px-2 py-1 text-xs font-semibold',
                      directory.writable ? statusTone.ok.pill : statusTone.warning.pill,
                    ]"
                  >
                    {{ directory.writable ? 'Writable' : 'Read-only' }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </Card>

      <Card title="Runtime & Environment" subtitle="Konfigurasi server yang sedang aktif">
        <dl class="grid grid-cols-1 gap-x-6 gap-y-4 sm:grid-cols-2">
          <div v-for="item in runtime" :key="item.label">
            <dt class="text-xs font-semibold uppercase text-slate-400">{{ item.label }}</dt>
            <dd class="mt-1 break-words text-sm font-medium text-slate-700">{{ item.value }}</dd>
          </div>
          <div>
            <dt class="text-xs font-semibold uppercase text-slate-400">DB size</dt>
            <dd class="mt-1 text-sm font-medium text-slate-700">{{ database.size }}</dd>
          </div>
          <div>
            <dt class="text-xs font-semibold uppercase text-slate-400">Failed jobs 24 jam</dt>
            <dd class="mt-1 text-sm font-medium text-slate-700">{{ queue.failed_jobs_24h ?? 0 }}</dd>
          </div>
        </dl>
      </Card>
    </div>
  </div>
</template>
