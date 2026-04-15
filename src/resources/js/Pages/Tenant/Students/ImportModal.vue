<script setup>
import { ref } from 'vue';
import { useForm } from '@inertiajs/vue3';
import Modal from '@/Components/UI/Modal.vue';
import Button from '@/Components/UI/Button.vue';

const props = defineProps({
    show: Boolean,
});

const emit = defineEmits(['close']);

const form = useForm({
    file: null,
});

const fileInput = ref(null);

const submit = () => {
    form.post('/students/import', {
        onSuccess: () => {
            form.reset();
            emit('close'); 
        },
    });
};

const close = () => {
    form.reset();
    form.clearErrors();
    emit('close');
}
</script>

<template>
    <Modal :show="show" @close="close" maxWidth="md">
        <div class="p-6">
            <h2 class="text-lg font-medium text-slate-900">Import Siswa</h2>
            <p class="mt-1 text-sm text-slate-500">
                Upload file Excel/CSV berisi data siswa. Pastikan format sesuai template.
            </p>

            <div class="mt-6 space-y-4">
                <a href="/students/template" class="flex items-center gap-2 text-sm font-medium text-emerald-600 hover:text-emerald-700">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                    Download Template CSV
                </a>

                <div class="space-y-1">
                    <label class="block text-sm font-medium text-slate-700">File Excel/CSV</label>
                    <input
                        ref="fileInput"
                        type="file"
                        accept=".xlsx,.xls,.csv"
                        class="block w-full text-sm text-slate-500 rounded-lg border border-slate-300 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-emerald-50 file:text-emerald-700 hover:file:bg-emerald-100"
                        @input="form.file = $event.target.files[0]"
                    />
                    <p v-if="form.errors.file" class="text-xs text-red-600 mt-1" v-html="form.errors.file"></p>
                </div>
            </div>

            <div class="mt-6 flex justify-end gap-3">
                <Button variant="secondary" @click="close">Batal</Button>
                <Button @click="submit" :loading="form.processing" :disabled="!form.file">Import</Button>
            </div>
        </div>
    </Modal>
</template>
