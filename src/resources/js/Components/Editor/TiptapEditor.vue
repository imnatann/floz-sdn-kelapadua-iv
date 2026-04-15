<script setup>
import { useEditor, EditorContent } from '@tiptap/vue-3'
import { BubbleMenu, FloatingMenu } from '@tiptap/vue-3/menus'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import Link from '@tiptap/extension-link'
import TextAlign from '@tiptap/extension-text-align'
import Placeholder from '@tiptap/extension-placeholder'
import BubbleMenuExtension from '@tiptap/extension-bubble-menu' 
import FloatingMenuExtension from '@tiptap/extension-floating-menu'
import { Extension } from '@tiptap/core'
import Suggestion from '@tiptap/suggestion'
import { watch, onBeforeUnmount } from 'vue'
import suggestion from './suggestion.js'

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: "Type '/' for commands...",
  },
})

const emit = defineEmits(['update:modelValue'])

const Commands = Extension.create({
  name: 'slash-commands',

  addOptions() {
    return {
      suggestion: {
        char: '/',
        command: ({ editor, range, props }) => {
          props.command({ editor, range })
        },
      },
    }
  },

  addProseMirrorPlugins() {
    return [
      Suggestion({
        editor: this.editor,
        ...this.options.suggestion,
      }),
    ]
  },
})

const editor = useEditor({
  extensions: [
    StarterKit,
    Underline,
    Link.configure({
      openOnClick: false,
    }),
    TextAlign.configure({
      types: ['heading', 'paragraph'],
    }),
    Placeholder.configure({
      placeholder: props.placeholder,
    }),
    BubbleMenuExtension, 
    FloatingMenuExtension,
    Commands.configure({
        suggestion: suggestion
    }),
  ],
  content: props.modelValue,
  onUpdate: () => {
    emit('update:modelValue', editor.value.getHTML())
  },
  editorProps: {
    attributes: {
      class: 'prose prose-sm sm:prose-base lg:prose-lg xl:prose-xl max-w-none focus:outline-none min-h-[150px] prose-headings:font-bold prose-headings:text-slate-800 prose-p:text-slate-600 prose-a:text-orange-600 prose-a:no-underline hover:prose-a:underline',
    },
  },
})

watch(() => props.modelValue, (value) => {
  if (!editor.value) return
  const isSame = editor.value.getHTML() === value
  if (isSame) {
    return
  }
  editor.value.commands.setContent(value, false)
})

onBeforeUnmount(() => {
  if (editor.value) {
      editor.value.destroy()
  }
})
</script>

<template>
  <div v-if="editor" class="relative group">
      
    <!-- Bubble Menu (Text Selection) - Dark Theme -->
    <bubble-menu
        class="flex items-center gap-1 p-1 bg-slate-800 rounded-lg shadow-xl border border-slate-700 overflow-hidden"
        :tippy-options="{ duration: 100 }"
        :editor="editor"
    >
        <button 
            @click="editor.chain().focus().toggleBold().run()" 
            :class="{ 'bg-slate-700 text-white': editor.isActive('bold'), 'text-slate-300 hover:bg-slate-700 hover:text-white': !editor.isActive('bold') }"
            class="p-1.5 rounded transition-colors text-sm font-medium"
        >
            Bold
        </button>
        <button 
            @click="editor.chain().focus().toggleItalic().run()" 
            :class="{ 'bg-slate-700 text-white': editor.isActive('italic'), 'text-slate-300 hover:bg-slate-700 hover:text-white': !editor.isActive('italic') }"
            class="p-1.5 rounded transition-colors text-sm font-medium"
        >
            Italic
        </button>
        <button 
            @click="editor.chain().focus().toggleUnderline().run()" 
            :class="{ 'bg-slate-700 text-white': editor.isActive('underline'), 'text-slate-300 hover:bg-slate-700 hover:text-white': !editor.isActive('underline') }"
            class="p-1.5 rounded transition-colors text-sm font-medium"
        >
            Underline
        </button>
        <div class="w-px h-4 bg-slate-600 mx-1"></div>
        <button 
            @click="editor.chain().focus().toggleHeading({ level: 1 }).run()" 
            :class="{ 'bg-slate-700 text-white': editor.isActive('heading', { level: 1 }), 'text-slate-300 hover:bg-slate-700 hover:text-white': !editor.isActive('heading', { level: 1 }) }"
            class="p-1.5 rounded transition-colors text-sm font-bold"
        >
            H1
        </button>
        <button 
            @click="editor.chain().focus().toggleHeading({ level: 2 }).run()" 
            :class="{ 'bg-slate-700 text-white': editor.isActive('heading', { level: 2 }), 'text-slate-300 hover:bg-slate-700 hover:text-white': !editor.isActive('heading', { level: 2 }) }"
            class="p-1.5 rounded transition-colors text-sm font-bold"
        >
            H2
        </button>
    </bubble-menu>

    <!-- Floating Menu (Empty Line) -->
    <floating-menu
        class="flex items-center gap-1 -ml-7"
        :tippy-options="{ duration: 100 }"
        :editor="editor"
    >
        <button 
            @click="editor.chain().focus().toggleHeading({ level: 1 }).run()"
            class="p-1 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-md transition-colors"
            title="Heading 1"
        >
            H1
        </button>
        <button 
            @click="editor.chain().focus().toggleBulletList().run()"
            class="p-1 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-md transition-colors"
            title="Bullet List"
        >
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6"></line><line x1="8" y1="12" x2="21" y2="12"></line><line x1="8" y1="18" x2="21" y2="18"></line><line x1="3" y1="6" x2="3.01" y2="6"></line><line x1="3" y1="12" x2="3.01" y2="12"></line><line x1="3" y1="18" x2="3.01" y2="18"></line></svg>
        </button>
    </floating-menu>

    <!-- Editor Content -->
    <!-- Removed border and shadow for seamless look -->
    <div class="min-h-[150px] cursor-text transition-all rounded-lg">
         <editor-content :editor="editor" />
    </div>
  </div>
</template>

<style>
/* Typography improvements */
.ProseMirror p.is-editor-empty:first-child::before {
  color: #94a3b8; /* slate-400 */
  content: attr(data-placeholder);
  float: left;
  height: 0;
  pointer-events: none;
}

/* Remove default focus outline */
.ProseMirror:focus {
    outline: none;
}
</style>
