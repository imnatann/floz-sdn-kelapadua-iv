<script setup>
import { Head } from '@inertiajs/vue3';
import DocsLayout from '@/Layouts/DocsLayout.vue';

const copyCode = (code) => {
    navigator.clipboard.writeText(code);
    // Simple toast or alert could be added here
};
</script>

<template>
    <DocsLayout>
        <Head title="Documentation" />

        <div class="prose prose-invert prose-orange max-w-none">
            
            <!-- Introduction -->
            <span class="text-orange-500 font-mono text-sm font-bold tracking-wider uppercase mb-2 block">Documentation</span>
            <h1 class="text-4xl md:text-5xl font-extrabold text-white mb-6">Introduction</h1>
            
            <p class="text-xl text-slate-400 leading-relaxed mb-8">
                FLOZ adalah platform manajemen sekolah (LMS) modern yang dirancang untuk kecepatan, fleksibilitas, dan pengalaman developer yang tak tertandingi.
                Dibangun di atas raksasa: <strong>Laravel</strong>, <strong>Vue.js</strong>, dan <strong>Tailwind CSS</strong>.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 my-12 not-prose">
                <div class="p-6 rounded-2xl bg-slate-900 border border-slate-800 hover:border-orange-500/50 transition-colors group">
                    <div class="w-10 h-10 rounded-full bg-orange-500/10 flex items-center justify-center text-orange-500 mb-4 group-hover:bg-orange-500 group-hover:text-white transition-all">
                        🚀
                    </div>
                    <h3 class="text-lg font-bold text-white mb-2">High Performance</h3>
                    <p class="text-slate-400 text-sm">Dioptimalkan untuk menangani ribuan siswa dengan caching cerdas dan query yang efisien.</p>
                </div>
                <div class="p-6 rounded-2xl bg-slate-900 border border-slate-800 hover:border-purple-500/50 transition-colors group">
                    <div class="w-10 h-10 rounded-full bg-purple-500/10 flex items-center justify-center text-purple-500 mb-4 group-hover:bg-purple-500 group-hover:text-white transition-all">
                        🎨
                    </div>
                    <h3 class="text-lg font-bold text-white mb-2">Beautiful UI</h3>
                    <p class="text-slate-400 text-sm">Antarmuka gelap yang elegan, responsif, dan memanjakan mata pengguna.</p>
                </div>
            </div>

            <hr class="border-slate-800 my-12" />

            <!-- Installation -->
            <h2 id="installation" class="text-3xl font-bold text-white scroll-mt-24">Installation</h2>
            
            <h3 class="text-xl font-bold text-white mt-8 mb-4">Prerequisites</h3>
            <ul class="list-disc list-inside text-slate-400 mb-6 space-y-2">
                <li><strong class="text-slate-200">PHP 8.2+</strong> with Extensions (BCMath, Ctype, JSON, Mbstring, OpenSSL, PDO, Tokenizer, XML)</li>
                <li><strong class="text-slate-200">Composer 2.x</strong></li>
                <li><strong class="text-slate-200">Node.js 18+</strong> & NPM</li>
                <li><strong class="text-slate-200">MySQL 8.0+</strong> or PostgreSQL 14+</li>
            </ul>

            <h3 class="text-xl font-bold text-white mt-8 mb-4">1. Create Project</h3>
            <p>Clone repository atau buat project baru menggunakan Composer:</p>

            <div class="not-prose my-6 relative group">
                <div class="absolute -inset-1 bg-gradient-to-r from-orange-500 to-purple-600 rounded-lg blur opacity-25 group-hover:opacity-50 transition duration-1000"></div>
                <div class="relative bg-[#1e1e1e] rounded-lg p-4 font-mono text-sm text-slate-300 border border-slate-800 overflow-x-auto">
                    <div class="flex justify-between items-center mb-2 text-xs text-slate-500">
                        <span>Terminal</span>
                        <button @click="copyCode('composer create-project floz/lms')" class="hover:text-white transition-colors">Copy</button>
                    </div>
                    <span class="text-green-400">$</span> composer create-project floz/lms
                </div>
            </div>

            <h3 class="text-xl font-bold text-white mt-8 mb-4">2. Setup Environment</h3>
            <p>Salin file <code>.env.example</code> menjadi <code>.env</code> dan konfigurasi database:</p>

            <div class="not-prose my-6 bg-[#1e1e1e] rounded-lg p-4 font-mono text-sm text-slate-300 border border-slate-800">
                <div><span class="text-green-400">$</span> cp .env.example .env</div>
                <div><span class="text-green-400">$</span> php artisan key:generate</div>
                <div><span class="text-green-400">$</span> php artisan migrate --seed</div>
            </div>

            <h3 class="text-xl font-bold text-white mt-8 mb-4">3. Frontend Assets</h3>
            <p>Install dependencies Node.js dan jalankan server development Vite:</p>
            
            <div class="not-prose my-6 bg-[#1e1e1e] rounded-lg p-4 font-mono text-sm text-slate-300 border border-slate-800">
                <div><span class="text-green-400">$</span> npm install</div>
                <div><span class="text-green-400">$</span> npm run dev</div>
            </div>

            <hr class="border-slate-800 my-12" />

            <!-- Configuration -->
            <h2 id="configuration" class="text-3xl font-bold text-white scroll-mt-24">Configuration</h2>
            <p class="mb-6">
                Konfigurasi utama FLOZ terdapat di file <code>.env</code>. Berikut adalah beberapa variabel kunci yang perlu diperhatikan:
            </p>

            <div class="not-prose overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="border-b border-slate-800 text-slate-200">
                            <th class="py-3 px-4">Key</th>
                            <th class="py-3 px-4">Description</th>
                            <th class="py-3 px-4">Default</th>
                        </tr>
                    </thead>
                    <tbody class="text-sm font-mono text-slate-400">
                        <tr class="border-b border-slate-800/50">
                            <td class="py-3 px-4 text-orange-400">APP_URL</td>
                            <td class="py-3 px-4">URL utama aplikasi</td>
                            <td class="py-3 px-4 text-slate-600">http://localhost</td>
                        </tr>
                        <tr class="border-b border-slate-800/50">
                            <td class="py-3 px-4 text-orange-400">DB_CONNECTION</td>
                            <td class="py-3 px-4">Koneksi database (mysql/pgsql)</td>
                            <td class="py-3 px-4 text-slate-600">mysql</td>
                        </tr>
                        <tr class="border-b border-slate-800/50">
                            <td class="py-3 px-4 text-orange-400">Central_DOMAIN</td>
                            <td class="py-3 px-4">Domain utama untuk multi-tenancy</td>
                            <td class="py-3 px-4 text-slate-600">floz.test</td>
                        </tr>
                    </tbody>
                </table>
            </div>

             <blockquote class="border-l-4 border-orange-500 bg-orange-500/10 pl-4 py-2 my-6 not-italic text-slate-300 rounded-r-lg">
                <p class="font-bold text-orange-400 mb-1">Penting</p>
                Pastikan <code>APP_URL</code> sesuai dengan domain yang Anda gunakan saat deployment production.
            </blockquote>

            <hr class="border-slate-800 my-12" />

            <!-- Directory Structure -->
            <h2 id="structure" class="text-3xl font-bold text-white scroll-mt-24">Directory Structure</h2>
            <p class="mb-6">
                FLOZ mengikuti struktur standar Laravel dengan beberapa penyesuaian untuk arsitektur multi-tenant.
            </p>

            <div class="not-prose bg-[#0d1117] border border-slate-800 rounded-xl p-6 font-mono text-sm text-slate-400 overflow-x-auto">
<pre class="whitespace-pre">
floz/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── <span class="text-orange-400">Platform/</span>       <span class="text-slate-600">// Controller untuk Admin Pusat</span>
│   │   │   └── <span class="text-purple-400">Tenant/</span>         <span class="text-slate-600">// Controller untuk Sekolah Users</span>
│   │   └── Middleware/
│   └── Models/
├── config/
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/
│   └── js/
│       ├── <span class="text-blue-400">Components/</span>
│       ├── <span class="text-blue-400">Layouts/</span>
│       └── <span class="text-blue-400">Pages/</span>
└── routes/
    ├── <span class="text-green-400">web.php</span>             <span class="text-slate-600">// Routing Landing & Platform</span>
    └── <span class="text-green-400">tenant.php</span>          <span class="text-slate-600">// Routing untuk subdomain Sekolah</span>
</pre>
            </div>

        </div>
    </DocsLayout>
</template>
