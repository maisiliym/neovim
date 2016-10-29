-- ShaDa marks saving/reading support
local helpers = require('test.functional.helpers')(after_each)
local meths, curwinmeths, curbufmeths, nvim_command, funcs, eq =
  helpers.meths, helpers.curwinmeths, helpers.curbufmeths, helpers.command,
  helpers.funcs, helpers.eq
local exc_exec, redir_exec = helpers.exc_exec, helpers.redir_exec

local shada_helpers = require('test.functional.shada.helpers')
local reset, set_additional_cmd, clear =
  shada_helpers.reset, shada_helpers.set_additional_cmd,
  shada_helpers.clear

local nvim_current_line = function()
  return curwinmeths.get_cursor()[1]
end

if helpers.pending_win32(pending) then return end

describe('ShaDa support code', function()
  local testfilename = 'Xtestfile-functional-shada-marks'
  local testfilename_2 = 'Xtestfile-functional-shada-marks-2'
  before_each(function()
    reset()
    local fd = io.open(testfilename, 'w')
    fd:write('test\n')
    fd:write('test2\n')
    fd:close()
    fd = io.open(testfilename_2, 'w')
    fd:write('test3\n')
    fd:write('test4\n')
    fd:close()
  end)
  after_each(function()
    clear()
    os.remove(testfilename)
    os.remove(testfilename_2)
  end)

  it('is able to dump and read back global mark', function()
    nvim_command('edit ' .. testfilename)
    nvim_command('mark A')
    nvim_command('2')
    nvim_command('kB')
    nvim_command('wshada')
    reset()
    nvim_command('rshada')
    nvim_command('normal! `A')
    eq(testfilename, funcs.fnamemodify(curbufmeths.get_name(), ':t'))
    eq(1, nvim_current_line())
    nvim_command('normal! `B')
    eq(2, nvim_current_line())
  end)

  it('does not dump global mark with `f0` in shada', function()
    nvim_command('set shada+=f0')
    nvim_command('edit ' .. testfilename)
    nvim_command('mark A')
    nvim_command('2')
    nvim_command('kB')
    nvim_command('wshada')
    reset()
    nvim_command('language C')
    eq('Vim(normal):E20: Mark not set', exc_exec('normal! `A'))
  end)

  it('does read back global mark even with `\'0` and `f0` in shada', function()
    nvim_command('edit ' .. testfilename)
    nvim_command('mark A')
    nvim_command('2')
    nvim_command('kB')
    nvim_command('wshada')
    set_additional_cmd('set shada=\'0,f0')
    reset()
    nvim_command('language C')
    nvim_command('normal! `A')
    eq(testfilename, funcs.fnamemodify(curbufmeths.get_name(), ':t'))
    eq(1, nvim_current_line())
  end)

  it('is able to dump and read back local mark', function()
    nvim_command('edit ' .. testfilename)
    nvim_command('mark a')
    nvim_command('2')
    nvim_command('kb')
    nvim_command('qall')
    reset()
    nvim_command('edit ' .. testfilename)
    nvim_command('normal! `a')
    eq(testfilename, funcs.fnamemodify(curbufmeths.get_name(), ':t'))
    eq(1, nvim_current_line())
    nvim_command('normal! `b')
    eq(2, nvim_current_line())
  end)

  it('is able to dump and read back mark "', function()
    nvim_command('edit ' .. testfilename)
    nvim_command('2')
    nvim_command('qall')
    reset()
    nvim_command('edit ' .. testfilename)
    nvim_command('normal! `"')
    eq(2, nvim_current_line())
  end)

  it('is able to dump and read back mark " from a closed tab', function()
    nvim_command('edit ' .. testfilename)
    nvim_command('tabedit ' .. testfilename_2)
    nvim_command('2')
    nvim_command('q!')
    nvim_command('qall')
    reset()
    nvim_command('edit ' .. testfilename_2)
    nvim_command('normal! `"')
    eq(2, nvim_current_line())
  end)

  it('is able to populate v:oldfiles', function()
    nvim_command('edit ' .. testfilename)
    local tf_full = curbufmeths.get_name()
    nvim_command('edit ' .. testfilename_2)
    local tf_full_2 = curbufmeths.get_name()
    nvim_command('qall')
    reset()
    local oldfiles = meths.get_vvar('oldfiles')
    table.sort(oldfiles)
    eq(2, #oldfiles)
    eq(testfilename, oldfiles[1]:sub(-#testfilename))
    eq(testfilename_2, oldfiles[2]:sub(-#testfilename_2))
    eq(tf_full, oldfiles[1])
    eq(tf_full_2, oldfiles[2])
    nvim_command('rshada!')
    oldfiles = meths.get_vvar('oldfiles')
    table.sort(oldfiles)
    eq(2, #oldfiles)
    eq(testfilename, oldfiles[1]:sub(-#testfilename))
    eq(testfilename_2, oldfiles[2]:sub(-#testfilename_2))
    eq(tf_full, oldfiles[1])
    eq(tf_full_2, oldfiles[2])
  end)

  it('is able to dump and restore jump list', function()
    nvim_command('edit ' .. testfilename_2)
    nvim_command('normal! G')
    nvim_command('normal! gg')
    nvim_command('edit ' .. testfilename)
    nvim_command('normal! G')
    nvim_command('normal! gg')
    nvim_command('enew')
    nvim_command('normal! gg')
    local saved = redir_exec('jumps')
    nvim_command('qall')
    reset()
    eq(saved, redir_exec('jumps'))
  end)

  it('is able to dump and restore jump list with different times (slow!)',
  function()
    nvim_command('edit ' .. testfilename_2)
    nvim_command('sleep 2')
    nvim_command('normal! G')
    nvim_command('sleep 2')
    nvim_command('normal! gg')
    nvim_command('sleep 2')
    nvim_command('edit ' .. testfilename)
    nvim_command('sleep 2')
    nvim_command('normal! G')
    nvim_command('sleep 2')
    nvim_command('normal! gg')
    nvim_command('qall')
    reset()
    nvim_command('redraw')
    nvim_command('edit ' .. testfilename)
    eq(testfilename, funcs.bufname('%'))
    eq(1, nvim_current_line())
    nvim_command('execute "normal! \\<C-o>"')
    eq(testfilename, funcs.bufname('%'))
    eq(1, nvim_current_line())
    nvim_command('execute "normal! \\<C-o>"')
    eq(testfilename, funcs.bufname('%'))
    eq(2, nvim_current_line())
    nvim_command('execute "normal! \\<C-o>"')
    eq(testfilename_2, funcs.bufname('%'))
    eq(1, nvim_current_line())
    nvim_command('execute "normal! \\<C-o>"')
    eq(testfilename_2, funcs.bufname('%'))
    eq(2, nvim_current_line())
  end)

  it('is able to dump and restore change list', function()
    nvim_command('edit ' .. testfilename)
    nvim_command('normal! Gra')
    nvim_command('normal! ggrb')
    nvim_command('qall!')
    reset()
    nvim_command('edit ' .. testfilename)
    nvim_command('normal! Gg;')
    -- Note: without “sync” “commands” test has good changes to fail for unknown 
    -- reason (in first eq expected 1 is compared with 2). Any command inserted 
    -- causes this to work properly.
    nvim_command('" sync')
    eq(1, nvim_current_line())
    nvim_command('normal! g;')
    nvim_command('" sync 2')
    eq(2, nvim_current_line())
  end)
end)
