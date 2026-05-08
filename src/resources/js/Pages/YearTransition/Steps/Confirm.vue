<script setup>
import { ref, computed } from 'vue';
import { router } from '@inertiajs/vue3';
import Button from '@/Components/UI/Button.vue';

const props = defineProps({
    modelValue: { type: Object, required: true },
});

const emit = defineEmits(['update:modelValue', 'back']);

const confirmWord = ref('');
const isSubmitting = ref(false);
const submitError = ref('');

const plan = computed(() => props.modelValue.plan);
const summary = computed(() => plan.value?.summary || { promoted: 0, graduated: 0, retained: 0, excluded: 0 });
// W-04: use server-side SHA-256 plan_hash from preview response (not client djb2)
const planHash = computed(() => plan.value?.plan_hash ?? null);

const canExecute = computed(() => confirmWord.value === 'TERAPKAN' && !isSubmitting.value);

function handleExecute() {
    if (!canExecute.value) return;
    isSubmitting.value = true;
    submitError.value = '';

    router.post('/year-transition/execute', {
        source_academic_year_id: props.modelValue.sourceAyId,
        target_academic_year_id: props.modelValue.targetAyId,
        overrides: props.modelValue.overrides || {},
        confirmation_word: confirmWord.value,
        plan_hash: planHash.value,
    }, {
        onSuccess: (page) => {
            // Inertia redirect will be handled by server flash
            isSubmitting.value = false;
        },
        onError: (errors) => {
            isSubmitting.value = false;
            if (errors.message) {
                submitError.value = errors.message;
            } else {
                submitError.value = 'Terjadi kesalahan. Silakan coba lagi.';
            }
        },
        onFinish: () => {
            isSubmitting.value = false;
        },
    });
}
</script>

<template>
    <div>
        <h3 class="text-base font-semibold text-slate-800 mb-1">Langkah 5: Konfirmasi & Terapkan</h3>
        <p class="text-sm text-slate-500 mb-6">Tinjau ringkasan akhir sebelum menerapkan transisi tahun ajaran.</p>

        <!-- Critical warning -->
        <div class="mb-6 flex gap-3 rounded-xl border-2 border-red-300 bg-red-50 p-5">
            <svg class="h-6 w-6 text-red-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div>
                <p class="font-semibold text-red-800 mb-1">Tindakan Tidak Dapat Dibatalkan</p>
                <p class="text-sm text-red-700">
                    Proses ini tidak dapat dibatalkan secara otomatis tanpa intervensi admin database.
                    Pastikan Anda telah me-review semua perubahan di langkah sebelumnya sebelum melanjutkan.
                </p>
            </div>
        </div>

        <!-- Summary stats -->
        <div v-if="plan" class="mb-6">
            <h4 class="text-sm font-semibold text-slate-600 mb-3">Ringkasan Perubahan</h4>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div class="rounded-lg border border-emerald-200 bg-emerald-50 p-3 text-center">
                    <div class="text-2xl font-bold text-emerald-600">{{ summary.promoted }}</div>
                    <div class="text-xs text-emerald-700 mt-0.5">Naik Kelas</div>
                </div>
                <div class="rounded-lg border border-blue-200 bg-blue-50 p-3 text-center">
                    <div class="text-2xl font-bold text-blue-600">{{ summary.graduated }}</div>
                    <div class="text-xs text-blue-700 mt-0.5">Lulus</div>
                </div>
                <div class="rounded-lg border border-amber-200 bg-amber-50 p-3 text-center">
                    <div class="text-2xl font-bold text-amber-600">{{ summary.retained }}</div>
                    <div class="text-xs text-amber-700 mt-0.5">Tinggal Kelas</div>
                </div>
                <div class="rounded-lg border border-slate-200 bg-slate-50 p-3 text-center">
                    <div class="text-2xl font-bold text-slate-500">{{ summary.excluded }}</div>
                    <div class="text-xs text-slate-500 mt-0.5">Dikecualikan</div>
                </div>
            </div>

            <!-- Plan hash -->
            <div v-if="planHash" class="mt-4 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
                <p class="text-xs text-slate-500 font-mono">
                    <span class="font-sans font-semibold text-slate-600 mr-2">Plan Hash:</span>
                    {{ planHash }}
                </p>
                <p class="text-xs text-slate-400 mt-1">Gunakan kode ini untuk verifikasi snapshot rencana di log audit.</p>
            </div>
        </div>

        <!-- Missing plan warning -->
        <div v-if="!plan" class="mb-6 flex gap-3 rounded-lg border border-amber-200 bg-amber-50 p-4">
            <svg class="h-5 w-5 text-amber-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <p class="text-sm text-amber-700">
                Preview belum dibuat. Kembali ke langkah sebelumnya untuk membuat preview terlebih dahulu.
            </p>
        </div>

        <!-- Type confirm -->
        <div class="mb-6">
            <label class="block text-sm font-medium text-slate-700 mb-2">
                Ketik kata <span class="font-mono font-bold text-red-600 bg-red-50 px-1.5 py-0.5 rounded">TERAPKAN</span> untuk mengaktifkan tombol konfirmasi
            </label>
            <input
                v-model="confirmWord"
                type="text"
                placeholder="Ketik TERAPKAN"
                autocomplete="off"
                :disabled="isSubmitting"
                class="w-full sm:max-w-xs rounded-lg border-2 px-4 py-2.5 text-sm font-mono transition-all focus:outline-none focus:ring-2 focus:ring-offset-1"
                :class="confirmWord === 'TERAPKAN'
                    ? 'border-emerald-400 bg-emerald-50 text-emerald-800 focus:ring-emerald-300'
                    : 'border-slate-300 focus:border-red-400 focus:ring-red-200'"
            />
        </div>

        <!-- Submit error -->
        <div v-if="submitError" class="mb-4 flex gap-3 rounded-lg border border-red-200 bg-red-50 p-4">
            <svg class="h-5 w-5 text-red-500 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <p class="text-sm text-red-700">{{ submitError }}</p>
        </div>

        <!-- Navigation -->
        <div class="mt-8 flex flex-col sm:flex-row justify-between gap-3">
            <Button variant="outline" @click="$emit('back')" :disabled="isSubmitting">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Sebelumnya
            </Button>

            <Button
                @click="handleExecute"
                :disabled="!canExecute"
                :loading="isSubmitting"
                variant="danger"
                size="lg"
            >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                Konfirmasi &amp; Terapkan Transisi
            </Button>
        </div>
    </div>
</template>
