scriptencoding utf-8
" vim:set ts=8 sts=2 sw=2 tw=0:

" MIT License
" 
" Copyright (c) 2016 Yuta Taniguchi
" 
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
" 
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.
"=============================================================================
" File: comfortable_motion.vim
" Author: Yuta Taniguchi
" Created: 2016-10-02
"=============================================================================

if !exists('g:loaded_comfortable_motion')
    "finish
endif
let g:loaded_comfortable_motion = 1

let s:save_cpo = &cpo
set cpo&vim


" Default parameter values
"if !exists('g:comfortable_motion_interval')
  let g:comfortable_motion_interval = 1000.0 / 60
"endif
if !exists('g:comfortable_motion_friction')
  let g:comfortable_motion_friction = 80.0
endif
if !exists('g:comfortable_motion_air_drag')
  let g:comfortable_motion_air_drag = 2.0
endif
if !exists('g:comfortable_motion_scroll_down_key')
  let g:comfortable_motion_scroll_down_key = "\<C-e>"
endif
if !exists('g:comfortable_motion_scroll_up_key')
  let g:comfortable_motion_scroll_up_key = "\<C-y>"
endif

" The state
let s:comfortable_motion_state = {
\ 'impulse': 0.0,
\ 'velocity': 0.0,
\ 'delta': 0.0,
\ 'save_scrolloff': 0,
\ 'save_cursorline': -1,
\ 'save_cursorcolumn': -1,
\ }

augroup comfortable_motion
  au!
  au WinLeave * let s:comfortable_motion_state.velocity = 0.0
  au WinLeave * let s:comfortable_motion_state.impulse = 0.0
  au WinLeave * if exists('s:timer_id') | call timer_stop(s:timer_id) | unlet s:timer_id | endif
augroup end

function! s:tick(timer_id)
  let l:st = s:comfortable_motion_state  " This is just an alias for the global variable
  if abs(l:st.velocity) >= 1 || l:st.impulse != 0 " short-circuit if velocity is less than one
    let l:dt = g:comfortable_motion_interval / 1000.0  " Unit conversion: ms -> s

    " Compute resistance forces
    let l:vel_sign = l:st.velocity == 0
      \            ? 0
      \            : l:st.velocity / abs(l:st.velocity)
    let l:friction = -l:vel_sign * g:comfortable_motion_friction * 1  " The mass is 1
    let l:air_drag = -l:st.velocity * g:comfortable_motion_air_drag
    let l:additional_force = l:friction + l:air_drag

    " Update the state
    let l:st.delta += l:st.velocity * l:dt
    let l:st.velocity += l:st.impulse + (abs(l:additional_force * l:dt) > abs(l:st.velocity) ? -l:st.velocity : l:additional_force * l:dt)
    let l:st.impulse = 0

    " Scroll
    let l:int_delta = float2nr(l:st.delta >= 0 ? floor(l:st.delta) : ceil(l:st.delta))
    let l:st.delta -= l:int_delta
    if l:int_delta > 0
      execute "normal! " . string(abs(l:int_delta)) . g:comfortable_motion_scroll_down_key
    elseif l:int_delta < 0
      execute "normal! " . string(abs(l:int_delta)) . g:comfortable_motion_scroll_up_key
    else
      " Do nothing
    endif
    redraw
  else
    call s:stop()
    redraw
  endif
endfunction

function! s:stop()
  let st = s:comfortable_motion_state  " This is just an alias for the global variable
  " Stop scrolling and the thread
  let st.velocity = 0
  let st.delta = 0
  let &scrolloff = st.save_scrolloff
  let &cursorline = st.save_cursorline
  let &cursorcolumn = st.save_cursorcolumn
endfunction

function! comfortable_motion#flick(impulse)
  let st = s:comfortable_motion_state  " This is just an alias for the global variable

  " save
  let st.save_scrolloff = &scrolloff
  let st.save_cursorline = &cursorline
  let st.save_cursorcolumn = &cursorcolumn

  " set
  normal! M
  let &scrolloff = 9999

  " start
  let st.impulse += a:impulse
  if !exists('s:timer_id')
    " There is no thread, start one
    let l:interval = float2nr(round(g:comfortable_motion_interval))
    let s:timer_id = timer_start(l:interval, function("s:tick"), {'repeat': -1})
  endif

  " loop
  while 1
    set nocursorline
    set nocursorcolumn

    let c = getchar()
    let k = nr2char(c)

    if    k != "\<Space>" && k != "\<C-e>" && k != "j" && a:impulse > 0
     \ || c != "\<S-Space>" && k != "\<C-y>" && k != "k" && a:impulse < 0
     \ || line('w$') == line('$') && a:impulse > 0
     \ || line('w0') == line('0') && a:impulse < 0
      break
    endif

    let st.impulse += a:impulse
  endwhile

  " finish
  call timer_stop(s:timer_id)
  unlet s:timer_id
  call s:stop()
  if k != "\<Space>" && c != "\<S-Space>" && k != "\<C-e>" && k != "\<C-y>" && k != "j" && k != "k"
    call feedkeys(k, 'm')
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
