<script setup>
import { ref, computed, watch } from 'vue';
import { Link } from '@inertiajs/vue3';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Button from '@/Components/UI/Button.vue';

const props = defineProps({
    academicYears: { type: Array, default: () => [] },
    modelValue: { type: Object, required: true },
});

const emit = defineEmits(['update:modelValue', 'next']);

// Find active AY as default source
const activeAy = computed(() => props.academicYears.find(ay => ay.is_active));

const sourceAyId = ref(props.modelValue.sourceAyId ?? activeAy.value?.id ?? null);
const targetAyId = ref(props.modelValue.targetAyId ?? null);
const error = ref('');

const ayOptions = computed(() =>
    props.academicYears.map(ay => ({
        value: ay.id,
        label: ay.name + (ay.is_active ? ' (Aktif)' : ''),
    }))
);

const sourceOptions = computed(() => ayOptions.value);

const targetOptions = computed(() =>
    ayOptions.value.filter(o => o.value != sourceAyId.value)
);

// Warn if target already has students (we'll do a soft check based on flag if available)
const targetHasStudents = computed(() => {
    if (!targetAyId.value) return false;
    const ay = props.academicYears.find(a => a.id == targetAyId.value);
    return ay?.students_count > 0;
});

function validate() {
    error.value = '';
    if (!sourceAyId.value) {
        error.value = 'Pilih tahun ajaran sumber.';
        return false;
    }
    if (!targetAyId.value) {
        error.value = 'Pilih tahun ajaran tujuan.';
        return false;
    }
    if (sourceAyId.value == targetAyId.value) {
        error.value = 'Tahun ajaran sumber dan tujuan harus berbeda.';
        return false;
    }
    return true;
}

function handleNext() {
    if (!validate()) return;
    emit('update:modelValue', {
        ...props.modelValue,
        sourceAyId: Number(sourceAyId.value),
        targetAyId: Number(targetAyId.value),
    });
    emit('next');
}

// Keep sourceAyId updated when academicYears loads
watch(() => props.academicYears, (years) => {
    if (!sourceAyId.value) {
        const active = years.find(ay => ay.is_active);
        if (active) sourceAyId.value = active.id;
    }
}, { immediate: true });

// Reset target if same as source
watch(sourceAyId, () => {
    if (sourceAyId.value == targetAyId.value) targetAyId.value = null;
});
</script>

<template>
    <div>
        <h3 class="text-base font-semibold text-slate-800 mb-1">Langkah 1: Pilih Tahun Ajaran</h3>
        <p class="text-sm text-slate-500 mb-6">Tentukan tahun ajaran sumber dan tujuan untuk proses transisi.</p>

        <!-- Info box -->
        <div class="mb-6 flex gap-3 rounded-lg border border-blue-200 bg-blue-50 p-4">
            <svg class="h-5 w-5 text-blue-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-sm text-blue-700">
                Data tahun ajaran lama tidak akan dihapus. Proses ini hanya akan memindahkan siswa ke kelas baru di tahun ajaran tujuan.
            </p>
        </div>

        <div class="grid gap-5 sm:grid-cols-2">
            <!-- Source AY -->
            <div>
                <FormSelect
                    v-model="sourceAyId"
                    label="Dari Tahun Ajaran"
                    placeholder="Pilih tahun ajaran sumber"
                    :options="sourceOptions"
                    required
                />
            </div>

            <!-- Target AY -->
            <div>
                <FormSelect
                    v-model="targetAyId"
                    label="Ke Tahun Ajaran Baru"
                    placeholder="Pilih tahun ajaran tujuan"
                    :options="targetOptions"
                    required
                />
                <div class="mt-2">
                    <Link
                        href="/academic-years/create"
                        class="text-xs text-orange-600 hover:text-orange-700 hover:underline font-medium"
                    >
                        + Buat Tahun Ajaran Baru
                    </Link>
                </div>
            </div>
        </div>

        <!-- Warning: target has students -->
        <div v-if="targetHasStudents" class="mt-4 flex gap-3 rounded-lg border border-amber-200 bg-amber-50 p-4">
            <svg class="h-5 w-5 text-amber-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <p class="text-sm text-amber-700">
                Tahun ajaran tujuan sudah memiliki siswa. Sebaiknya pilih tahun ajaran yang masih kosong untuk menghindari duplikasi.
            </p>
        </div>

        <!-- Validation error -->
        <div v-if="error" class="mt-4 flex gap-3 rounded-lg border border-red-200 bg-red-50 p-4">
            <svg class="h-5 w-5 text-red-500 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <p class="text-sm text-red-700">{{ error }}</p>
        </div>

        <!-- Navigation -->
        <div class="mt-8 flex justify-end">
            <Button @click="handleNext">
                Lanjutkan
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
            </Button>
        </div>
    </div>
</template>
