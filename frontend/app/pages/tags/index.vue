<script setup lang="ts">
const api = useApi()

type PostItem = {
  id: number
  title: string
  summary: string
  author: string | null
  category: string | null
  tags: string | null
  coverImage: string | null
}

const loading = ref(true)
const errorMessage = ref('')
const tags = ref<{ name: string; count: number }[]>([])

const splitTags = (raw: string | null | undefined) => {
  return (raw || '')
    .split(/[,，、。;；|｜]/)
    .map(tag => tag.trim())
    .filter(Boolean)
}

const goToTag = async (name: string) => {
  await navigateTo(`/tags/${encodeURIComponent(name)}`)
}

const loadTags = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const data = await api<{
      list: PostItem[]
      page: number
      totalPages: number
      totalElements: number
      size: number
    }>('/api/posts?page=0&size=100&keyword=')

    const map = new Map<string, number>()

    for (const post of data.list || []) {
      const tagList = splitTags(post.tags)

      for (const tag of tagList) {
        map.set(tag, (map.get(tag) || 0) + 1)
      }
    }

    tags.value = Array.from(map.entries())
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count)
  } catch (error: any) {
    errorMessage.value = error?.message || '加载标签失败'
  } finally {
    loading.value = false
  }
}

onMounted(loadTags)
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-6xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">标签</h1>
        <p class="mt-2 text-gray-600">按文章标签浏览内容</p>
      </div>

      <div v-if="loading" class="text-gray-500">
        加载中...
      </div>

      <div
        v-else-if="errorMessage"
        class="rounded-xl border border-red-200 bg-red-50 p-4 text-red-600"
      >
        {{ errorMessage }}
      </div>

      <EmptyState
        v-else-if="tags.length === 0"
        title="暂无标签数据"
        description="当前文章还没有形成可展示的标签。"
        action-text="浏览文章"
        action-to="/posts"
      />

      <div v-else class="flex flex-wrap gap-3">
        <button
          v-for="item in tags"
          :key="item.name"
          class="rounded-full border border-gray-200 bg-white px-4 py-2 text-sm text-gray-700 shadow-sm transition hover:border-blue-300 hover:text-blue-600"
          @click="goToTag(item.name)"
        >
          {{ item.name }}（{{ item.count }}）
        </button>
      </div>
    </div>
  </div>
</template>