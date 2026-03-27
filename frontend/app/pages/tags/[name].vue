<script setup lang="ts">
const route = useRoute()
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
const posts = ref<PostItem[]>([])

const tagName = computed(() => decodeURIComponent(String(route.params.name || '')))

const splitTags = (raw: string | null | undefined) => {
  return (raw || '')
    .split(/[,，、。;；|｜]/)
    .map(tag => tag.trim())
    .filter(Boolean)
}

const loadPosts = async () => {
  loading.value = true
  errorMessage.value = ''
  posts.value = []

  try {
    const data = await api<{
      list: PostItem[]
      page: number
      totalPages: number
      totalElements: number
      size: number
    }>('/api/posts?page=0&size=100&keyword=')

    posts.value = (data.list || []).filter(post => {
      const tagList = splitTags(post.tags)
      return tagList.includes(tagName.value)
    })
  } catch (error: any) {
    errorMessage.value = error?.message || '加载标签文章失败'
  } finally {
    loading.value = false
  }
}

onMounted(loadPosts)
watch(() => route.params.name, loadPosts)
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <div class="max-w-6xl mx-auto px-4 py-8">
      <div class="mb-8">
        <NuxtLink to="/tags" class="text-sm text-blue-600 hover:text-blue-700">
          ← 返回标签
        </NuxtLink>
        <h1 class="mt-3 text-3xl font-bold text-gray-900">标签：{{ tagName }}</h1>
        <p class="mt-2 text-gray-600">该标签下的文章列表</p>
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
        v-else-if="posts.length === 0"
        title="该标签下还没有文章"
        description="你可以返回标签页继续浏览其他主题。"
       action-text="返回标签列表"
        action-to="/tags"
      />

      <div v-else class="grid gap-6">
        <article
          v-for="post in posts"
          :key="post.id"
          class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm"
        >
          <div class="md:flex">
            <div v-if="post.coverImage" class="md:w-72 shrink-0 bg-gray-100">
              <img :src="post.coverImage" alt="封面图" class="h-56 w-full object-cover md:h-full" />
            </div>

            <div class="flex-1 p-6">
              <NuxtLink :to="`/posts/${post.id}`" class="block">
                <h2 class="text-2xl font-semibold text-gray-900 hover:text-blue-600 transition">
                  {{ post.title }}
                </h2>
              </NuxtLink>

              <p class="mt-3 text-gray-600 leading-7">
                {{ post.summary }}
              </p>

              <div class="mt-4 flex flex-wrap gap-2 text-sm">
                <span class="rounded-full bg-gray-100 px-3 py-1 text-gray-700">
                  作者：{{ post.author || '未知作者' }}
                </span>
                <span class="rounded-full bg-blue-50 px-3 py-1 text-blue-700">
                  分类：{{ post.category || '未分类' }}
                </span>
                <span class="rounded-full bg-green-50 px-3 py-1 text-green-700">
                  标签：{{ post.tags || '无标签' }}
                </span>
              </div>

              <div class="mt-5">
                <NuxtLink
                  :to="`/posts/${post.id}`"
                  class="inline-flex items-center rounded-lg border border-gray-300 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition"
                >
                  阅读全文
                </NuxtLink>
              </div>
            </div>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>