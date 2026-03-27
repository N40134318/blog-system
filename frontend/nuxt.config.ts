declare const process: {
    env: Record<string, string | undefined>
}

export default defineNuxtConfig({
    css: ['@/assets/css/main.css'],

    runtimeConfig: {
        public: {
            appName:
                process.env.NUXT_PUBLIC_APP_NAME || 'Rainstorm Dev Platform',
            apiBase:
                process.env.NUXT_PUBLIC_API_BASE || 'https://dev.rainstorm.space'
        }
    },

    routeRules: {
        '/dashboard': { ssr: false },
        '/dashboard/**': { ssr: false },
        '/my-posts': { ssr: false },
        '/create-post': { ssr: false },
        '/edit-post/**': { ssr: false },
        '/login': { ssr: false },
        '/register': { ssr: false }
    },

    vite: {
        server: {
            allowedHosts: ['dev.rainstorm.space']
        },
        optimizeDeps: {
            include: ['markdown-it', 'highlight.js']
        }
    },

    modules: ['@nuxtjs/tailwindcss']
})
