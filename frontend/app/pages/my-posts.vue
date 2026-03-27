<script setup lang="ts">
definePageMeta({
  middleware: 'auth'
})

import { computed } from 'vue'
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

const splitTags = (raw: string | null | undefined) => {
  return (raw || '')
    .split(/[,，、。;；|｜]/)
    .map(tag => tag.trim())
    .filter(Boolean)
}

const formatTime = (timestamp: number | null | undefined) => {
  if (!timestamp) return '暂无时间'
  return new Date(timestamp).toLocaleString()
}

const posts = ref<PostItem[]>([])
const loading = ref(true)
const errorMessage = ref('')
const keyword = ref('')
const page = ref(0)
const size = ref(5)
const totalPages = ref(0)
const currentUsername = ref('')
const statusFilter = ref<StatusFilter>('all')

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
  posts.value = []
  totalPages.value = 0

  try {
    const me = await api<{ username: string }>('/api/auth/me')
    currentUsername.value = me.username

    const query = new URLSearchParams({
      page: String(page.value),
      size: String(size.value),
      keyword: keyword.value
    })

    const data = await api<PageResponse>(`/api/posts/my?${query.toString()}`)

    posts.value = data.list || []
    totalPages.value = data.totalPages || 0
  } catch (e: any) {
    errorMessage.value = e?.message || '加载失败'
  } finally {
    loading.value = false
  }
}

const search = async () => {
  page.value = 0
  await loadPosts()
}

const prevPage = async () => {
  if (page.value > 0) {
    page.value--
    await loadPosts()
  }
}

const nextPage = async () => {
  if (page.value < totalPages.value - 1) {
    page.value++
    await loadPosts()
  }
}

const setStatusFilter = (value: StatusFilter) => {
  statusFilter.value = value
}

onMounted(loadPosts)
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-6xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">我的文章</h1>
        <p class="mt-2 text-gray-600">管理和查看我的草稿与已发布内容</p>
        <p v-if="currentUsername" class="mt-2 text-sm text-blue-600">
          当前登录用户：{{ currentUsername }}
        </p>
      </div>

      <div class="bg-white rounded-2xl shadow-sm border border-gray-200 p-4 mb-6 space-y-4">
        <div class="flex flex-col md:flex-row gap-3">
          <input
            v-model="keyword"
            placeholder="搜索我的文章"
            class="flex-1 rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button
            @click="search"
            class="rounded-xl bg-gray-900 text-white px-5 py-3 hover:bg-gray-800 transition"
          >
            搜索
          </button>
        </div>

        <div class="flex flex-wrap gap-3">
          <button
            @click="setStatusFilter('all')"
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
            @click="setStatusFilter('draft')"
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
            @click="setStatusFilter('published')"
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

      <div v-if="loading" class="text-gray-500 py-10">
        加载中...
      </div>

      <div v-else-if="errorMessage" class="bg-red-50 text-red-600 border border-red-200 rounded-xl p-4">
        {{ errorMessage }}
      </div>

      <EmptyState
        v-else-if="posts.length === 0"
        title="你还没有文章"
        description="先保存一篇草稿，或者直接发布第一篇文章。"
        action-text="去写文章"
        action-to="/create-post"
      />

      <EmptyState
        v-else-if="filteredPosts.length === 0"
        title="当前筛选下没有文章"
        description="试试切换筛选条件，或者去创建新的文章。"
        action-text="去写文章"
        action-to="/create-post"
      />

      <div v-else class="grid gap-6">
        <article
          v-for="post in filteredPosts"
          :key="post.id"
          class="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden"
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

            <div class="flex-1 p-6">
              <div class="flex flex-wrap items-center gap-3">
                <NuxtLink :to="`/posts/${post.id}`" class="block group">
                  <h2 class="text-2xl font-semibold text-gray-900 group-hover:text-blue-600 transition">
                    {{ post.title }}
                  </h2>
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

                <span
                  v-else
                  class="inline-flex rounded-full bg-gray-100 px-3 py-1 text-xs text-gray-600"
                >
                  未知状态
                </span>
              </div>

              <p class="mt-3 text-gray-600 leading-7">
                {{ post.summary }}
              </p>

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

              <div class="mt-4 text-sm text-gray-500 space-y-1">
                <div>创建时间：{{ formatTime(post.createdAt) }}</div>
                <div>更新时间：{{ formatTime(post.updatedAt) }}</div>
                <div>阅读量：{{ post.viewCount ?? 0 }}</div>
                <div>权重：{{ post.weight ?? 0 }}</div>
              </div>

              <div class="mt-5 flex gap-3">
                <NuxtLink
                  :to="`/posts/${post.id}`"
                  class="inline-flex items-center rounded-lg border border-gray-300 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition"
                >
                  查看详情
                </NuxtLink>

                <NuxtLink
                  :to="`/edit-post/${post.id}`"
                  class="inline-flex items-center rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800 transition"
                >
                  编辑文章
                </NuxtLink>
              </div>
            </div>
          </div>
        </article>
      </div>

      <div
        v-if="totalPages > 0"
        class="mt-8 flex items-center justify-center gap-3"
      >
        <button
          @click="prevPage"
          :disabled="page === 0"
          class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-700 disabled:opacity-50"
        >
          上一页
        </button>

        <div class="text-gray-700">
          第 {{ page + 1 }} 页 / 共 {{ totalPages }} 页
        </div>

        <button
          @click="nextPage"
          :disabled="page >= totalPages - 1"
          class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-700 disabled:opacity-50"
        >
          下一页
        </button>
      </div>
    </div>
  </div>
</template>
