<script setup>
import { onMounted, onUnmounted, ref } from 'vue';

const props = defineProps({
  count: {
    type: Number,
    default: 80
  },
  colors: {
    type: Array,
    default: () => ['#ea580c', '#f97316', '#fb923c', '#fdba74'] // Orange 600, 500, 400, 300
  }
});

const canvasRef = ref(null);
let ctx = null;
let animationFrameId = null;
let particles = [];
let mouse = { x: null, y: null };
let dimensions = { width: 0, height: 0 };

class Particle {
  constructor() {
    this.x = Math.random() * dimensions.width;
    this.y = Math.random() * dimensions.height;
    this.size = Math.random() * 4 + 1;
    this.speedX = Math.random() * 1 - 0.5;
    this.speedY = Math.random() * 1 - 0.5; // Upwards drift
    this.color = props.colors[Math.floor(Math.random() * props.colors.length)];
    this.baseX = this.x;
    this.baseY = this.y;
    this.density = (Math.random() * 30) + 1;
  }

  update() {
    // Mouse interaction (Antigravity repulsion)
    if (mouse.x != null) {
      let dx = mouse.x - this.x;
      let dy = mouse.y - this.y;
      let distance = Math.sqrt(dx * dx + dy * dy);
      let forceDirectionX = dx / distance;
      let forceDirectionY = dy / distance;
      let maxDistance = 150;
      let force = (maxDistance - distance) / maxDistance;
      let directionX = forceDirectionX * force * this.density;
      let directionY = forceDirectionY * force * this.density;

      if (distance < maxDistance) {
        this.x -= directionX;
        this.y -= directionY;
      }
    }

    // Natural movement
    this.x += this.speedX;
    this.y -= 0.5; // Constant upward float

    // Wrap around screen
    if (this.y < 0) {
      this.y = dimensions.height;
      this.x = Math.random() * dimensions.width;
    }
    if (this.x > dimensions.width) this.x = 0;
    if (this.x < 0) this.x = dimensions.width;
  }

  draw() {
    ctx.fillStyle = this.color;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();
  }
}

const init = () => {
    particles = [];
    for (let i = 0; i < props.count; i++) {
        particles.push(new Particle());
    }
}

const animate = () => {
    ctx.clearRect(0, 0, dimensions.width, dimensions.height);
    for (let i = 0; i < particles.length; i++) {
        particles[i].update();
        particles[i].draw();
    }
    animationFrameId = requestAnimationFrame(animate);
}

const handleResize = () => {
    if (canvasRef.value) {
        canvasRef.value.width = window.innerWidth;
        canvasRef.value.height = window.innerHeight;
        dimensions.width = window.innerWidth;
        dimensions.height = window.innerHeight;
        init();
    }
}

const handleMouseMove = (e) => {
    mouse.x = e.clientX;
    mouse.y = e.clientY;
}

const handleMouseLeave = () => {
    mouse.x = null;
    mouse.y = null;
}

onMounted(() => {
    if (canvasRef.value) {
        ctx = canvasRef.value.getContext('2d');
        canvasRef.value.width = window.innerWidth;
        canvasRef.value.height = window.innerHeight;
        dimensions.width = window.innerWidth;
        dimensions.height = window.innerHeight;
        
        init();
        animate();
        
        window.addEventListener('resize', handleResize);
        window.addEventListener('mousemove', handleMouseMove);
        window.addEventListener('mouseleave', handleMouseLeave);
    }
});

onUnmounted(() => {
    window.removeEventListener('resize', handleResize);
    window.removeEventListener('mousemove', handleMouseMove);
    window.removeEventListener('mouseleave', handleMouseLeave);
    cancelAnimationFrame(animationFrameId);
});
</script>

<template>
  <canvas ref="canvasRef" class="fixed inset-0 z-0 pointer-events-none block"></canvas>
</template>
