"=============================================================================
" File: comfortable_motion.vim
" Author: Yuta Taniguchi
" Created: 2016-10-02
"=============================================================================

scriptencoding utf-8

if exists('g:loaded_comfortable_motion')
  "finish
endif
let g:loaded_comfortable_motion = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:comfortable_motion_no_default_key_mappings') ||
\  !g:comfortable_motion_no_default_key_mappings
  "nnoremap <silent> <C-d> :call comfortable_motion#flick(100)<CR>
  "nnoremap <silent> <C-u> :call comfortable_motion#flick(-100)<CR>

  "nnoremap <silent> <C-f> :call comfortable_motion#flick(200)<CR>
  "nnoremap <silent> <C-b> :call comfortable_motion#flick(-200)<CR>
endif


let g:comfortable_motion_no_default_key_mappings = v:true
let g:comfortable_motion_friction = 90.0 / 5.0
let g:comfortable_motion_air_drag = 6.0 / 5.0
let g:comfortable_motion_impulse_multiplier = 3.8  " Feel free to increase/decrease this value.
"nnoremap <silent> <C-e> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0)     )<CR>
"nnoremap <silent> <C-y> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * -1)<CR>
nnoremap <silent> gj    :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0)     )<CR>
nnoremap <silent> gk    :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * -1)<CR>


let &cpo = s:save_cpo
unlet s:save_cpo
