declare module 'markdown-it' {
  class MarkdownIt {
    constructor(options?: {
      html?: boolean
      linkify?: boolean
      typographer?: boolean
      breaks?: boolean
    })

    render(src: string): string
  }

  export default MarkdownIt
}