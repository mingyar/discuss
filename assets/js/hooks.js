export const Hooks = {
  ScrollToBottom: {
    mounted() {
      this.scrollToBottom()
    },
    updated() {
      this.scrollToBottom()
    },
    scrollToBottom() {
      this.el.scrollTop = this.el.scrollHeight
    }
  },

  AutoFocus: {
    mounted() {
      this.el.focus()
    }
  },

  FadeIn: {
    mounted() {
      this.el.classList.add('opacity-0')
      requestAnimationFrame(() => {
        this.el.classList.remove('opacity-0')
        this.el.classList.add('opacity-100', 'transition-opacity', 'duration-500')
      })
    }
  }
}
