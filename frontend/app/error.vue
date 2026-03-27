<script setup lang="ts">
const props = defineProps<{
  error: {
    statusCode?: number
    statusMessage?: string
    message?: string
  }
}>()

const handleClearError = () => clearError({ redirect: '/' })

const title = computed(() => {
  if (props.error?.statusCode === 404) return '页面不存在'
  if (props.error?.statusCode === 401) return '没有访问权限'
  if (props.error?.statusCode === 500) return '服务器开小差了'
  return '页面出错了'
})

const description = computed(() => {
  if (props.error?.statusCode === 404) {
    return '你访问的页面可能已被删除、改名，或者地址输入有误。'
  }
  if (props.error?.statusCode === 401) {
    return '当前请求未通过验证，请重新登录后再试。'
  }
  if (props.error?.statusCode === 500) {
    return '服务器暂时无法处理这个请求，可以稍后再试。'
  }
  return props.error?.statusMessage || props.error?.message || '发生了未知错误。'
})
</script>

<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center px-4">
    <div class="w-full max-w-2xl rounded-3xl border border-gray-200 bg-white p-8 md:p-12 shadow-sm text-center">
      <div class="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-red-50 text-red-600 text-3xl font-bold">
        {{ error?.statusCode || '!' }}
      </div>

      <h1 class="text-3xl md:text-4xl font-bold text-gray-900">
        {{ title }}
      </h1>

      <p class="mt-4 text-gray-600 leading-7">
        {{ description }}
      </p>

      <div class="mt-8 flex flex-wrap justify-center gap-3">
        <button
          @click="handleClearError"
          class="rounded-xl bg-gray-900 px-5 py-3 text-white hover:bg-gray-800 transition"
        >
          返回首页
        </button>

        <button
          @click="$router.back()"
          class="rounded-xl border border-gray-300 bg-white px-5 py-3 text-gray-700 hover:bg-gray-50 transition"
        >
          返回上一页
        </button>
      </div>
    </div>
  </div>
</template>