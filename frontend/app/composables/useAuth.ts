export const useAuth = () => {
    const accessToken = useState<string | null>('accessToken', () => null)
    const refreshToken = useState<string | null>('refreshToken', () => null)
    const role = useState<string | null>('role', () => null)

    const setTokens = (access: string, refresh: string, nextRole?: string | null) => {
        accessToken.value = access
        refreshToken.value = refresh
        role.value = nextRole || null

        if (import.meta.client) {
            localStorage.setItem('accessToken', access)
            localStorage.setItem('refreshToken', refresh)

            if (nextRole) {
                localStorage.setItem('role', nextRole)
            } else {
                localStorage.removeItem('role')
            }
        }
    }

    const loadTokens = () => {
        if (!import.meta.client) return

        accessToken.value = localStorage.getItem('accessToken')
        refreshToken.value = localStorage.getItem('refreshToken')
        role.value = localStorage.getItem('role')
    }

    const clearTokens = () => {
        accessToken.value = null
        refreshToken.value = null
        role.value = null

        if (import.meta.client) {
            localStorage.removeItem('accessToken')
            localStorage.removeItem('refreshToken')
            localStorage.removeItem('role')
            localStorage.removeItem('token')
        }
    }

    const logout = async () => {
        try {
            const config = useRuntimeConfig()
            const apiBase = config.public.apiBase
            const token = import.meta.client ? localStorage.getItem('accessToken') : null

            if (token) {
                await $fetch(`${apiBase}/api/logout`, {
                    method: 'POST',
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                })
            }
        } catch {
            // 忽略后端退出异常
        } finally {
            clearTokens()
            if (import.meta.client) {
                window.location.href = `/login?t=${Date.now()}`
            }
        }
    }

    return {
        accessToken,
        refreshToken,
        role,
        setTokens,
        loadTokens,
        clearTokens,
        logout
    }
}
