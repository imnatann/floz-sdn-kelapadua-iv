<script setup>
import { computed } from 'vue';
import { Head, Link, useForm } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormInput from '@/Components/UI/FormInput.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    academicYear: {
        type: Object,
        default: null,
    },
});

const isEditing = computed(() => !!props.academicYear);

const form = useForm({
    name: props.academicYear?.name ?? '',
    start_date: props.academicYear?.start_date ?? '',
    end_date: props.academicYear?.end_date ?? '',
});

function submit() {
    if (isEditing.value) {
        form.put(route('academic-years.update', props.academicYear.id));
    } else {
        form.post(route('academic-years.store'));
    }
}
</script>

<template>
    <Head :title="isEditing ? 'Edit Tahun Ajaran' : 'Tambah Tahun Ajaran'" />

    <div class="max-w-xl">
        <!-- Breadcrumb -->
        <div class="mb-4 flex items-center gap-2 text-sm text-slate-500">
            <Link :href="route('academic-years.index')" class="hover:text-orange-600">Tahun Ajaran</Link>
            <span>/</span>
            <span>{{ isEditing ? 'Edit' : 'Tambah' }}</span>
        </div>

        <h2 class="mb-6 text-xl font-bold text-slate-800">
            {{ isEditing ? 'Edit Tahun Ajaran' : 'Tambah Tahun Ajaran' }}
        </h2>

        <form @submit.prevent="submit" class="space-y-5 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Nama Tahun Ajaran</label>
                <FormInput
                    v-model="form.name"
                    type="text"
                    placeholder="Contoh: 2026/2027"
                    :error="form.errors.name"
                />
                <p v-if="form.errors.name" class="mt-1 text-sm text-red-600">{{ form.errors.name }}</p>
            </div>

            <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Tanggal Mulai</label>
                <FormInput
                    v-model="form.start_date"
                    type="date"
                    :error="form.errors.start_date"
                />
                <p v-if="form.errors.start_date" class="mt-1 text-sm text-red-600">{{ form.errors.start_date }}</p>
            </div>

            <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Tanggal Selesai</label>
                <FormInput
                    v-model="form.end_date"
                    type="date"
                    :error="form.errors.end_date"
                />
                <p v-if="form.errors.end_date" class="mt-1 text-sm text-red-600">{{ form.errors.end_date }}</p>
            </div>

            <div class="flex items-center gap-3 pt-2">
                <Button type="submit" :disabled="form.processing">
                    {{ isEditing ? 'Simpan Perubahan' : 'Buat Tahun Ajaran' }}
                </Button>
                <Link :href="route('academic-years.index')">
                    <Button type="button" variant="ghost">Batal</Button>
                </Link>
            </div>
        </form>
    </div>
</template>
