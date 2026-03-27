<script setup lang="ts">
import { computed, onBeforeUnmount, nextTick, watch } from 'vue'
import { renderMarkdown, extractToc, renderMermaid } from '~/composables/useMarkdown'

const route = useRoute()
const api = useApi()
const auth = useAuth()

type PostDetail = {
  id: number
  title: string
  summary: string | null
  content: string
  author: string | null
  category: string | null
  tags: string | null
  coverImage: string | null
  status: string | null
  createdAt: number | null
  updatedAt: number | null
  viewCount: number | null
}

type CommentItem = {
  id: number
  postId: number
  author: string
  content: string
  createdAt: number
}

const post = ref<PostDetail | null>(null)
const comments = ref<CommentItem[]>([])
const commentContent = ref('')
const loading = ref(true)
const commentLoading = ref(false)
const errorMessage = ref('')
const commentErrorMessage = ref('')
const currentUsername = ref('')
const activeTocId = ref('')

const renderedContent = computed(() => {
  return renderMarkdown(post.value?.content || '')
})

const tocItems = computed(() => {
  return extractToc(post.value?.content || '')
})

const isLoggedIn = computed(() => !!auth.accessToken.value)
const isAdmin = computed(() => auth.role.value === 'admin')

const canManagePost = computed(() => {
  if (!post.value || !currentUsername.value) return false
  return currentUsername.value === post.value.author || isAdmin.value
})

const canDeleteComment = (comment: CommentItem) => {
  if (!currentUsername.value) return false
  return currentUsername.value === comment.author || isAdmin.value
}

const formatTime = (timestamp: number | null | undefined) => {
  if (!timestamp) return '暂无时间'
  return new Date(timestamp).toLocaleString()
}

let observer: IntersectionObserver | null = null

const handleMarkdownClick = async (event: Event) => {
  const target = event.target as HTMLElement | null
  if (!target) return

  const button = target.closest('.code-copy-btn') as HTMLButtonElement | null
  if (!button) return

  const codeBlock = button.closest('.code-block') as HTMLElement | null
  if (!codeBlock) return

  const rawCode = codeBlock.getAttribute('data-code') || ''
  const decodedCode = decodeURIComponent(rawCode)

  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(decodedCode)
    } else {
      const textarea = document.createElement('textarea')
      textarea.value = decodedCode
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      textarea.style.left = '-9999px'
      document.body.appendChild(textarea)
      textarea.focus()
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
    }

    const originalText = '复制'
    button.textContent = '已复制'
    button.classList.add('copied')

    window.setTimeout(() => {
      button.textContent = originalText
      button.classList.remove('copied')
    }, 1500)
  } catch (error) {
    button.textContent = '复制失败'
    window.setTimeout(() => {
      button.textContent = '复制'
    }, 1500)
  }
}

const setupTocObserver = async () => {
  if (import.meta.server) return

  if (observer) {
    observer.disconnect()
    observer = null
  }

  await nextTick()

  const headings = Array.from(
    document.querySelectorAll('.markdown-body h1, .markdown-body h2, .markdown-body h3')
  ) as HTMLElement[]

  if (headings.length === 0) return

  observer = new IntersectionObserver(
    (entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => {
          return (a.target as HTMLElement).offsetTop - (b.target as HTMLElement).offsetTop
        })

      if (visible.length > 0) {
        activeTocId.value = (visible[0].target as HTMLElement).id
        return
      }

      const scrollY = window.scrollY + 140
      let currentId = headings[0].id

      for (const heading of headings) {
        if (heading.offsetTop <= scrollY) {
          currentId = heading.id
        } else {
          break
        }
      }

      activeTocId.value = currentId
    },
    {
      root: null,
      rootMargin: '-100px 0px -70% 0px',
      threshold: [0, 1]
    }
  )

  headings.forEach((heading) => observer?.observe(heading))
  activeTocId.value = headings[0].id
}

const renderArticleEnhancements = async () => {
  if (import.meta.server) return
  if (loading.value || !post.value) return

  await nextTick()
  await renderMermaid()
  await nextTick()
  await setupTocObserver()
}

watch(
  [renderedContent, loading],
  async () => {
    await renderArticleEnhancements()
  },
  { immediate: true }
)

const scrollToHeading = (id: string) => {
  if (import.meta.server) return

  const el = document.getElementById(id)
  if (!el) return

  const topOffset = 96
  const y = el.getBoundingClientRect().top + window.scrollY - topOffset

  window.history.replaceState(null, '', `#${id}`)
  window.scrollTo({
    top: y,
    behavior: 'smooth'
  })

  activeTocId.value = id
}

const loadPost = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const data = await api<PostDetail>(`/api/posts/${route.params.id}`)
    post.value = data
  } catch (error: any) {
    errorMessage.value = error?.message || '加载文章失败'
  } finally {
    loading.value = false
    await renderArticleEnhancements()
  }
}

const loadComments = async () => {
  commentErrorMessage.value = ''

  try {
    const data = await api<CommentItem[]>(`/api/posts/${route.params.id}/comments`)
    comments.value = data
  } catch (error: any) {
    comments.value = []
    commentErrorMessage.value = error?.message || '加载评论失败'
  }
}

const loadCurrentUser = async () => {
  try {
    auth.loadTokens()
    const data = await api<{ username: string; role?: string }>('/api/auth/me')
    currentUsername.value = data.username
  } catch (error) {
    currentUsername.value = ''
  }
}

const submitComment = async () => {
  if (!isLoggedIn.value) {
    commentErrorMessage.value = '请先登录后再发表评论'
    return
  }

  if (!commentContent.value.trim()) {
    commentErrorMessage.value = '评论内容不能为空'
    return
  }

  try {
    commentLoading.value = true
    commentErrorMessage.value = ''

    await api(`/api/posts/${route.params.id}/comments`, {
      method: 'POST',
      body: {
        content: commentContent.value
      }
    })

    commentContent.value = ''
    await loadComments()
  } catch (error: any) {
    commentErrorMessage.value = error?.message || '发表评论失败'
  } finally {
    commentLoading.value = false
  }
}

const deleteComment = async (commentId: number) => {
  if (!confirm('确定要删除这条评论吗？')) {
    return
  }

  try {
    await api(`/api/comments/${commentId}`, {
      method: 'DELETE'
    })
    await loadComments()
  } catch (error: any) {
    commentErrorMessage.value = error?.message || '删除评论失败'
  }
}

const deletePost = async () => {
  if (!confirm('确定要删除这篇文章吗？')) {
    return
  }

  try {
    await api(`/api/posts/${route.params.id}`, {
      method: 'DELETE'
    })

    if (isAdmin.value) {
      await navigateTo('/dashboard/posts')
      return
    }

    await navigateTo('/my-posts')
  } catch (error: any) {
    errorMessage.value = error?.message || '删除文章失败'
  }
}

const splitTags = (raw: string | null | undefined) => {
  return (raw || '')
    .split(/[,，、。;；|｜]/)
    .map(tag => tag.trim())
    .filter(Boolean)
}

onMounted(async () => {
  document.addEventListener('click', handleMarkdownClick)

  await loadCurrentUser()
  await loadPost()
  await loadComments()
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleMarkdownClick)

  if (observer) {
    observer.disconnect()
    observer = null
  }
})
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div v-if="loading" class="text-gray-500 py-10">
        加载中...
      </div>

      <div
        v-else-if="errorMessage"
        class="bg-red-50 text-red-600 border border-red-200 rounded-xl p-4"
      >
        {{ errorMessage }}
      </div>

      <div
        v-else-if="post"
        class="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_260px] gap-6 items-start"
      >
        <div class="space-y-6 min-w-0">
          <article class="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
            <div v-if="post.coverImage" class="bg-gray-100">
              <img
                :src="post.coverImage"
                alt="封面图"
                class="w-full max-h-[420px] object-cover"
              />
            </div>

            <div class="p-6 md:p-8">
              <div class="flex flex-wrap items-center gap-3">
                <h1 class="text-3xl md:text-4xl font-bold text-gray-900 leading-tight">
                  {{ post.title }}
                </h1>

                <span
                  v-if="post.status === 'draft'"
                  class="inline-flex rounded-full bg-yellow-50 px-3 py-1 text-sm text-yellow-700"
                >
                  草稿
                </span>

                <span
                  v-else-if="post.status === 'published'"
                  class="inline-flex rounded-full bg-green-50 px-3 py-1 text-sm text-green-700"
                >
                  已发布
                </span>
              </div>

              <div class="mt-4 flex flex-wrap gap-2 text-sm">
                <span class="px-3 py-1 rounded-full bg-gray-100 text-gray-700">
                  作者：{{ post.author || '未知作者' }}
                </span>

                <NuxtLink
                  :to="`/categories/${encodeURIComponent(post.category || '未分类')}`"
                  class="px-3 py-1 rounded-full bg-blue-50 text-blue-700 hover:bg-blue-100 transition"
                >
                  分类：{{ post.category || '未分类' }}
                </NuxtLink>

                <template v-if="splitTags(post.tags).length > 0">
                  <NuxtLink
                    v-for="tag in splitTags(post.tags)"
                    :key="tag"
                    :to="`/tags/${encodeURIComponent(tag)}`"
                    class="px-3 py-1 rounded-full bg-green-50 text-green-700 hover:bg-green-100 transition"
                  >
                    # {{ tag }}
                  </NuxtLink>
                </template>

                <span
                  v-else
                  class="px-3 py-1 rounded-full bg-green-50 text-green-700"
                >
                  无标签
                </span>
              </div>

              <div class="mt-4 space-y-1 text-sm text-gray-500">
                <div>发布时间：{{ formatTime(post.createdAt) }}</div>
                <div>最近更新：{{ formatTime(post.updatedAt || post.createdAt) }}</div>
                <div>阅读量：{{ post.viewCount ?? 0 }}</div>
              </div>

              <div v-if="canManagePost" class="mt-6 flex flex-wrap gap-3">
                <NuxtLink
                  :to="`/edit-post/${post.id}`"
                  class="inline-flex items-center rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800 transition"
                >
                  编辑这篇文章
                </NuxtLink>

                <button
                  @click="deletePost"
                  class="inline-flex items-center rounded-lg border border-red-300 bg-red-50 px-4 py-2 text-sm text-red-600 hover:bg-red-100 transition"
                >
                  删除这篇文章
                </button>
              </div>

              <div class="mt-8 border-t border-gray-200 pt-8">
                <div
                  class="markdown-body"
                  v-html="renderedContent"
                ></div>
              </div>
            </div>
          </article>

          <section class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 md:p-8">
            <h2 class="text-2xl font-semibold text-gray-900 mb-6">评论区</h2>

          <div v-if="isLoggedIn" class="space-y-3">
            <textarea
                v-model="commentContent"
                placeholder="写下你的评论"
                class="w-full min-h-[120px] rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
              />
              <button
                @click="submitComment"
                :disabled="commentLoading"
                class="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800 disabled:opacity-50"
              >
                {{ commentLoading ? '提交中...' : '发表评论' }}
              </button>
            </div>

            <div
            v-else
            class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-5"
            >
              <div class="text-sm text-gray-700">登录后即可参与评论</div>
              <p class="mt-2 text-sm text-gray-500">
                你可以先登录账号，再对这篇文章发表看法。
              </p>
              <NuxtLink
                to="/login"
                class="mt-4 inline-flex rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800 transition"
              >
                去登录
              </NuxtLink>
            </div>

            <p v-if="commentErrorMessage" class="mt-3 text-red-600">
              {{ commentErrorMessage }}
            </p>

            <div class="mt-8 space-y-4">
              <EmptyState
                v-if="comments.length === 0"
                title="还没有评论"
                description="来发表第一条评论，参与这篇文章的讨论。"
              />

              <article
                v-for="comment in comments"
                :key="comment.id"
                class="rounded-xl border border-gray-200 bg-gray-50 p-4"
              >
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <div class="text-sm font-medium text-gray-900 flex flex-wrap items-center gap-2">
                      <span>{{ comment.author }}</span>

                      <span
                        v-if="post?.author && comment.author === post.author"
                        class="rounded-full bg-purple-50 px-2 py-0.5 text-xs text-purple-700"
                      >
                        作者
                      </span>

                      <span
                        v-if="currentUsername && currentUsername === comment.author"
                        class="rounded-full bg-blue-50 px-2 py-0.5 text-xs text-blue-600"
                      >
                        我的评论
                      </span>
                    </div>
                    <div class="mt-1 text-xs text-gray-500">
                      {{ formatTime(comment.createdAt) }}
                    </div>
                  </div>

                  <button
                    v-if="canDeleteComment(comment)"
                    @click="deleteComment(comment.id)"
                    class="text-sm text-red-600 hover:text-red-700"
                    >
                    {{ currentUsername === comment.author ? '删除评论' : '管理删除' }}
                  </button>
                </div>

                <p class="mt-3 text-gray-700 leading-7 whitespace-pre-wrap">
                  {{ comment.content }}
                </p>
              </article>
            </div>
          </section>
        </div>

        <aside class="block mt-6 lg:mt-0 lg:sticky lg:top-24">
          <div
            v-if="tocItems.length > 0"
            class="rounded-2xl border border-gray-200 bg-white shadow-sm overflow-hidden"
          >
            <div class="px-5 pt-5 pb-3 border-b border-gray-100">
              <h3 class="text-base font-semibold text-gray-900">
                文章目录（{{ tocItems.length }}）
              </h3>
            </div>

            <nav
              class="px-3 py-3 overflow-y-auto overscroll-contain"
              style="max-height: min(420px, calc(100vh - 180px));"
            >
              <div class="space-y-2">
                <button
                  v-for="item in tocItems"
                  :key="item.id"
                  type="button"
                  @click="scrollToHeading(item.id)"
                  :class="[
                    'block w-full text-left text-sm transition break-words rounded-lg px-2 py-1.5',
                    activeTocId === item.id
                      ? 'bg-blue-50 text-blue-700 font-medium'
                      : 'text-gray-600 hover:text-blue-600 hover:bg-gray-50',
                    item.level === 1 ? 'pl-2' : '',
                    item.level === 2 ? 'pl-6' : '',
                    item.level === 3 ? 'pl-10 text-gray-500' : ''
                  ]"
                >
                  {{ item.text }}
                </button>
              </div>
            </nav>
          </div>
        </aside>
      </div>
    </div>
  </div>
</template>
