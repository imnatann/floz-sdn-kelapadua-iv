import { VueRenderer } from '@tiptap/vue-3'
import tippy from 'tippy.js'
import CommandList from './CommandList.vue'

export default {
    items: ({ query }) => {
        return [
            {
                title: 'Heading 1',
                description: 'Big section heading.',
                icon: 'H1',
                command: ({ editor, range }) => {
                    editor
                        .chain()
                        .focus()
                        .deleteRange(range)
                        .setNode('heading', { level: 1 })
                        .run()
                },
            },
            {
                title: 'Heading 2',
                description: 'Medium section heading.',
                icon: 'H2',
                command: ({ editor, range }) => {
                    editor
                        .chain()
                        .focus()
                        .deleteRange(range)
                        .setNode('heading', { level: 2 })
                        .run()
                },
            },
            {
                title: 'Text',
                description: 'Just start writing with plain text.',
                icon: 'T',
                command: ({ editor, range }) => {
                    editor
                        .chain()
                        .focus()
                        .deleteRange(range)
                        .setParagraph()
                        .run()
                },
            },
            {
                title: 'Bullet List',
                description: 'Create a simple bulleted list.',
                icon: '•',
                command: ({ editor, range }) => {
                    editor
                        .chain()
                        .focus()
                        .deleteRange(range)
                        .toggleBulletList()
                        .run()
                },
            },
            {
                title: 'Ordered List',
                description: 'Create a list with numbering.',
                icon: '1.',
                command: ({ editor, range }) => {
                    editor
                        .chain()
                        .focus()
                        .deleteRange(range)
                        .toggleOrderedList()
                        .run()
                },
            },
            {
                title: 'Quote',
                description: 'Capture a quote.',
                icon: '❝',
                command: ({ editor, range }) => {
                    editor
                        .chain()
                        .focus()
                        .deleteRange(range)
                        .toggleBlockquote()
                        .run()
                },
            },
            {
                title: 'Divider',
                description: 'Visually divide content.',
                icon: '—',
                command: ({ editor, range }) => {
                    editor
                        .chain()
                        .focus()
                        .deleteRange(range)
                        .setHorizontalRule()
                        .run()
                },
            }
        ].filter(item => item.title.toLowerCase().startsWith(query.toLowerCase())).slice(0, 10)
    },

    render: () => {
        let component
        let popup

        return {
            onStart: props => {
                component = new VueRenderer(CommandList, {
                    props,
                    editor: props.editor,
                })

                if (!props.clientRect) {
                    return
                }

                popup = tippy('body', {
                    getReferenceClientRect: props.clientRect,
                    appendTo: () => document.body,
                    content: component.element,
                    showOnCreate: true,
                    interactive: true,
                    trigger: 'manual',
                    placement: 'bottom-start',
                })
            },

            onUpdate(props) {
                component.updateProps(props)

                if (!props.clientRect) {
                    return
                }

                popup[0].setProps({
                    getReferenceClientRect: props.clientRect,
                })
            },

            onKeyDown(props) {
                if (props.event.key === 'Escape') {
                    popup[0].hide()

                    return true
                }

                return component.ref?.onKeyDown(props)
            },

            onExit() {
                popup[0].destroy()
                component.destroy()
            },
        }
    },
}
