<script setup lang="ts">
definePageMeta({
  middleware: 'auth',
  layout: 'admin'
})

const api = useApi()

type PostItem = {
  id: number
  title: string
  summary: string
  author: string | null
  category: string | null
  tags: string | null
  coverImage: string | null
  status: string | null
  createdAt: number | null
  updatedAt: number | null
  viewCount?: number | null
  weight?: number | null
}

type PageResponse = {
  list: PostItem[]
  page: number
  totalPages: number
  totalElements: number
  size: number
}

type StatusFilter = 'all' | 'draft' | 'published'

const loading = ref(true)
const errorMessage = ref('')
const keyword = ref('')
const posts = ref<PostItem[]>([])
const currentUsername = ref('')
const page = ref(0)
const size = ref(6)
const totalPages = ref(0)
const totalElements = ref(0)
const statusFilter = ref<StatusFilter>('all')
const statusLoadingId = ref<number | null>(null)
const deleteLoadingId = ref<number | null>(null)
const weightLoadingId = ref<number | null>(null)
const weightInputs = ref<Record<number, number>>({})

const formatTime = (timestamp: number | null | undefined) => {
  if (!timestamp) return '暂无时间'
  return new Date(timestamp).toLocaleString()
}

const splitTags = (raw: string | null | undefined) => {
  return (raw || '')
    .split(/[,，、。;；|｜]/)
    .map(tag => tag.trim())
    .filter(Boolean)
}

const filteredPosts = computed(() => {
  if (statusFilter.value === 'draft') {
    return posts.value.filter(post => post.status === 'draft')
  }

  if (statusFilter.value === 'published') {
    return posts.value.filter(post => post.status === 'published')
  }

  return posts.value
})

const draftCount = computed(() => {
  return posts.value.filter(post => post.status === 'draft').length
})

const publishedCount = computed(() => {
  return posts.value.filter(post => post.status === 'published').length
})

const loadPosts = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const me = await api<{ username: string }>('/api/auth/me')
    currentUsername.value = me.username

    const query = new URLSearchParams({
      page: String(page.value),
      size: String(size.value),
      keyword: keyword.value
    })

    const data = await api<PageResponse>(`/api/admin/posts?${query.toString()}`)

    posts.value = data.list || []
    weightInputs.value = Object.fromEntries(
    (data.list || []).map(post => [post.id, post.weight ?? 0])
    )
    totalPages.value = data.totalPages || 0
    totalElements.value = data.totalElements || 0
  } catch (error: any) {
    const message = error?.message || '加载文章失败'
    errorMessage.value = message
    posts.value = []
    totalPages.value = 0
    totalElements.value = 0

    if (
      message.includes('未登录') ||
      message.includes('401') ||
      message.includes('token')
    ) {
      await navigateTo('/login')
    }
  } finally {
    loading.value = false
  }
}

const search = async () => {
  page.value = 0
  await loadPosts()
}

const resetSearch = async () => {
  keyword.value = ''
  statusFilter.value = 'all'
  page.value = 0
  await loadPosts()
}

const prevPage = async () => {
  if (page.value <= 0) return
  page.value--
  await loadPosts()
}

const nextPage = async () => {
  if (page.value >= totalPages.value - 1) return
  page.value++
  await loadPosts()
}

const toggleStatus = async (post: PostItem) => {
  const nextStatus = post.status === 'published' ? 'draft' : 'published'
  const actionText = nextStatus === 'published' ? '发布' : '转为草稿'

  if (!confirm(`确定要将这篇文章${actionText}吗？`)) {
    return
  }

  try {
    statusLoadingId.value = post.id

    await api(`/api/posts/${post.id}/status`, {
      method: 'PUT',
      body: {
        status: nextStatus
      }
    })

    await loadPosts()
  } catch (error: any) {
    alert(error?.message || '更新文章状态失败')
  } finally {
    statusLoadingId.value = null
  }
}

const updateWeight = async (post: PostItem) => {
  const rawWeight = Number(weightInputs.value[post.id] ?? 0)

  if (!Number.isInteger(rawWeight)) {
    alert('权重必须是整数')
    return
  }

  try {
    weightLoadingId.value = post.id

    await api(`/api/posts/${post.id}/weight?weight=${rawWeight}`, {
      method: 'PUT'
    })

    await loadPosts()
  } catch (error: any) {
    alert(error?.message || '更新文章权重失败')
  } finally {
    weightLoadingId.value = null
  }
}

const deletePost = async (post: PostItem) => {
  if (!confirm(`确定要删除文章《${post.title}》吗？此操作不可恢复。`)) {
    return
  }

  try {
    deleteLoadingId.value = post.id

    await api(`/api/posts/${post.id}`, {
      method: 'DELETE'
    })

    if (filteredPosts.value.length === 1 && page.value > 0) {
      page.value--
    }

    await loadPosts()
  } catch (error: any) {
    alert(error?.message || '删除文章失败')
  } finally {
    deleteLoadingId.value = null
  }
}

onMounted(loadPosts)
</script>

<template>
  <div class="space-y-8">
    <section class="rounded-3xl border border-gray-200 bg-white p-6 md:p-8 shadow-sm">
      <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <div class="inline-flex rounded-full bg-blue-50 px-4 py-1 text-sm text-blue-700">
            Dashboard / Posts
          </div>

          <h1 class="mt-4 text-3xl md:text-4xl font-bold text-gray-900">
            文章管理
          </h1>

          <p class="mt-3 max-w-2xl text-gray-600 leading-7">
            统一管理全站草稿与已发布文章，支持搜索、筛选、查看、编辑、状态切换与删除。
          </p>

          <p v-if="currentUsername" class="mt-3 text-sm text-blue-600">
            当前登录用户：{{ currentUsername }}
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
            to="/create-post"
            class="rounded-xl bg-gray-900 px-5 py-3 text-sm text-white hover:bg-gray-800 transition"
          >
            新建文章
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
            placeholder="搜索标题或内容"
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

        <div class="flex flex-wrap gap-3">
          <button
            @click="statusFilter = 'all'"
            :class="[
              'rounded-full px-4 py-2 text-sm transition',
              statusFilter === 'all'
                ? 'bg-gray-900 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            全部（{{ posts.length }}）
          </button>

          <button
            @click="statusFilter = 'draft'"
            :class="[
              'rounded-full px-4 py-2 text-sm transition',
              statusFilter === 'draft'
                ? 'bg-yellow-500 text-white'
                : 'bg-yellow-50 text-yellow-700 hover:bg-yellow-100'
            ]"
          >
            草稿（{{ draftCount }}）
          </button>

          <button
            @click="statusFilter = 'published'"
            :class="[
              'rounded-full px-4 py-2 text-sm transition',
              statusFilter === 'published'
                ? 'bg-green-600 text-white'
                : 'bg-green-50 text-green-700 hover:bg-green-100'
            ]"
          >
            已发布（{{ publishedCount }}）
          </button>
        </div>
      </div>
    </section>

    <div
      v-if="errorMessage"
      class="rounded-2xl border border-red-200 bg-red-50 p-4 text-red-600"
    >
      {{ errorMessage }}
    </div>

    <div v-if="loading" class="grid gap-6">
      <div
        v-for="item in 4"
        :key="item"
        class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm"
      >
        <div class="md:flex">
          <div class="h-52 bg-gray-200 animate-pulse md:w-72"></div>
          <div class="flex-1 p-6">
            <div class="h-7 w-2/5 rounded bg-gray-200 animate-pulse"></div>
            <div class="mt-4 h-4 w-full rounded bg-gray-100 animate-pulse"></div>
            <div class="mt-2 h-4 w-4/5 rounded bg-gray-100 animate-pulse"></div>
          </div>
        </div>
      </div>
    </div>

    <EmptyState
      v-else-if="posts.length === 0"
      title="你还没有文章"
      description="先写一篇文章，后台文章管理页就会开始展示内容。"
      action-text="去写文章"
      action-to="/create-post"
    />

    <EmptyState
      v-else-if="filteredPosts.length === 0"
      title="当前筛选下没有文章"
      description="试试切换筛选条件，或者清空搜索关键词。"
      action-text="返回文章管理"
      action-to="/dashboard/posts"
    />

    <div v-else class="grid gap-6">
      <article
        v-for="post in filteredPosts"
        :key="post.id"
        class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
      >
        <div class="md:flex">
          <div
            v-if="post.coverImage"
            class="md:w-72 shrink-0 bg-gray-100"
          >
            <img
              :src="post.coverImage"
              alt="封面图"
              class="w-full h-56 md:h-full object-cover"
            />
          </div>

          <div
            v-else
            class="flex h-56 items-center justify-center bg-gray-100 text-sm text-gray-400 md:w-72 shrink-0"
          >
            暂无封面
          </div>

          <div class="flex-1 p-6">
            <div class="flex flex-wrap items-center gap-3">
              <NuxtLink
                :to="`/posts/${post.id}`"
                class="text-2xl font-semibold text-gray-900 hover:text-blue-600 transition"
              >
                {{ post.title }}
              </NuxtLink>

              <span
                v-if="post.status === 'draft'"
                class="inline-flex rounded-full bg-yellow-50 px-3 py-1 text-xs text-yellow-700"
              >
                草稿
              </span>

              <span
                v-else-if="post.status === 'published'"
                class="inline-flex rounded-full bg-green-50 px-3 py-1 text-xs text-green-700"
              >
                已发布
              </span>
            </div>

            <p class="mt-3 text-gray-600 leading-7">
              {{ post.summary }}
            </p>

            <div class="mt-4 flex flex-wrap gap-2 text-sm">
              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                {{ post.category || '未分类' }}
              </span>

              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                创建：{{ formatTime(post.createdAt) }}
              </span>

              <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                更新：{{ formatTime(post.updatedAt) }}
              </span>

              <span class="rounded-full bg-blue-50 px-3 py-1 text-blue-700">
                阅读：{{ post.viewCount ?? 0 }}
              </span>

              <span class="rounded-full bg-purple-50 px-3 py-1 text-purple-700">
                权重：{{ post.weight ?? 0 }}
              </span>

              <template v-for="tag in splitTags(post.tags).slice(0, 3)" :key="tag">
                <span class="rounded-full bg-green-50 px-3 py-1 text-green-700">
                  # {{ tag }}
                </span>
              </template>
            </div>

            <div class="mt-6 space-y-4">
              <div class="flex flex-wrap items-center gap-3 rounded-xl border border-gray-200 bg-gray-50 p-3">
                <span class="text-sm text-gray-600">文章权重</span>

                <input
                  v-model.number="weightInputs[post.id]"
                  type="number"
                  class="w-28 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="权重"
                />

                <button
                  @click="updateWeight(post)"
                  :disabled="weightLoadingId === post.id"
                  class="rounded-lg border border-purple-300 bg-purple-50 px-4 py-2 text-sm text-purple-700 hover:bg-purple-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {{ weightLoadingId === post.id ? '保存中...' : '保存权重' }}
                </button>

                <span class="text-xs text-gray-500">
                  数值越大越靠前，测试文章可设为负数
                </span>
              </div>

              <div class="flex flex-wrap gap-3">
              <NuxtLink
                :to="`/posts/${post.id}`"
                class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition"
              >
                查看
              </NuxtLink>

              <NuxtLink
                :to="`/edit-post/${post.id}`"
                class="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800 transition"
              >
                编辑
              </NuxtLink>

              <button
                @click="toggleStatus(post)"
                :disabled="statusLoadingId === post.id"
                class="rounded-lg border border-blue-300 bg-blue-50 px-4 py-2 text-sm text-blue-700 hover:bg-blue-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {{
                  statusLoadingId === post.id
                    ? '处理中...'
                    : post.status === 'published'
                      ? '转为草稿'
                      : '发布'
                }}
              </button>

              <button
                @click="deletePost(post)"
                :disabled="deleteLoadingId === post.id"
                class="rounded-lg border border-red-300 bg-red-50 px-4 py-2 text-sm text-red-600 hover:bg-red-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {{ deleteLoadingId === post.id ? '删除中...' : '删除' }}
              </button>
              </div>
            </div>
          </div>
        </div>
      </article>
    </div>

    <div
      v-if="!loading && totalPages > 0"
      class="flex flex-col items-center justify-center gap-4"
    >
      <div class="text-sm text-gray-600">
        第 {{ page + 1 }} 页 / 共 {{ totalPages }} 页 · 共 {{ totalElements }} 篇文章
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
