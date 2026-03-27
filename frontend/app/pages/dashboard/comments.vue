<script setup lang="ts">
definePageMeta({
  middleware: 'auth',
  layout: 'admin'
})

const api = useApi()

type CommentStatus = 'visible' | 'hidden'

type CommentItem = {
  id: number
  postId: number
  postTitle: string
  author: string
  content: string
  createdAt: number
  status: CommentStatus
}

type PageResponse = {
  list: CommentItem[]
  page: number
  totalPages: number
  totalElements: number
  size: number
}

const loading = ref(true)
const errorMessage = ref('')
const keyword = ref('')
const comments = ref<CommentItem[]>([])
const page = ref(0)
const size = ref(10)
const totalPages = ref(0)
const totalElements = ref(0)
const deleteLoadingId = ref<number | null>(null)
const statusLoadingId = ref<number | null>(null)

const formatTime = (timestamp: number | null | undefined) => {
  if (!timestamp) return '暂无时间'
  return new Date(timestamp).toLocaleString()
}

const loadComments = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const query = new URLSearchParams({
      page: String(page.value),
      size: String(size.value),
      keyword: keyword.value
    })

    const data = await api<PageResponse>(`/api/admin/comments?${query.toString()}`)

    comments.value = data.list || []
    totalPages.value = data.totalPages || 0
    totalElements.value = data.totalElements || 0
  } catch (error: any) {
    errorMessage.value = error?.message || '加载评论失败'
    comments.value = []
    totalPages.value = 0
    totalElements.value = 0
  } finally {
    loading.value = false
  }
}

const search = async () => {
  page.value = 0
  await loadComments()
}

const resetSearch = async () => {
  keyword.value = ''
  page.value = 0
  await loadComments()
}

const prevPage = async () => {
  if (page.value <= 0) return
  page.value--
  await loadComments()
}

const nextPage = async () => {
  if (page.value >= totalPages.value - 1) return
  page.value++
  await loadComments()
}

const deleteComment = async (comment: CommentItem) => {
  const preview =
    comment.content.length > 30
      ? `${comment.content.slice(0, 30)}...`
      : comment.content

  if (!confirm(`确定要删除评论「${preview}」吗？`)) {
    return
  }

  try {
    deleteLoadingId.value = comment.id

    await api(`/api/comments/${comment.id}`, {
      method: 'DELETE'
    })

    if (comments.value.length === 1 && page.value > 0) {
      page.value--
    }

    await loadComments()
  } catch (error: any) {
    alert(error?.message || '删除评论失败')
  } finally {
    deleteLoadingId.value = null
  }
}

const toggleStatus = async (comment: CommentItem) => {
  const isVisible = comment.status === 'visible'
  const actionText = isVisible ? '隐藏' : '恢复'
  const endpoint = isVisible
    ? `/api/admin/comments/${comment.id}/hide`
    : `/api/admin/comments/${comment.id}/restore`

  const preview =
    comment.content.length > 30
      ? `${comment.content.slice(0, 30)}...`
      : comment.content

  if (!confirm(`确定要${actionText}评论「${preview}」吗？`)) {
    return
  }

  try {
    statusLoadingId.value = comment.id

    await api(endpoint, {
      method: 'PUT'
    })

    await loadComments()
  } catch (error: any) {
    alert(error?.message || `${actionText}评论失败`)
  } finally {
    statusLoadingId.value = null
  }
}

onMounted(loadComments)
</script>

<template>
  <div class="space-y-8">
    <section class="rounded-3xl border border-gray-200 bg-white p-6 md:p-8 shadow-sm">
      <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <div class="inline-flex rounded-full bg-blue-50 px-4 py-1 text-sm text-blue-700">
            Dashboard / Comments
          </div>

          <h1 class="mt-4 text-3xl md:text-4xl font-bold text-gray-900">
            评论管理
          </h1>

          <p class="mt-3 max-w-2xl text-gray-600 leading-7">
            统一查看全站评论内容，支持搜索、分页、隐藏恢复和删除，适合管理员进行内容审核与清理。
          </p>
        </div>

        <div class="flex flex-wrap gap-3">
          <NuxtLink
            to="/dashboard"
            class="rounded-xl border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 hover:bg-gray-50 transition"
          >
            返回总览
          </NuxtLink>

          <NuxtLink
            to="/dashboard/posts"
            class="rounded-xl bg-gray-900 px-5 py-3 text-sm text-white hover:bg-gray-800 transition"
          >
            去文章管理
          </NuxtLink>
        </div>
      </div>
    </section>

    <section class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm">
      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-3 md:flex-row">
          <input
            v-model="keyword"
            @keyup.enter="search"
            placeholder="搜索评论作者或评论内容"
            class="flex-1 rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
          />

          <div class="flex gap-3">
            <button
              @click="search"
              class="rounded-xl bg-gray-900 px-5 py-3 text-sm text-white hover:bg-gray-800 transition"
            >
              搜索
            </button>

            <button
              @click="resetSearch"
              class="rounded-xl border border-gray-300 bg-white px-5 py-3 text-sm text-gray-700 hover:bg-gray-50 transition"
            >
              重置
            </button>
          </div>
        </div>
      </div>
    </section>

    <div
      v-if="errorMessage"
      class="rounded-2xl border border-red-200 bg-red-50 p-4 text-red-600"
    >
      {{ errorMessage }}
    </div>

    <div v-if="loading" class="grid gap-4">
      <div
        v-for="item in 6"
        :key="item"
        class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm"
      >
        <div class="h-5 w-40 rounded bg-gray-200 animate-pulse"></div>
        <div class="mt-4 h-4 w-full rounded bg-gray-100 animate-pulse"></div>
        <div class="mt-2 h-4 w-4/5 rounded bg-gray-100 animate-pulse"></div>
      </div>
    </div>

    <EmptyState
      v-else-if="comments.length === 0"
      title="暂无评论"
      description="当前没有可展示的评论记录，或者搜索结果为空。"
      action-text="返回后台首页"
      action-to="/dashboard"
    />

    <div v-else class="grid gap-4">
      <article
        v-for="comment in comments"
        :key="comment.id"
        class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm"
      >
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2 text-sm">
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                评论ID：{{ comment.id }}
              </span>

              <span class="rounded-full bg-blue-50 px-3 py-1 text-blue-700">
                作者：{{ comment.author }}
              </span>

              <span
                v-if="comment.status === 'visible'"
                class="rounded-full bg-green-50 px-3 py-1 text-green-700"
              >
                可见
              </span>

              <span
                v-else
                class="rounded-full bg-yellow-50 px-3 py-1 text-yellow-700"
              >
                已隐藏
              </span>

              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-600">
                {{ formatTime(comment.createdAt) }}
              </span>
            </div>

            <div class="mt-4 rounded-xl border border-gray-200 bg-gray-50 p-4">
              <div class="text-xs text-gray-500">所属文章</div>
              <NuxtLink
                :to="`/posts/${comment.postId}`"
                class="mt-2 block text-base font-semibold text-gray-900 hover:text-blue-600 transition break-words"
              >
                {{ comment.postTitle || '无标题文章' }}
              </NuxtLink>
              <div class="mt-1 text-xs text-gray-500">
                Post ID：#{{ comment.postId }}
              </div>
            </div>

            <p
              :class="[
                'mt-4 whitespace-pre-wrap break-words leading-7',
                comment.status === 'hidden' ? 'text-gray-400' : 'text-gray-800'
              ]"
            >
              {{ comment.content }}
            </p>
          </div>

          <div class="flex shrink-0 gap-3 flex-wrap">
            <button
              @click="toggleStatus(comment)"
              :disabled="statusLoadingId === comment.id"
              class="rounded-lg border border-blue-300 bg-blue-50 px-4 py-2 text-sm text-blue-700 hover:bg-blue-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{
                statusLoadingId === comment.id
                  ? '处理中...'
                  : comment.status === 'visible'
                    ? '隐藏评论'
                    : '恢复评论'
              }}
            </button>

            <button
              @click="deleteComment(comment)"
              :disabled="deleteLoadingId === comment.id"
              class="rounded-lg border border-red-300 bg-red-50 px-4 py-2 text-sm text-red-600 hover:bg-red-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{ deleteLoadingId === comment.id ? '删除中...' : '删除评论' }}
            </button>
          </div>
        </div>
      </article>
    </div>

    <div
      v-if="!loading && totalPages > 0"
      class="flex flex-col items-center justify-center gap-4"
    >
      <div class="text-sm text-gray-600">
        第 {{ page + 1 }} 页 / 共 {{ totalPages }} 页 · 共 {{ totalElements }} 条评论
      </div>

      <div class="flex items-center gap-3">
        <button
          @click="prevPage"
          :disabled="page === 0"
          class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          上一页
        </button>

        <button
          @click="nextPage"
          :disabled="page >= totalPages - 1"
          class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          下一页
        </button>
      </div>
    </div>
  </div>
</template>
