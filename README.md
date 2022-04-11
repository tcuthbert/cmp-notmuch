# notmuch address source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

Quick hack to get notmuch addresses as a neovim completion source. This is
how I have it configured. Hopefully it works for you too.

```lua
cmp.setup.filetype('mail', {
  sources = cmp.config.sources({
    { name = 'notmuch', option = { domains = { 'work.domain' } } },
  }, {
    { name = 'emoji' },
  })
})
```
