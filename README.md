usage:

for best effects, set the concealcursor/level for the filetypes you wish to use
the plugin with.
```vim
autocmd FileType tex set conceallevel=2 concealcursor=nciv
```

setup:
```lua
require("inline-conceal").setup {
  extra_symbol_map = {
    tex = {
      {"\\R", "ℝ"},
      {"\\N", "ℕ"},
      {"\\Z", "ℤ"},
      {"\\Q", "ℚ"},
    }
  }
}
```

install w/ any plugin manager
