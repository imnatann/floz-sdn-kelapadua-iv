<script setup>
import { ref, onMounted, watch } from 'vue';

const terminalBody = ref(null);
const lines = ref([
    { text: 'composer create-project floz/lms', type: 'command', typed: false },
]);

const isVisible = ref(false);

const startTyping = async () => {
    // Reset
    lines.value = [{ text: 'composer create-project floz/lms', type: 'command', typed: false }];
    
    // Simulate typing the first command
    const command = lines.value[0];
    const fullText = command.text;
    command.text = '';
    
    for (let i = 0; i < fullText.length; i++) {
        command.text += fullText[i];
        await new Promise(r => setTimeout(r, 50 + Math.random() * 30)); // Random typing speed
    }
    command.typed = true;

    // Simulate logs appearing
    const logs = [
        { text: 'Creating a "floz/lms" project at "./floz-lms"', type: 'info', delay: 300 },
        { text: 'Installing floz/lms (v1.0.0)', type: 'info', delay: 500 },
        { text: '- Downloading packages...', type: 'info', delay: 400 },
        { text: '- Installing dependencies...', type: 'info', delay: 800 },
        { text: '> @php artisan key:generate', type: 'command-output', delay: 600 },
        { text: 'Application ready! Build something amazing. 🚀', type: 'success', delay: 600 },
    ];

    for (const log of logs) {
        await new Promise(r => setTimeout(r, log.delay));
        lines.value.push(log);
        // Auto scroll
        if (terminalBody.value) {
            terminalBody.value.scrollTop = terminalBody.value.scrollHeight;
        }
    }
};

onMounted(() => {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting && !isVisible.value) {
                isVisible.value = true;
                setTimeout(startTyping, 500);
            }
        });
    }, { threshold: 0.5 });

    if (terminalBody.value) {
        observer.observe(terminalBody.value);
    }
});
</script>

<template>
    <section class="py-24 bg-[#09090b] text-white relative overflow-hidden">
        
        <!-- Background Glow -->
        <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-orange-500/10 rounded-full blur-[120px] pointer-events-none"></div>

        <div class="container mx-auto px-4 relative z-10">
            
            <div class="flex flex-col lg:flex-row items-center gap-12 lg:gap-20">
                
                <!-- Text Content -->
                <div class="flex-1 text-center lg:text-left">
                    <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-500/10 border border-orange-500/20 text-orange-400 text-xs font-mono mb-6">
                        <span class="w-2 h-2 rounded-full bg-orange-500 animate-pulse"></span>
                        OPEN SOURCE
                    </div>
                    <h2 class="text-4xl md:text-5xl font-bold mb-6 tracking-tight">
                        Deploy dalam hitungan <span class="text-transparent bg-clip-text bg-gradient-to-r from-orange-400 to-red-500">detik.</span>
                    </h2>
                    <p class="text-slate-400 text-lg mb-8 leading-relaxed">
                        Tidak ada vendor lock-in. Hosting di server mana saja. Full kontrol atas data dan infrastruktur sekolah Anda.
                    </p>
                    
                    <div class="flex flex-wrap justify-center lg:justify-start gap-4">
                        <a href="https://github.com/imnatann/floz-lms" target="_blank" class="px-6 py-3 rounded-lg bg-white text-black font-bold hover:bg-slate-200 transition-colors flex items-center gap-2">
                            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                            Star on GitHub
                        </a>
                        <a href="/docs" class="px-6 py-3 rounded-lg border border-slate-700 text-slate-300 hover:text-white hover:border-slate-500 transition-colors">
                            Baca Dokumentasi
                        </a>
                    </div>
                </div>

                <!-- Terminal Visual -->
                <div class="flex-1 w-full max-w-2xl" ref="terminalBody">
                    <div class="rounded-xl border border-slate-800 bg-[#1e1e1e] shadow-2xl overflow-hidden transition-all duration-700 transform"
                         :class="isVisible ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'">
                        
                        <!-- Terminal Header -->
                        <div class="px-4 py-3 bg-[#252526] border-b border-slate-800 flex items-center gap-2">
                            <div class="flex gap-2">
                                <div class="w-3 h-3 rounded-full bg-red-500/80"></div>
                                <div class="w-3 h-3 rounded-full bg-yellow-500/80"></div>
                                <div class="w-3 h-3 rounded-full bg-green-500/80"></div>
                            </div>
                            <div class="flex-1 text-center text-xs font-mono text-slate-500 pr-12">
                                bash — 80x24
                            </div>
                        </div>

                        <!-- Terminal Body -->
                        <div class="p-6 font-mono text-sm h-[320px] overflow-y-auto custom-scrollbar">
                            <div class="flex flex-col gap-1">
                                <div v-for="(line, index) in lines" :key="index" class="transition-opacity duration-300">
                                    
                                    <!-- Command Input -->
                                    <div v-if="line.type === 'command'" class="text-white flex gap-2">
                                        <span class="text-green-500 select-none">➜</span>
                                        <span class="text-cyan-400 select-none">~</span>
                                        <span>{{ line.text }}</span>
                                        <span v-if="index === lines.length - 1 && !line.typed" class="w-2 h-5 bg-slate-500 inline-block align-middle animate-pulse"></span>
                                    </div>

                                    <!-- Outputs -->
                                    <div v-else-if="line.type === 'info'" class="text-slate-400 pl-4">
                                        {{ line.text }}
                                    </div>

                                    <div v-else-if="line.type === 'command-output'" class="text-slate-500 pl-4">
                                        {{ line.text }}
                                    </div>

                                    <div v-else-if="line.type === 'success'" class="text-green-400 font-bold pl-4 mt-2">
                                        {{ line.text }}
                                    </div>

                                </div>
                                
                                <!-- Blinking Cursor at end -->
                                <div v-if="lines.length > 1 && lines[lines.length-1].type === 'success'" class="text-white flex gap-2 mt-2">
                                    <span class="text-green-500 select-none">➜</span>
                                    <span class="text-cyan-400 select-none">~</span>
                                    <span class="w-2 h-5 bg-slate-500 inline-block align-middle animate-pulse"></span>
                                </div>
                            </div>
                        </div>

                    </div>
                    
                    <!-- Reflection/Glow under terminal -->
                    <div class="w-[90%] mx-auto h-4 bg-orange-500/20 blur-xl mt-4 rounded-[100%] opacity-50"></div>
                </div>

            </div>
        </div>
    </section>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
    width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
    background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: #333;
    border-radius: 3px;
}
</style>
