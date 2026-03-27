<script setup lang="ts">
const api = useApi()

const username = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const submit = async () => {
  if (!username.value.trim()) {
    errorMessage.value = '用户名不能为空'
    return
  }

  if (!password.value.trim()) {
    errorMessage.value = '密码不能为空'
    return
  }

  try {
    loading.value = true
    errorMessage.value = ''
    successMessage.value = ''

    const data = await api<{ username: string }>('/api/register', {
      method: 'POST',
      body: {
        username: username.value,
        password: password.value
      }
    })

    successMessage.value = `注册成功：${data.username}`

    setTimeout(() => {
      window.location.href = '/login'
    }, 800)
  } catch (error: any) {
    errorMessage.value = error?.message || '注册失败'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center px-4 py-10">
    <div class="w-full max-w-md rounded-2xl border border-gray-200 bg-white p-8 shadow-sm">
      <div class="mb-8 text-center">
        <h1 class="text-3xl font-bold text-gray-900">注册</h1>
        <p class="mt-2 text-sm text-gray-600">创建账号后即可登录并开始写文章</p>
      </div>

      <div class="space-y-5">
        <div>
          <label class="mb-2 block text-sm font-medium text-gray-700">用户名</label>
          <input
            v-model="username"
            type="text"
            placeholder="请输入用户名"
            class="w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-gray-700">密码</label>
          <input
            v-model="password"
            type="password"
            placeholder="请输入密码"
            class="w-full rounded-xl border border-gray-300 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <button
          @click="submit"
          :disabled="loading"
          class="w-full rounded-xl bg-gray-900 px-4 py-3 text-white transition hover:bg-gray-800 disabled:opacity-50"
        >
          {{ loading ? '注册中...' : '立即注册' }}
        </button>

        <p v-if="successMessage" class="text-sm text-green-600">
          {{ successMessage }}
        </p>

        <p v-if="errorMessage" class="text-sm text-red-600">
          {{ errorMessage }}
        </p>
      </div>

      <div class="mt-8 border-t border-gray-200 pt-6 text-center text-sm text-gray-600">
        已经有账号？
        <NuxtLink to="/login" class="font-medium text-blue-600 hover:text-blue-700">
          去登录
        </NuxtLink>
      </div>
    </div>
  </div>
</template>