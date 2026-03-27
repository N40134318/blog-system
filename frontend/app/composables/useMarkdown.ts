// @ts-ignore
import MarkdownIt from 'markdown-it'
// @ts-ignore
import hljs from 'highlight.js'
import mermaid from 'mermaid'

/* ---------------- 工具函数 ---------------- */

const slugify = (text: string) => {
	return text
		.trim()
		.toLowerCase()
		.replace(/[^\w\u4e00-\u9fa5\s-]/g, '')
		.replace(/\s+/g, '-')
}

const escapeHtml = (str: string) => {
	return str
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;')
		.replace(/'/g, '&#39;')
}

const normalizeLang = (lang: string) => {
	const value = (lang || '').trim().toLowerCase()
	return value || 'text'
}

const buildLineNumbers = (str: string) => {
	const lineCount = Math.max(1, str.replace(/\n$/, '').split('\n').length)
	return Array.from({ length: lineCount }, (_, i) => `<span>${i + 1}</span>`).join('')
}

/* ---------------- Mermaid 初始化 ---------------- */

mermaid.initialize({
	startOnLoad: false,
	theme: 'default'
})

let mermaidId = 0

/* ---------------- Markdown 配置 ---------------- */

const markdownOptions: any = {
	html: false,
	linkify: true,
	typographer: true,
	breaks: true,

	highlight(str: string, lang: string) {
		const normalizedLang = normalizeLang(lang)

		/* 🔥 Mermaid 特殊处理 */
		if (normalizedLang === 'mermaid') {
			const id = `mermaid-${mermaidId++}`
			return `<div class="mermaid" id="${id}">${escapeHtml(str)}</div>`
		}

		const encodedRawCode = encodeURIComponent(str)
		const lineNumbers = buildLineNumbers(str)

		if (lang && hljs.getLanguage(lang)) {
			try {
				const highlighted = hljs.highlight(str, {
					language: lang
				}).value

				return `
<div class="code-block" data-code="${encodedRawCode}">
  <div class="code-block-header">
    <button type="button" class="code-copy-btn">复制</button>
    <span class="code-block-lang">${escapeHtml(normalizedLang)}</span>
  </div>
  <div class="code-block-body">
    <div class="code-line-numbers">${lineNumbers}</div>
    <pre><code class="hljs language-${escapeHtml(normalizedLang)}">${highlighted}</code></pre>
  </div>
</div>
        `.trim()
			} catch (error) { }
		}

		return `
<div class="code-block" data-code="${encodedRawCode}">
  <div class="code-block-header">
    <button type="button" class="code-copy-btn">复制</button>
    <span class="code-block-lang">${escapeHtml(normalizedLang)}</span>
  </div>
  <div class="code-block-body">
    <div class="code-line-numbers">${lineNumbers}</div>
    <pre><code class="hljs language-${escapeHtml(normalizedLang)}">${escapeHtml(str)}</code></pre>
  </div>
</div>
    `.trim()
	}
}

const md = new MarkdownIt(markdownOptions)

/* ---------------- 标题锚点 ---------------- */

const renderer = (md as any).renderer

const defaultHeadingOpen =
	renderer.rules.heading_open ||
	((tokens: any[], idx: number, options: any, env: any, self: any) => {
		return self.renderToken(tokens, idx, options)
	})

renderer.rules.heading_open = (
	tokens: any[],
	idx: number,
	options: any,
	env: any,
	self: any
) => {
	const titleToken = tokens[idx + 1]
	const title = titleToken?.content || ''
	const slug = slugify(title)

	tokens[idx].attrSet('id', slug)

	return defaultHeadingOpen(tokens, idx, options, env, self)
}

/* ---------------- 主渲染函数 ---------------- */

export const renderMarkdown = (content: string) => {
	return md.render(content || '')
}

/* ---------------- Mermaid 执行函数（关键） ---------------- */

export const renderMermaid = async () => {
	await mermaid.run({
		querySelector: '.mermaid'
	})
}

/* ---------------- TOC ---------------- */

export type TocItem = {
	id: string
	text: string
	level: number
}

export const extractToc = (content: string): TocItem[] => {
	const lines = (content || '').split('\n')
	const toc: TocItem[] = []

	for (const line of lines) {
		const match = /^(#{1,3})\s+(.+)$/.exec(line.trim())
		if (!match) continue

		const level = match[1]!.length
		const text = match[2]!.trim()

		toc.push({
			id: slugify(text),
			text,
			level
		})
	}

	return toc
}