local ok, cmp = pcall(require, 'cmp')
if ok then cmp.register_source('notmuch', require('cmp_notmuch').new()) end
