" Win32 registry editing.
" Uses URL notation file names of the form:  registry://HIVE/key
" I.e.
"             registry://HKCR/.vim
"
if(has('win32') && has('perl'))
  augroup Registry
  au BufReadCmd,FileReadCmd registry://* runtime ftplugin/registryedit.vim | call RegistryRead (expand('<afile>'))
  au BufWriteCmd            registry://* runtime ftplugin/registryedit.vim | call RegistryWrite(expand('<afile>'))
  augroup END
endif  " of has('win32')

