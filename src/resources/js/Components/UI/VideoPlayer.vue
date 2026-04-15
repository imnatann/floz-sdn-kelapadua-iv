<script setup>
import { ref, watch, onMounted } from 'vue';

const props = defineProps({
    src: {
        type: String,
        required: true
    },
    poster: {
        type: String,
        default: ''
    },
    quizzes: {
        type: Array,
        default: () => []
    },
    autoplay: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['quiz-answered', 'video-ended', 'timeupdate']);

const videoRef = ref(null);
const currentQuiz = ref(null);
const answeredQuizzes = ref(new Set());
const selectedAnswer = ref(null);
const isCorrect = ref(null);
const errorFeedback = ref('');

const checkQuizzes = () => {
    if (!videoRef.value || currentQuiz.value) return;
    
    const currentTime = videoRef.value.currentTime;
    
    // Temukan kuis yang belum dijawab yang berada dalam window waktu +/- 0.5 detik
    const upcomingQuiz = props.quizzes.find(q => 
        !answeredQuizzes.value.has(q.id) && 
        currentTime >= q.time && 
        currentTime < q.time + 1
    );

    if (upcomingQuiz) {
        currentQuiz.value = upcomingQuiz;
        videoRef.value.pause();
        
        // Riset state jawaban untuk kuis yang baru ini
        selectedAnswer.value = null;
        isCorrect.value = null;
        errorFeedback.value = '';
    }
};

const handleTimeUpdate = (e) => {
    emit('timeupdate', e.target.currentTime);
    checkQuizzes();
};

const handleVideoEnded = () => {
    emit('video-ended');
};

const submitAnswer = () => {
    if (selectedAnswer.value === null) {
        errorFeedback.value = 'Silakan pilih salah satu jawaban!';
        return;
    }

    if (selectedAnswer.value === currentQuiz.value.correctAnswerIndex) {
        isCorrect.value = true;
        errorFeedback.value = '';
        
        // Tandai sebagai sudah dijawab
        answeredQuizzes.value.add(currentQuiz.value.id);
        emit('quiz-answered', { quizId: currentQuiz.value.id, correct: true, answer: selectedAnswer.value });
        
        // Lanjutkan video secara otomatis setelah jeda sejenak
        setTimeout(() => {
            currentQuiz.value = null;
            selectedAnswer.value = null;
            isCorrect.value = null;
            if (videoRef.value) {
                videoRef.value.play();
            }
        }, 1500);
    } else {
        isCorrect.value = false;
        errorFeedback.value = 'Jawaban kurang tepat. Coba lagi!';
        emit('quiz-answered', { quizId: currentQuiz.value.id, correct: false, answer: selectedAnswer.value });
    }
};

// Metode yang dapat diakses dari komponen induk
const play = () => videoRef.value?.play();
const pause = () => videoRef.value?.pause();
const seekTo = (time) => {
    if (videoRef.value) {
        videoRef.value.currentTime = time;
    }
};

defineExpose({
    play,
    pause,
    seekTo,
    videoRef
});
</script>

<template>
    <div class="relative w-full rounded-2xl overflow-hidden bg-slate-900 group shadow-md border border-slate-200">
        
        <!-- Native Video Element -->
        <video 
            ref="videoRef"
            :src="src"
            :poster="poster"
            class="w-full h-auto aspect-video object-contain bg-black"
            controls
            controlsList="nodownload"
            :autoplay="autoplay"
            @timeupdate="handleTimeUpdate"
            @ended="handleVideoEnded"
        ></video>

        <!-- Quiz Overlay Backdrop -->
        <transition name="fade">
            <div 
                v-if="currentQuiz" 
                class="absolute inset-0 z-20 flex items-center justify-center bg-slate-900/80 backdrop-blur-sm p-4 md:p-8"
            >
                <!-- Quiz Card -->
                <transition name="slide-up" appear>
                    <div class="floz-card w-full max-w-lg bg-white overflow-hidden shadow-2xl transition-all">
                        <div class="p-6 md:p-8">
                            
                            <!-- Header -->
                            <div class="mb-5 flex items-center justify-between">
                                <span class="inline-flex items-center gap-1.5 py-1 px-3 rounded-full text-xs font-semibold text-orange-700 bg-orange-100">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="10"></circle>
                                        <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                                    </svg>
                                    Kuis Video
                                </span>
                            </div>

                            <!-- Question -->
                            <h3 class="text-xl md:text-2xl font-bold text-slate-900 leading-snug mb-6">
                                {{ currentQuiz.question }}
                            </h3>

                            <!-- Options Form -->
                            <div class="space-y-3 mb-6">
                                <label 
                                    v-for="(option, idx) in currentQuiz.options" 
                                    :key="idx"
                                    class="flex items-center p-4 rounded-xl border-2 cursor-pointer transition-all duration-200 group"
                                    :class="[
                                        selectedAnswer === idx ? 'border-orange-500 bg-orange-50' : 'border-slate-200 hover:border-orange-300 hover:bg-slate-50',
                                        isCorrect === false && selectedAnswer === idx ? 'border-red-500 bg-red-50 !opacity-100' : '',
                                        isCorrect === true && selectedAnswer === idx ? 'border-green-500 bg-green-50 !opacity-100' : '',
                                        isCorrect === true && selectedAnswer !== idx ? 'opacity-50 pointer-events-none' : ''
                                    ]"
                                >
                                    <input 
                                        type="radio" 
                                        :name="'quiz-option-' + currentQuiz.id" 
                                        :value="idx" 
                                        v-model="selectedAnswer"
                                        class="radio radio-primary radio-sm mr-4 text-orange-600 focus:ring-orange-500"
                                        :disabled="isCorrect === true"
                                    />
                                    <span 
                                        class="text-slate-700 font-medium text-base select-none"
                                        :class="{
                                            'text-green-800 font-bold': isCorrect === true && selectedAnswer === idx,
                                            'text-red-800 font-bold': isCorrect === false && selectedAnswer === idx,
                                            'text-orange-900 font-bold': selectedAnswer === idx && isCorrect === null
                                        }"
                                    >
                                        {{ option }}
                                    </span>
                                </label>
                            </div>

                            <!-- Feedback Messages -->
                            <div class="h-6 mb-4 flex items-center justify-end">
                                <transition name="fade">
                                    <div v-if="errorFeedback && isCorrect !== true" class="text-red-600 text-sm font-semibold flex items-center gap-1.5">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                                        </svg>
                                        {{ errorFeedback }}
                                    </div>
                                    <div v-else-if="isCorrect === true" class="text-green-600 text-sm font-semibold flex items-center gap-1.5">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                                        </svg>
                                        Tepat sekali! Melanjutkan video...
                                    </div>
                                </transition>
                            </div>

                            <!-- Submit Action -->
                            <div class="flex justify-end pt-2 border-t border-slate-100">
                                <button 
                                    @click="submitAnswer" 
                                    :disabled="isCorrect === true || selectedAnswer === null"
                                    class="bg-orange-600 hover:bg-orange-700 disabled:bg-slate-300 disabled:cursor-not-allowed text-white px-6 py-2.5 rounded-xl font-semibold shadow-sm transition-colors duration-200 flex items-center gap-2"
                                >
                                    Jawab
                                    <svg v-if="isCorrect !== true" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                                        <path fill-rule="evenodd" d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z" clip-rule="evenodd" />
                                    </svg>
                                </button>
                            </div>

                        </div>
                    </div>
                </transition>
            </div>
        </transition>

    </div>
</template>

<style scoped>
/* Transisi untuk Overlay Kuis */
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active {
    transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.slide-up-enter-from,
.slide-up-leave-to {
    opacity: 0;
    transform: translateY(20px) scale(0.95);
}
</style>
