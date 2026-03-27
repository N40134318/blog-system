<script setup lang="ts">
import { computed, nextTick, watch } from 'vue'
import { renderMarkdown, renderMermaid } from '~/composables/useMarkdown'

definePageMeta({
  middleware: 'auth'
})

const title = ref('')
const content = ref('')
const category = ref('')
const tags = ref('')
const coverImage = ref('')
const successMessage = ref('')
const errorMessage = ref('')
const uploadMessage = ref('')
const bodyImageMessage = ref('')
const uploading = ref(false)
const uploadingBodyImage = ref(false)
const submittingAction = ref<'draft' | 'published' | ''>('')
const selectedFile = ref<File | null>(null)
const selectedFileName = ref('')
const selectedBodyImageFile = ref<File | null>(null)
const selectedBodyImageFileName = ref('')

const api = useApi()

const editorRef = ref<HTMLTextAreaElement | null>(null)
const previewRef = ref<HTMLDivElement | null>(null)

const syncPreviewScroll = () => {
  const editor = editorRef.value
  const preview = previewRef.value

  if (!editor || !preview) return

  const editorScrollRange = editor.scrollHeight - editor.clientHeight
  const previewScrollRange = preview.scrollHeight - preview.clientHeight

  if (editorScrollRange <= 0 || previewScrollRange <= 0) {
    preview.scrollTop = 0
    return
  }

  const scrollRatio = editor.scrollTop / editorScrollRange
  preview.scrollTop = scrollRatio * previewScrollRange
}

const replaceSelection = async (
  before: string,
  after = '',
  placeholder = ''
) => {
  const textarea = editorRef.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const currentValue = content.value
  const selectedText = currentValue.slice(start, end)
  const insertText = selectedText || placeholder

  const newText =
    currentValue.slice(0, start) +
    before +
    insertText +
    after +
    currentValue.slice(end)

  content.value = newText

  await nextTick()
  textarea.focus()

  const selectionStart = start + before.length
  const selectionEnd = selectionStart + insertText.length
  textarea.setSelectionRange(selectionStart, selectionEnd)
}

const insertBlock = async (text: string) => {
  const textarea = editorRef.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const currentValue = content.value

  const prefix = start > 0 && currentValue[start - 1] !== '\n' ? '\n' : ''
  const suffix = end < currentValue.length && currentValue[end] !== '\n' ? '\n' : ''

  const newText =
    currentValue.slice(0, start) +
    prefix +
    text +
    suffix +
    currentValue.slice(end)

  content.value = newText

  await nextTick()
  textarea.focus()

  const cursor = start + prefix.length + text.length
  textarea.setSelectionRange(cursor, cursor)
}

const insertTextAtCursor = async (text: string) => {
  const textarea = editorRef.value
  if (!textarea) {
    content.value += text
    return
  }

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const currentValue = content.value

  const prefix = start > 0 && currentValue[start - 1] !== '\n' ? '\n' : ''
  const suffix = end < currentValue.length && currentValue[end] !== '\n' ? '\n' : ''

  const newText =
    currentValue.slice(0, start) +
    prefix +
    text +
    suffix +
    currentValue.slice(end)

  content.value = newText

  await nextTick()
  textarea.focus()

  const cursor = start + prefix.length + text.length
  textarea.setSelectionRange(cursor, cursor)
}

const insertHeading = async (level: 1 | 2 | 3) => {
  const marks = '#'.repeat(level)
  await insertBlock(`${marks} 标题`)
}

const insertBold = async () => {
  await replaceSelection('**', '**', '加粗文字')
}

const insertItalic = async () => {
  await replaceSelection('*', '*', '斜体文字')
}

const insertInlineCode = async () => {
  await replaceSelection('`', '`', 'code')
}

const insertCodeBlock = async () => {
  await insertBlock('```javascript\nconsole.log("Hello World")\n```')
}

const insertQuote = async () => {
  await insertBlock('> 引用内容')
}

const insertUnorderedList = async () => {
  await insertBlock('- 列表项 1\n- 列表项 2\n- 列表项 3')
}

const insertOrderedList = async () => {
  await insertBlock('1. 列表项 1\n2. 列表项 2\n3. 列表项 3')
}

const insertDivider = async () => {
  await insertBlock('---')
}

const insertLink = async () => {
  await replaceSelection('[', '](https://example.com)', '链接文字')
}

const insertImage = async () => {
  await replaceSelection('![', '](https://image-url.com/example.png)', '图片描述')
}

const previewHtml = computed(() => {
  return renderMarkdown(content.value)
})

watch(previewHtml, async () => {
  await nextTick()
  await renderMermaid()
})

const selectFile = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0] || null
  selectedFile.value = file
  selectedFileName.value = file ? file.name : ''
  uploadMessage.value = ''
  errorMessage.value = ''
}

const selectBodyImageFile = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0] || null
  selectedBodyImageFile.value = file
  selectedBodyImageFileName.value = file ? file.name : ''
  bodyImageMessage.value = ''
  errorMessage.value = ''
}

const uploadSelectedFile = async () => {
  if (!selectedFile.value) {
    errorMessage.value = '请先选择图片'
    return
  }

  try {
    uploading.value = true
    errorMessage.value = ''
    uploadMessage.value = ''

    const formData = new FormData()
    formData.append('file', selectedFile.value)

    const data = await api<{ url: string }>('/api/upload', {
      method: 'POST',
      body: formData
    })

    coverImage.value = data.url
    uploadMessage.value = '封面上传成功'
    selectedFile.value = null
    selectedFileName.value = ''
  } catch (error: any) {
    errorMessage.value = error?.message || '上传失败'
  } finally {
    uploading.value = false
  }
}

const uploadBodyImageAndInsert = async () => {
  if (!selectedBodyImageFile.value) {
    errorMessage.value = '请先选择正文图片'
    return
  }

  try {
    uploadingBodyImage.value = true
    errorMessage.value = ''
    bodyImageMessage.value = ''

    const formData = new FormData()
    formData.append('file', selectedBodyImageFile.value)

    const data = await api<{ url: string }>('/api/upload', {
      method: 'POST',
      body: formData
    })

    await insertTextAtCursor(`![图片描述](${data.url})`)
    bodyImageMessage.value = '正文图片已上传并插入'
    selectedBodyImageFile.value = null
    selectedBodyImageFileName.value = ''
  } catch (error: any) {
    errorMessage.value = error?.message || '正文图片上传失败'
  } finally {
    uploadingBodyImage.value = false
  }
}

const submit = async (status: 'draft' | 'published') => {
  if (!title.value.trim()) {
    errorMessage.value = '文章标题不能为空'
    return
  }

  if (!content.value.trim()) {
    errorMessage.value = '文章内容不能为空'
    return
  }

  try {
    submittingAction.value = status
    errorMessage.value = ''
    successMessage.value = ''

    const data = await api<{
      id: number
      title: string
      content: string
      category: string | null
      tags: string | null
      coverImage: string | null
      status: string | null
    }>('/api/posts', {
      method: 'POST',
      body: {
        title: title.value,
        content: content.value,
        category: category.value,
        tags: tags.value,
        coverImage: coverImage.value,
        status
      }
    })

    successMessage.value =
      status === 'draft'
        ? `草稿保存成功：${data.title}`
        : `发布成功：${data.title}`

    if (status === 'draft') {
      await navigateTo('/my-posts')
      return
    }

    await navigateTo(`/posts/${data.id}`)
  } catch (error: any) {
    errorMessage.value =
      error?.message || (status === 'draft' ? '保存草稿失败' : '发布失败')
  } finally {
    submittingAction.value = ''
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-7xl mx-auto px-4 py-8">
      <section class="mb-6 rounded-3xl border border-gray-200 bg-white p-6 md:p-8 shadow-sm">
        <div class="flex flex-col gap-6 xl:flex-row xl:items-end xl:justify-between">
          <div>
            <div class="inline-flex rounded-full bg-blue-50 px-4 py-1 text-sm text-blue-700">
              Create Post
            </div>

            <h1 class="mt-4 text-3xl md:text-4xl font-bold text-gray-900">
              发布文章
            </h1>

            <p class="mt-3 max-w-2xl text-gray-600 leading-7">
              创建新的 Markdown 文章内容，补充分类、标签和封面，支持实时预览、快捷工具栏和正文图片插入。
            </p>
          </div>

          <div class="flex flex-wrap gap-3">
            <NuxtLink
              to="/my-posts"
              class="rounded-xl border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 hover:bg-gray-50 transition"
            >
              返回我的文章
            </NuxtLink>
          </div>
        </div>
      </section>

      <div
        v-if="successMessage"
        class="mb-6 rounded-xl border border-green-200 bg-green-50 p-4 text-green-700"
      >
        {{ successMessage }}
      </div>

      <div
        v-if="errorMessage"
        class="mb-6 rounded-xl border border-red-200 bg-red-50 p-4 text-red-600"
      >
        {{ errorMessage }}
      </div>

      <div class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 md:p-8 space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">文章标题</label>
          <input
            v-model="title"
            placeholder="请输入文章标题"
            class="w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div class="grid gap-6 md:grid-cols-2">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">文章分类</label>
            <input
              v-model="category"
              placeholder="例如：后端"
              class="w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">文章标签</label>
            <input
              v-model="tags"
              placeholder="多个标签可用逗号、中文逗号、顿号、分号分隔"
              class="w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div class="rounded-2xl border border-dashed border-gray-300 bg-gray-50 p-5">
          <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-lg font-semibold text-gray-900">封面图片</h2>
              <p class="mt-1 text-sm text-gray-500">支持 png / jpg / jpeg / webp，建议上传清晰横图</p>
            </div>

            <div class="flex flex-col gap-3 md:items-end">
              <input
                type="file"
                accept="image/png,image/jpeg,image/jpg,image/webp"
                @change="selectFile"
                class="block text-sm text-gray-600"
              />
              <button
                @click="uploadSelectedFile"
                :disabled="uploading"
                class="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
              >
                {{ uploading ? '上传中...' : '上传封面' }}
              </button>
            </div>
          </div>

          <p v-if="selectedFileName" class="mt-4 text-sm text-gray-600">
            已选择文件：{{ selectedFileName }}
          </p>

          <p v-if="uploadMessage" class="mt-2 text-sm text-green-600">
            {{ uploadMessage }}
          </p>

          <div v-if="coverImage" class="mt-5">
            <p class="mb-3 text-sm font-medium text-gray-700">封面预览</p>
            <img
              :src="coverImage"
              alt="封面预览"
              class="w-full max-w-xl rounded-2xl border border-gray-200 object-cover"
            />
          </div>
        </div>

        <div class="rounded-2xl border border-dashed border-blue-200 bg-blue-50/60 p-5">
          <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-lg font-semibold text-gray-900">正文插图</h2>
              <p class="mt-1 text-sm text-gray-500">
                上传成功后会自动在正文当前光标位置插入 Markdown 图片语法
              </p>
            </div>

            <div class="flex flex-col gap-3 md:items-end">
              <input
                type="file"
                accept="image/png,image/jpeg,image/jpg,image/webp"
                @change="selectBodyImageFile"
                class="block text-sm text-gray-600"
              />
              <button
                @click="uploadBodyImageAndInsert"
                :disabled="uploadingBodyImage"
                class="rounded-lg bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {{ uploadingBodyImage ? '插入中...' : '上传并插入正文' }}
              </button>
            </div>
          </div>

          <p v-if="selectedBodyImageFileName" class="mt-4 text-sm text-gray-600">
            已选择正文图片：{{ selectedBodyImageFileName }}
          </p>

          <p v-if="bodyImageMessage" class="mt-2 text-sm text-green-600">
            {{ bodyImageMessage }}
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">文章内容（Markdown）</label>

          <div class="space-y-4">
            <div
              class="sticky top-20 z-20 rounded-xl border border-gray-200 bg-white/95 p-3 backdrop-blur"
            >
              <div class="flex flex-wrap gap-2">
                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertHeading(1)"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  H1
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertHeading(2)"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  H2
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertHeading(3)"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  H3
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertBold"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-bold text-gray-700 hover:bg-gray-100 transition"
                >
                  B
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertItalic"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm italic text-gray-700 hover:bg-gray-100 transition"
                >
                  I
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertInlineCode"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-mono text-gray-700 hover:bg-gray-100 transition"
                >
                  Code
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertCodeBlock"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  代码块
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertQuote"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  引用
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertUnorderedList"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  无序列表
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertOrderedList"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  有序列表
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertLink"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  链接
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertImage"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  图片
                </button>

                <button
                  type="button"
                  @mousedown.prevent
                  @click="insertDivider"
                  class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 transition"
                >
                  分割线
                </button>
              </div>
            </div>

            <div class="grid gap-6 lg:grid-cols-2 items-stretch">
              <div class="flex flex-col">
                <div class="mb-2 text-sm font-medium text-gray-600">编辑区</div>
                <textarea
                  ref="editorRef"
                  v-model="content"
                  @scroll="syncPreviewScroll"
                  placeholder="请输入 Markdown 内容"
                  class="h-[600px] w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500 font-mono resize-none bg-white"
                ></textarea>
              </div>

              <div class="flex flex-col">
                <div class="mb-2 text-sm font-medium text-gray-600">预览区</div>
                <div
                  ref="previewRef"
                  class="h-[600px] overflow-y-auto rounded-xl border border-gray-200 bg-white p-4"
                >
                  <div class="markdown-body" v-html="previewHtml"></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="flex flex-wrap gap-3 pt-2">
          <button
            @click="submit('draft')"
            :disabled="submittingAction !== '' || uploading || uploadingBodyImage"
            class="rounded-lg border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
          >
            {{ submittingAction === 'draft' ? '保存中...' : '保存草稿' }}
          </button>

          <button
            @click="submit('published')"
            :disabled="submittingAction !== '' || uploading || uploadingBodyImage"
            class="rounded-lg bg-gray-900 px-5 py-3 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
          >
            {{ submittingAction === 'published' ? '发布中...' : '发布文章' }}
          </button>

          <NuxtLink
            to="/my-posts"
            class="rounded-lg border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 hover:bg-gray-50"
          >
            返回我的文章
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>