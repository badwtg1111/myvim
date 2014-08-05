" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
ruby/command-t/controller.rb	[[[1
407
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/finder/buffer_finder'
require 'command-t/finder/jump_finder'
require 'command-t/finder/file_finder'
require 'command-t/finder/mru_buffer_finder'
require 'command-t/finder/tag_finder'
require 'command-t/match_window'
require 'command-t/prompt'
require 'command-t/vim/path_utilities'
require 'command-t/util'

module CommandT
  class Controller
    include VIM::PathUtilities

    def initialize
      @prompt = Prompt.new
    end

    def show_buffer_finder
      @path          = VIM::pwd
      @active_finder = buffer_finder
      show
    end

    def show_jump_finder
      @path          = VIM::pwd
      @active_finder = jump_finder
      show
    end

    def show_mru_finder
      @path          = VIM::pwd
      @active_finder = mru_finder
      show
    end

    def show_tag_finder
      @path          = VIM::pwd
      @active_finder = tag_finder
      show
    end

    def show_file_finder
      # optional parameter will be desired starting directory, or ""
      @path             = File.expand_path(::VIM::evaluate('a:arg'), VIM::pwd)
      @active_finder    = file_finder
      file_finder.path  = @path
      show
    rescue Errno::ENOENT
      # probably a problem with the optional parameter
      @match_window.print_no_such_file_or_directory
    end

    def hide
      @match_window.close
      if VIM::Window.select @initial_window
        if @initial_buffer.number == 0
          # upstream bug: buffer number misreported as 0
          # see: https://wincent.com/issues/1617
          ::VIM::command "silent b #{@initial_buffer.name}"
        else
          ::VIM::command "silent b #{@initial_buffer.number}"
        end
      end
    end

    # Take current matches and stick them in the quickfix window.
    def quickfix
      hide

      matches = @matches.map do |match|
        "{ 'filename': '#{VIM::escape_for_single_quotes match}' }"
      end.join(', ')

      ::VIM::command 'call setqflist([' + matches + '])'
      ::VIM::command 'cope'
    end

    def refresh
      return unless @active_finder && @active_finder.respond_to?(:flush)
      @active_finder.flush
      list_matches!
    end

    def flush
      @max_height   = nil
      @min_height   = nil
      @file_finder  = nil
      @tag_finder   = nil
    end

    def handle_key
      key = ::VIM::evaluate('a:arg').to_i.chr
      if @focus == @prompt
        @prompt.add! key
        @needs_update = true
      else
        @match_window.find key
      end
    end

    def backspace
      if @focus == @prompt
        @prompt.backspace!
        @needs_update = true
      end
    end

    def delete
      if @focus == @prompt
        @prompt.delete!
        @needs_update = true
      end
    end

    def accept_selection options = {}
      selection = @match_window.selection
      hide
      open_selection(selection, options) unless selection.nil?
    end

    def toggle_focus
      @focus.unfocus # old focus
      @focus = @focus == @prompt ? @match_window : @prompt
      @focus.focus # new focus
    end

    def cancel
      hide
    end

    def select_next
      @match_window.select_next
    end

    def select_prev
      @match_window.select_prev
    end

    def clear
      @prompt.clear!
      list_matches!
    end

    def cursor_left
      @prompt.cursor_left if @focus == @prompt
    end

    def cursor_right
      @prompt.cursor_right if @focus == @prompt
    end

    def cursor_end
      @prompt.cursor_end if @focus == @prompt
    end

    def cursor_start
      @prompt.cursor_start if @focus == @prompt
    end

    def leave
      @match_window.leave
    end

    def unload
      @match_window.unload
    end

    def list_matches(options = {})
      return unless @needs_update || options[:force]

      @matches = @active_finder.sorted_matches_for(
        @prompt.abbrev,
        :limit   => match_limit,
        :threads => CommandT::Util.processor_count
      )
      @match_window.matches = @matches

      @needs_update = false
    end

  private

    def list_matches!
      list_matches(:force => true)
    end

    def show
      @initial_window   = $curwin
      @initial_buffer   = $curbuf
      @match_window     = MatchWindow.new \
        :highlight_color      => get_string('g:CommandTHighlightColor'),
        :match_window_at_top  => get_bool('g:CommandTMatchWindowAtTop'),
        :match_window_reverse => get_bool('g:CommandTMatchWindowReverse'),
        :min_height           => min_height,
        :debounce_interval    => get_number('g:CommandTInputDebounce', 50),
        :prompt               => @prompt
      @focus            = @prompt
      @prompt.focus
      register_for_key_presses
      set_up_autocmds
      clear # clears prompt and lists matches
    end

    def max_height
      @max_height ||= get_number('g:CommandTMaxHeight', 0)
    end

    def min_height
      @min_height ||= begin
        min_height = get_number('g:CommandTMinHeight', 0)
        min_height = max_height if max_height != 0 && min_height > max_height
        min_height
      end
    end

    def get_number(name, default = nil)
      VIM::exists?(name) ? ::VIM::evaluate("#{name}").to_i : default
    end

    def get_bool(name)
      VIM::exists?(name) ? ::VIM::evaluate("#{name}").to_i != 0 : nil
    end

    def get_string(name)
      VIM::exists?(name) ? ::VIM::evaluate("#{name}").to_s : nil
    end

    # expect a string or a list of strings
    def get_list_or_string name
      return nil unless VIM::exists?(name)
      list_or_string = ::VIM::evaluate("#{name}")
      if list_or_string.kind_of?(Array)
        list_or_string.map { |item| item.to_s }
      else
        list_or_string.to_s
      end
    end

    # Backslash-escape space, \, |, %, #, "
    def sanitize_path_string str
      # for details on escaping command-line mode arguments see: :h :
      # (that is, help on ":") in the Vim documentation.
      str.gsub(/[ \\|%#"]/, '\\\\\0')
    end

    def default_open_command
      if !get_bool('&hidden') && get_bool('&modified')
        'sp'
      else
        'e'
      end
    end

    def ensure_appropriate_window_selection
      # normally we try to open the selection in the current window, but there
      # is one exception:
      #
      # - we don't touch any "unlisted" buffer with buftype "nofile" (such as
      #   NERDTree or MiniBufExplorer); this is to avoid things like the "Not
      #   enough room" error which occurs when trying to open in a split in a
      #   shallow (potentially 1-line) buffer like MiniBufExplorer is current
      #
      # Other "unlisted" buffers, such as those with buftype "help" are treated
      # normally.
      initial = $curwin
      while true do
        break unless ::VIM::evaluate('&buflisted').to_i == 0 &&
          ::VIM::evaluate('&buftype').to_s == 'nofile'
        ::VIM::command 'wincmd w'     # try next window
        break if $curwin == initial # have already tried all
      end
    end

    def open_selection selection, options = {}
      command = options[:command] || default_open_command
      selection = File.expand_path selection, @path
      selection = relative_path_under_working_directory selection
      selection = sanitize_path_string selection
      selection = File.join('.', selection) if selection =~ /^\+/
      ensure_appropriate_window_selection

      @active_finder.open_selection command, selection, options
    end

    def map key, function, param = nil
      ::VIM::command "noremap <silent> <buffer> #{key} " \
        ":call CommandT#{function}(#{param})<CR>"
    end

    def term
      @term ||= ::VIM::evaluate('&term')
    end

    def register_for_key_presses
      # "normal" keys (interpreted literally)
      numbers     = ('0'..'9').to_a.join
      lowercase   = ('a'..'z').to_a.join
      uppercase   = lowercase.upcase
      punctuation = '<>`@#~!"$%&/()=+*-_.,;:?\\\'{}[] ' # and space
      (numbers + lowercase + uppercase + punctuation).each_byte do |b|
        map "<Char-#{b}>", 'HandleKey', b
      end

      # "special" keys (overridable by settings)
      {
        'AcceptSelection'       => '<CR>',
        'AcceptSelectionSplit'  => ['<C-CR>', '<C-s>'],
        'AcceptSelectionTab'    => '<C-t>',
        'AcceptSelectionVSplit' => '<C-v>',
        'Backspace'             => '<BS>',
        'Cancel'                => ['<C-c>', '<Esc>'],
        'Clear'                 => '<C-u>',
        'CursorEnd'             => '<C-e>',
        'CursorLeft'            => ['<Left>', '<C-h>'],
        'CursorRight'           => ['<Right>', '<C-l>'],
        'CursorStart'           => '<C-a>',
        'Delete'                => '<Del>',
        'Quickfix'              => '<C-q>',
        'Refresh'               => '<C-f>',
        'SelectNext'            => ['<C-n>', '<C-j>', '<Down>'],
        'SelectPrev'            => ['<C-p>', '<C-k>', '<Up>'],
        'ToggleFocus'           => '<Tab>',
      }.each do |key, value|
        if override = get_list_or_string("g:CommandT#{key}Map")
          Array(override).each do |mapping|
            map mapping, key
          end
        else
          Array(value).each do |mapping|
            unless mapping == '<Esc>' && term =~ /\A(screen|xterm|vt100)/
              map mapping, key
            end
          end
        end
      end
    end

    def set_up_autocmds
      ::VIM::command 'augroup Command-T'
      ::VIM::command 'au!'
      ::VIM::command 'autocmd CursorHold <buffer> :call CommandTListMatches()'
      ::VIM::command 'augroup END'
    end

    # Returns the desired maximum number of matches, based on available
    # vertical space and the g:CommandTMaxHeight option.
    def match_limit
      limit = VIM::Screen.lines - 5
      limit = 1 if limit < 0
      limit = [limit, max_height].min if max_height > 0
      limit
    end

    def buffer_finder
      @buffer_finder ||= CommandT::BufferFinder.new
    end

    def mru_finder
      @mru_finder ||= CommandT::MRUBufferFinder.new
    end

    def file_finder
      @file_finder ||= CommandT::FileFinder.new nil,
        :max_depth              => get_number('g:CommandTMaxDepth'),
        :max_files              => get_number('g:CommandTMaxFiles'),
        :max_caches             => get_number('g:CommandTMaxCachedDirectories'),
        :always_show_dot_files  => get_bool('g:CommandTAlwaysShowDotFiles'),
        :never_show_dot_files   => get_bool('g:CommandTNeverShowDotFiles'),
        :scan_dot_directories   => get_bool('g:CommandTScanDotDirectories'),
        :wild_ignore            => get_string('g:CommandTWildIgnore'),
        :scanner                => get_string('g:CommandTFileScanner')
    end

    def jump_finder
      @jump_finder ||= CommandT::JumpFinder.new
    end

    def tag_finder
      @tag_finder ||= CommandT::TagFinder.new \
        :include_filenames => get_bool('g:CommandTTagIncludeFilenames')
    end
  end # class Controller
end # module CommandT
ruby/command-t/extconf.rb	[[[1
56
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'mkmf'

def header(item)
  unless find_header(item)
    puts "couldn't find #{item} (required)"
    exit 1
  end
end

# mandatory headers
header('float.h')
header('ruby.h')
header('stdlib.h')
header('string.h')

# optional headers (for CommandT::Watchman::Utils)
if have_header('fcntl.h') &&
  have_header('sys/errno.h') &&
  have_header('sys/socket.h')
  RbConfig::MAKEFILE_CONFIG['DEFS'] += ' -DWATCHMAN_BUILD'

  have_header('ruby/st.h') # >= 1.9; sets HAVE_RUBY_ST_H
  have_header('st.h')      # 1.8; sets HAVE_ST_H
end

# optional
if RbConfig::CONFIG['THREAD_MODEL'] == 'pthread'
  have_library('pthread', 'pthread_create') # sets HAVE_PTHREAD_H if found
end

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

create_makefile('ext')
ruby/command-t/finder/buffer_finder.rb	[[[1
35
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher
require 'command-t/scanner/buffer_scanner'
require 'command-t/finder'

module CommandT
  class BufferFinder < Finder
    def initialize
      @scanner = BufferScanner.new
      @matcher = Matcher.new @scanner, :always_show_dot_files => true
    end
  end # class BufferFinder
end # CommandT
ruby/command-t/finder/file_finder.rb	[[[1
51
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher
require 'command-t/finder'
require 'command-t/scanner/file_scanner/ruby_file_scanner'
require 'command-t/scanner/file_scanner/find_file_scanner'
require 'command-t/scanner/file_scanner/watchman_file_scanner'

module CommandT
  class FileFinder < Finder
    def initialize(path = Dir.pwd, options = {})
      case options.delete(:scanner)
      when 'ruby', nil # ruby is the default
        @scanner = FileScanner::RubyFileScanner.new(path, options)
      when 'find'
        @scanner = FileScanner::FindFileScanner.new(path, options)
      when 'watchman'
        @scanner = FileScanner::WatchmanFileScanner.new(path, options)
      else
        raise ArgumentError, "unknown scanner type '#{options[:scanner]}'"
      end

      @matcher = Matcher.new @scanner, options
    end

    def flush
      @scanner.flush
    end
  end # class FileFinder
end # module CommandT
ruby/command-t/finder/jump_finder.rb	[[[1
35
# Copyright 2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher
require 'command-t/scanner/jump_scanner'
require 'command-t/finder'

module CommandT
  class JumpFinder < Finder
    def initialize
      @scanner = JumpScanner.new
      @matcher = Matcher.new @scanner, :always_show_dot_files => true
    end
  end # class JumpFinder
end # module CommandT
ruby/command-t/finder/mru_buffer_finder.rb	[[[1
50
# Copyright 2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher
require 'command-t/scanner/mru_buffer_scanner'
require 'command-t/finder/buffer_finder'

module CommandT
  class MRUBufferFinder < BufferFinder
    # Override sorted_matches_for to prevent MRU ordered matches from being
    # ordered alphabetically.
    def sorted_matches_for str, options = {}
      matches = super(str, options.merge(:sort => false))

      # take current buffer (by definition, the most recently used) and move it
      # to the end of the results
      if MRU.stack.last &&
        relative_path_under_working_directory(MRU.stack.last.name) == matches.first
        matches[1..-1] + [matches.first]
      else
        matches
      end
    end

    def initialize
      @scanner = MRUBufferScanner.new
      @matcher = Matcher.new @scanner, :always_show_dot_files => true
    end
  end # class MRUBufferFinder
end # CommandT
ruby/command-t/finder/tag_finder.rb	[[[1
44
# Copyright 2011-2012 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher
require 'command-t/scanner/tag_scanner'
require 'command-t/finder'

module CommandT
  class TagFinder < Finder
    def initialize options = {}
      @scanner = TagScanner.new options
      @matcher = Matcher.new @scanner, :always_show_dot_files => true
    end

    def open_selection command, selection, options = {}
      if @scanner.include_filenames
        selection = selection[0, selection.index(':')]
      end

      #  open the tag and center the screen on it
      ::VIM::command "silent! tag #{selection} | :normal zz"
    end
  end # class TagFinder
end # module CommandT
ruby/command-t/finder.rb	[[[1
54
# Copyright 2010-2012 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher

module CommandT
  # Encapsulates a Scanner instance (which builds up a list of available files
  # in a directory) and a Matcher instance (which selects from that list based
  # on a search string).
  #
  # Specialized subclasses use different kinds of scanners adapted for
  # different kinds of search (files, buffers).
  class Finder
    include VIM::PathUtilities

    def initialize path = Dir.pwd, options = {}
      raise RuntimeError, 'Subclass responsibility'
    end

    # Options:
    #   :limit (integer): limit the number of returned matches
    def sorted_matches_for str, options = {}
      @matcher.sorted_matches_for str, options
    end

    def open_selection command, selection, options = {}
      ::VIM::command "silent #{command} #{selection}"
    end

    def path= path
      @scanner.path = path
    end
  end # class Finder
end # CommandT
ruby/command-t/match_window.rb	[[[1
446
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'ostruct'
require 'command-t/settings'

module CommandT
  class MatchWindow
    SELECTION_MARKER  = '> '
    MARKER_LENGTH     = SELECTION_MARKER.length
    UNSELECTED_MARKER = ' ' * MARKER_LENGTH
    MH_START          = '<commandt>'
    MH_END            = '</commandt>'
    @@buffer          = nil

    def initialize options = {}
      @highlight_color = options[:highlight_color] || 'PmenuSel'
      @min_height      = options[:min_height]
      @prompt          = options[:prompt]
      @reverse_list    = options[:match_window_reverse]

      # save existing window dimensions so we can restore them later
      @windows = []
      (0..(::VIM::Window.count - 1)).each do |i|
        @windows << OpenStruct.new(:index   => i,
                                   :height  => ::VIM::Window[i].height,
                                   :width   => ::VIM::Window[i].width)
      end

      set 'timeout', true        # ensure mappings timeout
      set 'hlsearch', false      # don't highlight search strings
      set 'insertmode', false    # don't make Insert mode the default
      set 'showcmd', false       # don't show command info on last line
      set 'equalalways', false   # don't auto-balance window sizes
      set 'timeoutlen', 0        # respond immediately to mappings
      set 'report', 9999         # don't show "X lines changed" reports
      set 'sidescroll', 0        # don't sidescroll in jumps
      set 'sidescrolloff', 0     # don't sidescroll automatically
      set 'updatetime', options[:debounce_interval]

      # show match window
      split_location = options[:match_window_at_top] ? 'topleft' : 'botright'
      if @@buffer # still have buffer from last time
        ::VIM::command "silent! #{split_location} #{@@buffer.number}sbuffer"
        raise "Can't re-open GoToFile buffer" unless $curbuf.number == @@buffer.number
        $curwin.height = 1
      else        # creating match window for first time and set it up
        ::VIM::command "silent! #{split_location} 1split GoToFile"
        set 'bufhidden', 'unload' # unload buf when no longer displayed
        set 'buftype', 'nofile'   # buffer is not related to any file
        set 'modifiable', false   # prevent manual edits
        set 'swapfile', false     # don't create a swapfile
        set 'wrap', false         # don't soft-wrap
        set 'number', false       # don't show line numbers
        set 'list', false         # don't use List mode (visible tabs etc)
        set 'foldcolumn', 0       # don't show a fold column at side
        set 'foldlevel', 99       # don't fold anything
        set 'cursorline', false   # don't highlight line cursor is on
        set 'spell', false        # spell-checking off
        set 'buflisted', false    # don't show up in the buffer list
        set 'textwidth', 0        # don't hard-wrap (break long lines)

        # don't show the color column
        set 'colorcolumn', 0 if VIM::exists?('+colorcolumn')

        # don't show relative line numbers
        set 'relativenumber', false if VIM::exists?('+relativenumber')

        # sanity check: make sure the buffer really was created
        raise "Can't find GoToFile buffer" unless $curbuf.name.match /GoToFile\z/
        @@buffer = $curbuf
      end

      # syntax coloring
      if VIM::has_syntax?
        ::VIM::command "syntax match CommandTSelection \"^#{SELECTION_MARKER}.\\+$\""
        ::VIM::command 'syntax match CommandTNoEntries "^-- NO MATCHES --$"'
        ::VIM::command 'syntax match CommandTNoEntries "^-- NO SUCH FILE OR DIRECTORY --$"'
        set 'synmaxcol', 9999

        if VIM::has_conceal?
          set 'conceallevel', 2
          set 'concealcursor', 'nvic'
          ::VIM::command 'syntax region CommandTCharMatched ' \
                         "matchgroup=CommandTCharMatched start=+#{MH_START}+ " \
                         "matchgroup=CommandTCharMatchedEnd end=+#{MH_END}+ concealends"
          ::VIM::command 'highlight def CommandTCharMatched ' \
                         'term=bold,underline cterm=bold,underline ' \
                         'gui=bold,underline'
        end

        ::VIM::command "highlight link CommandTSelection #{@highlight_color}"
        ::VIM::command 'highlight link CommandTNoEntries Error'

        # hide cursor
        @cursor_highlight = get_cursor_highlight
        hide_cursor
      end

      # perform cleanup using an autocmd to ensure we don't get caught out
      # by some unexpected means of dismissing or leaving the Command-T window
      # (eg. <C-W q>, <C-W k> etc)
      ::VIM::command 'autocmd! * <buffer>'
      ::VIM::command 'autocmd BufLeave <buffer> silent! ruby $command_t.leave'
      ::VIM::command 'autocmd BufUnload <buffer> silent! ruby $command_t.unload'

      @has_focus  = false
      @selection  = nil
      @abbrev     = ''
      @window     = $curwin
    end

    def close
      # Unlisted buffers like those provided by Netrw, NERDTree and Vim's help
      # don't actually appear in the buffer list; if they are the only such
      # buffers present when Command-T is invoked (for example, when invoked
      # immediately after starting Vim with a directory argument, like `vim .`)
      # then performing the normal clean-up will yield an "E90: Cannot unload
      # last buffer" error. We can work around that by doing a :quit first.
      if ::VIM::Buffer.count == 0
        ::VIM::command 'silent quit'
      end

      # Workaround for upstream bug in Vim 7.3 on some platforms
      #
      # On some platforms, $curbuf.number always returns 0. One workaround is
      # to build Vim with --disable-largefile, but as this is producing lots of
      # support requests, implement the following fallback to the buffer name
      # instead, at least until upstream gets fixed.
      #
      # For more details, see: https://wincent.com/issues/1617
      if $curbuf.number == 0
        # use bwipeout as bunload fails if passed the name of a hidden buffer
        ::VIM::command 'silent! bwipeout! GoToFile'
        @@buffer = nil
      else
        ::VIM::command "silent! bunload! #{@@buffer.number}"
      end
    end

    def leave
      close
      unload
    end

    def unload
      restore_window_dimensions
      @settings.restore
      @prompt.dispose
      show_cursor
    end

    def add! char
      @abbrev += char
    end

    def backspace!
      @abbrev.chop!
    end

    def select_next
      if @selection < @matches.length - 1
        @selection += 1
        print_match(@selection - 1) # redraw old selection (removes marker)
        print_match(@selection)     # redraw new selection (adds marker)
        move_cursor_to_selected_line
      else
        # (possibly) loop or scroll
      end
    end

    def select_prev
      if @selection > 0
        @selection -= 1
        print_match(@selection + 1) # redraw old selection (removes marker)
        print_match(@selection)     # redraw new selection (adds marker)
        move_cursor_to_selected_line
      else
        # (possibly) loop or scroll
      end
    end

    def matches= matches
      matches = matches.reverse if @reverse_list
      if matches != @matches
        @matches = matches
        @selection = @reverse_list ? @matches.length - 1 : 0
        print_matches
        move_cursor_to_selected_line
      end
    end

    def focus
      unless @has_focus
        @has_focus = true
        if VIM::has_syntax?
          ::VIM::command 'highlight link CommandTSelection Search'
        end
      end
    end

    def unfocus
      if @has_focus
        @has_focus = false
        if VIM::has_syntax?
          ::VIM::command "highlight link CommandTSelection #{@highlight_color}"
        end
      end
    end

    def find char
      # is this a new search or the continuation of a previous one?
      now = Time.now
      if @last_key_time.nil? or @last_key_time < (now - 0.5)
        @find_string = char
      else
        @find_string += char
      end
      @last_key_time = now

      # see if there's anything up ahead that matches
      @matches.each_with_index do |match, idx|
        if match[0, @find_string.length].casecmp(@find_string) == 0
          old_selection = @selection
          @selection = idx
          print_match(old_selection)  # redraw old selection (removes marker)
          print_match(@selection)     # redraw new selection (adds marker)
          break
        end
      end
    end

    # Returns the currently selected item as a String.
    def selection
      @matches[@selection]
    end

    def print_no_such_file_or_directory
      print_error 'NO SUCH FILE OR DIRECTORY'
    end

  private

    def set(setting, value)
      @settings ||= Settings.new
      @settings.set(setting, value)
    end

    def move_cursor_to_selected_line
      # on some non-GUI terminals, the cursor doesn't hide properly
      # so we move the cursor to prevent it from blinking away in the
      # upper-left corner in a distracting fashion
      @window.cursor = [@selection + 1, 0]
    end

    def print_error msg
      return unless VIM::Window.select(@window)
      unlock
      clear
      @window.height = @min_height > 0 ? @min_height : 1
      @@buffer[1] = "-- #{msg} --"
      lock
    end

    def restore_window_dimensions
      # sort from tallest to shortest, tie-breaking on window width
      @windows.sort! do |a, b|
        order = b.height <=> a.height
        if order.zero?
          b.width <=> a.width
        else
          order
        end
      end

      # starting with the tallest ensures that there are no constraints
      # preventing windows on the side of vertical splits from regaining
      # their original full size
      @windows.each do |w|
        # beware: window may be nil
        if window = ::VIM::Window[w.index]
          window.height = w.height
          window.width  = w.width
        end
      end
    end

    def match_text_for_idx idx
      match = truncated_match @matches[idx].to_s
      if idx == @selection
        prefix = SELECTION_MARKER
        suffix = padding_for_selected_match match
      else
        if VIM::has_syntax? && VIM::has_conceal?
          match = match_with_syntax_highlight match
        end
        prefix = UNSELECTED_MARKER
        suffix = ''
      end
      prefix + match + suffix
    end

    # Highlight matching characters within the matched string.
    #
    # Note that this is only approximate; it will highlight the first matching
    # instances within the string, which may not actually be the instances that
    # were used by the matching/scoring algorithm to determine the best score
    # for the match.
    #
    def match_with_syntax_highlight match
      highlight_chars = @prompt.abbrev.downcase.chars.to_a
      match.chars.inject([]) do |output, char|
        if char.downcase == highlight_chars.first
          highlight_chars.shift
          output.concat [MH_START, char, MH_END]
        else
          output << char
        end
      end.join
    end

    # Print just the specified match.
    def print_match idx
      return unless VIM::Window.select(@window)
      unlock
      @@buffer[idx + 1] = match_text_for_idx idx
      lock
    end

    # Print all matches.
    def print_matches
      match_count = @matches.length
      if match_count == 0
        print_error 'NO MATCHES'
      else
        return unless VIM::Window.select(@window)
        unlock
        clear
        actual_lines = 1
        @window_width = @window.width # update cached value
        max_lines = VIM::Screen.lines - 5
        max_lines = 1 if max_lines < 0
        actual_lines = match_count < @min_height ? @min_height : match_count
        actual_lines = max_lines if actual_lines > max_lines
        @window.height = actual_lines
        (1..actual_lines).each do |line|
          idx = line - 1
          if @@buffer.count >= line
            @@buffer[line] = match_text_for_idx idx
          else
            @@buffer.append line - 1, match_text_for_idx(idx)
          end
        end
        lock
      end
    end

    # Prepare padding for match text (trailing spaces) so that selection
    # highlighting extends all the way to the right edge of the window.
    def padding_for_selected_match str
      len = str.length
      if len >= @window_width - MARKER_LENGTH
        ''
      else
        ' ' * (@window_width - MARKER_LENGTH - len)
      end
    end

    # Convert "really/long/path" into "really...path" based on available
    # window width.
    def truncated_match str
      len = str.length
      available_width = @window_width - MARKER_LENGTH
      return str if len <= available_width
      left = (available_width / 2) - 1
      right = (available_width / 2) - 2 + (available_width % 2)
      str[0, left] + '...' + str[-right, right]
    end

    def clear
      # range = % (whole buffer)
      # action = d (delete)
      # register = _ (black hole register, don't record deleted text)
      ::VIM::command 'silent %d _'
    end

    def get_cursor_highlight
      # there are 3 possible formats to check for, each needing to be
      # transformed in a certain way in order to reapply the highlight:
      #   Cursor xxx guifg=bg guibg=fg      -> :hi! Cursor guifg=bg guibg=fg
      #   Cursor xxx links to SomethingElse -> :hi! link Cursor SomethingElse
      #   Cursor xxx cleared                -> :hi! clear Cursor
      highlight = VIM::capture 'silent! 0verbose highlight Cursor'

      if highlight =~ /^Cursor\s+xxx\s+links to (\w+)/
        "link Cursor #{$~[1]}"
      elsif highlight =~ /^Cursor\s+xxx\s+cleared/
        'clear Cursor'
      elsif highlight =~ /Cursor\s+xxx\s+(.+)/
        "Cursor #{$~[1]}"
      else # likely cause E411 Cursor highlight group not found
        nil
      end
    end

    def hide_cursor
      if @cursor_highlight
        ::VIM::command 'highlight Cursor NONE'
      end
    end

    def show_cursor
      if @cursor_highlight
        ::VIM::command "highlight #{@cursor_highlight}"
      end
    end

    def lock
      set 'modifiable', false
    end

    def unlock
      set 'modifiable', true
    end
  end
end
ruby/command-t/mru.rb	[[[1
58
# Copyright 2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  # Maintains a stack of seen buffers in MRU (most recently used) order.
  module MRU
    class << self
      # The stack of used buffers in MRU order.
      def stack
        @stack ||= []
      end

      # Mark the current buffer as having been used, effectively moving it to
      # the top of the stack.
      def touch
        return unless ::VIM::evaluate('buflisted(%d)' % $curbuf.number) == 1
        return unless $curbuf.name

        stack.delete $curbuf
        stack.push $curbuf
      end

      # Mark a buffer as deleted, removing it from the stack.
      def delete
        # Note that $curbuf does not point to the buffer that is being deleted;
        # we need to use Vim's <abuf> for the correct buffer number.
        stack.delete_if do |b|
          b.number == ::VIM::evaluate('expand("<abuf>")').to_i
        end
      end

      # Returns `true` if `buffer` has been used (ie. is present in the stack).
      def used?(buffer)
        stack.include?(buffer)
      end
    end
  end # module MRU
end # module CommandT
ruby/command-t/prompt.rb	[[[1
165
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  # Abuse the status line as a prompt.
  class Prompt
    attr_accessor :abbrev

    def initialize
      @abbrev     = ''  # abbreviation entered so far
      @col        = 0   # cursor position
      @has_focus  = false
    end

    # Erase whatever is displayed in the prompt line,
    # effectively disposing of the prompt
    def dispose
      ::VIM::command 'echo'
      ::VIM::command 'redraw'
    end

    # Clear any entered text.
    def clear!
      @abbrev = ''
      @col    = 0
      redraw
    end

    # Insert a character at (before) the current cursor position.
    def add! char
      left, cursor, right = abbrev_segments
      @abbrev = left + char + cursor + right
      @col += 1
      redraw
    end

    # Delete a character to the left of the current cursor position.
    def backspace!
      if @col > 0
        left, cursor, right = abbrev_segments
        @abbrev = left.chop! + cursor + right
        @col -= 1
        redraw
      end
    end

    # Delete a character at the current cursor position.
    def delete!
      if @col < @abbrev.length
        left, cursor, right = abbrev_segments
        @abbrev = left + right
        redraw
      end
    end

    def cursor_left
      if @col > 0
        @col -= 1
        redraw
      end
    end

    def cursor_right
      if @col < @abbrev.length
        @col += 1
        redraw
      end
    end

    def cursor_end
      if @col < @abbrev.length
        @col = @abbrev.length
        redraw
      end
    end

    def cursor_start
      if @col != 0
        @col = 0
        redraw
      end
    end

    def redraw
      if @has_focus
        prompt_highlight = 'Comment'
        normal_highlight = 'None'
        cursor_highlight = 'Underlined'
      else
        prompt_highlight = 'NonText'
        normal_highlight = 'NonText'
        cursor_highlight = 'NonText'
      end
      left, cursor, right = abbrev_segments
      components = [prompt_highlight, '>>', 'None', ' ']
      components += [normal_highlight, left] unless left.empty?
      components += [cursor_highlight, cursor] unless cursor.empty?
      components += [normal_highlight, right] unless right.empty?
      components += [cursor_highlight, ' '] if cursor.empty?
      set_status *components
    end

    def focus
      unless @has_focus
        @has_focus = true
        redraw
      end
    end

    def unfocus
      if @has_focus
        @has_focus = false
        redraw
      end
    end

  private

    # Returns the @abbrev string divided up into three sections, any of
    # which may actually be zero width, depending on the location of the
    # cursor:
    #   - left segment (to left of cursor)
    #   - cursor segment (character at cursor)
    #   - right segment (to right of cursor)
    def abbrev_segments
      left    = @abbrev[0, @col]
      cursor  = @abbrev[@col, 1]
      right   = @abbrev[(@col + 1)..-1] || ''
      [left, cursor, right]
    end

    def set_status *args
      # see ':help :echo' for why forcing a redraw here helps
      # prevent the status line from getting inadvertantly cleared
      # after our echo commands
      ::VIM::command 'redraw'
      while (highlight = args.shift) and  (text = args.shift) do
        text = VIM::escape_for_single_quotes text
        ::VIM::command "echohl #{highlight}"
        ::VIM::command "echon '#{text}'"
      end
      ::VIM::command 'echohl None'
    end
  end # class Prompt
end # module CommandT
ruby/command-t/scanner/buffer_scanner.rb	[[[1
42
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'
require 'command-t/vim/path_utilities'
require 'command-t/scanner'

module CommandT
  # Returns a list of all open buffers.
  class BufferScanner < Scanner
    include VIM::PathUtilities

    def paths
      (0..(::VIM::Buffer.count - 1)).map do |n|
        buffer = ::VIM::Buffer[n]
        if buffer.name # beware, may be nil
          relative_path_under_working_directory buffer.name
        end
      end.compact
    end
  end # class BufferScanner
end # module CommandT
ruby/command-t/scanner/file_scanner/find_file_scanner.rb	[[[1
77
# Copyright 2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'open3'
require 'command-t/vim'
require 'command-t/vim/path_utilities'
require 'command-t/scanner/file_scanner'

module CommandT
  class FileScanner
    # A FileScanner which shells out to the `find` executable in order to scan.
    class FindFileScanner < FileScanner
      include VIM::PathUtilities

      def paths
        super || begin
          set_wild_ignore(@wild_ignore)

          # temporarily set field separator to NUL byte; this setting is
          # respected by both `readlines` and `chomp!` below, and makes it easier
          # to parse the output of `find -print0`
          separator = $/
          $/ = "\x00"

          unless @scan_dot_directories
            dot_directory_filter = [
              '-not', '-path', "#{@path}/.*/*",           # top-level dot dir
              '-and', '-not', '-path', "#{@path}/*/.*/*"  # lower-level dot dir
            ]
          end

          Open3.popen3(*([
            'find', '-L',                 # follow symlinks
            @path,                        # anchor search here
            '-maxdepth', @max_depth.to_s, # limit depth of DFS
            '-type', 'f',                 # only show regular files (not dirs etc)
            dot_directory_filter,         # possibly skip out dot directories
            '-print0'                     # NUL-terminate results
          ].flatten.compact)) do |stdin, stdout, stderr|
            counter = 1
            paths = []
            stdout.readlines.each do |line|
              next if path_excluded?(line.chomp!)
              paths << line[@prefix_len + 1..-1]
              break if (counter += 1) > @max_files
            end
            @paths[@path] = paths
          end
        ensure
          $/ = separator
          set_wild_ignore(@base_wild_ignore)
        end
        @paths[@path]
      end
    end # class FindFileScanner
  end # class FileScanner
end # module CommandT
ruby/command-t/scanner/file_scanner/ruby_file_scanner.rb	[[[1
78
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'
require 'command-t/scanner/file_scanner'

module CommandT
  class FileScanner
    # Pure Ruby implementation of a file scanner.
    class RubyFileScanner < FileScanner
      def paths
        super || begin
          @paths[@path] = []
          @depth        = 0
          @files        = 0
          set_wild_ignore(@wild_ignore)
          add_paths_for_directory @path, @paths[@path]
        rescue FileLimitExceeded
        ensure
          set_wild_ignore(@base_wild_ignore)
        end
        @paths[@path]
      end

    private

      def looped_symlink? path
        if File.symlink?(path)
          target = File.expand_path(File.readlink(path), File.dirname(path))
          target.include?(@path) || @path.include?(target)
        end
      end

      def add_paths_for_directory dir, accumulator
        Dir.foreach(dir) do |entry|
          next if ['.', '..'].include?(entry)
          path = File.join(dir, entry)
          unless path_excluded?(path)
            if File.file?(path)
              @files += 1
              raise FileLimitExceeded if @files > @max_files
              accumulator << path[@prefix_len + 1..-1]
            elsif File.directory?(path)
              next if @depth >= @max_depth
              next if (entry.match(/\A\./) && !@scan_dot_directories)
              next if looped_symlink?(path)
              @depth += 1
              add_paths_for_directory path, accumulator
              @depth -= 1
            end
          end
        end
      rescue Errno::EACCES
        # skip over directories for which we don't have access
      end
    end # class RubyFileScanner
  end # class FileScanner
end # module CommandT
ruby/command-t/scanner/file_scanner/watchman_file_scanner.rb	[[[1
82
# Copyright 2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'pathname'
require 'socket'
require 'command-t/vim'
require 'command-t/vim/path_utilities'
require 'command-t/scanner/file_scanner'
require 'command-t/scanner/file_scanner/find_file_scanner'

module CommandT
  class FileScanner
    # A FileScanner which delegates the heavy lifting to Watchman
    # (https://github.com/facebook/watchman); useful for very large hierarchies.
    #
    # Inherits from FindFileScanner so that it can fall back to it in the event
    # that Watchman isn't available or able to fulfil the request.
    class WatchmanFileScanner < FindFileScanner
      # Exception raised when Watchman is unavailable or unable to process the
      # requested path.
      class WatchmanUnavailable < RuntimeError; end

      def paths
        @paths[@path] ||= begin
          ensure_cache_under_limit
          sockname = Watchman::Utils.load(
            %x{watchman --output-encoding=bser get-sockname}
          )['sockname']
          raise WatchmanUnavailable unless $?.exitstatus.zero?

          UNIXSocket.open(sockname) do |socket|
            root = Pathname.new(@path).realpath.to_s
            roots = Watchman::Utils.query(['watch-list'], socket)['roots']
            if !roots.include?(root)
              # this path isn't being watched yet; try to set up watch
              result = Watchman::Utils.query(['watch', root], socket)

              # root_restrict_files setting may prevent Watchman from working
              raise WatchmanUnavailable if result.has_key?('error')
            end

            query = ['query', root, {
              'expression' => ['type', 'f'],
              'fields'     => ['name'],
            }]
            paths = Watchman::Utils.query(query, socket)

            # could return error if watch is removed
            raise WatchmanUnavailable if paths.has_key?('error')

            @paths[@path] = paths['files']
          end
        end

        @paths[@path]
      rescue Errno::ENOENT, WatchmanUnavailable
        # watchman executable not present, or unable to fulfil request
        super
      end
    end # class WatchmanFileScanner
  end # class FileScanner
end # module CommandT
ruby/command-t/scanner/file_scanner.rb	[[[1
83
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'
require 'command-t/scanner'

module CommandT
  # Reads the current directory recursively for the paths to all regular files.
  #
  # This is an abstract superclass; the real work is done by subclasses which
  # obtain file listings via different strategies (for examples, see the
  # RubyFileScanner and FindFileScanner subclasses).
  class FileScanner < Scanner
    class FileLimitExceeded < ::RuntimeError; end
    attr_accessor :path

    def initialize(path = Dir.pwd, options = {})
      @paths                = {}
      @paths_keys           = []
      @path                 = path
      @max_depth            = options[:max_depth] || 15
      @max_files            = options[:max_files] || 30_000
      @max_caches           = options[:max_caches] || 1
      @scan_dot_directories = options[:scan_dot_directories] || false
      @wild_ignore          = options[:wild_ignore]
      @base_wild_ignore     = VIM::wild_ignore
    end

    def paths
      @paths[@path] || begin
        ensure_cache_under_limit
        @prefix_len = @path.chomp('/').length
        nil
      end
    end

    def flush
      @paths = {}
    end

  private

    def ensure_cache_under_limit
      # Ruby 1.8 doesn't have an ordered hash, so use a separate stack to
      # track and expire the oldest entry in the cache
      if @max_caches > 0 && @paths_keys.length >= @max_caches
        @paths.delete @paths_keys.shift
      end
      @paths_keys << @path
    end

    def path_excluded?(path)
      # first strip common prefix (@path) from path to match VIM's behavior
      path = path[(@prefix_len + 1)..-1]
      path = VIM::escape_for_single_quotes path
      ::VIM::evaluate("empty(expand(fnameescape('#{path}')))").to_i == 1
    end

    def set_wild_ignore(ignore)
      ::VIM::command("set wildignore=#{ignore}") if @wild_ignore
    end
  end # class FileScanner
end # module CommandT
ruby/command-t/scanner/jump_scanner.rb	[[[1
54
# Copyright 2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'
require 'command-t/vim/path_utilities'
require 'command-t/scanner'

module CommandT
  # Returns a list of files in the jumplist.
  class JumpScanner < Scanner
    include VIM::PathUtilities

    def paths
      jumps_with_filename = jumps.lines.select do |line|
        line_contains_filename?(line)
      end
      filenames = jumps_with_filename[1..-2].map do |line|
        relative_path_under_working_directory line.split[3]
      end

      filenames.sort.uniq
    end

  private

    def line_contains_filename? line
      line.split.count > 3
    end

    def jumps
      VIM::capture 'silent jumps'
    end
  end # class JumpScanner
end # module CommandT
ruby/command-t/scanner/mru_buffer_scanner.rb	[[[1
48
# Copyright 2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim/path_utilities'
require 'command-t/scanner/buffer_scanner'

module CommandT
  # Returns a list of all open buffers, sorted in MRU order.
  class MRUBufferScanner < BufferScanner
    include VIM::PathUtilities

    def paths
      # Collect all buffers that have not been used yet.
      unused_buffers = (0..(::VIM::Buffer.count - 1)).map do |n|
        buffer = ::VIM::Buffer[n]
        buffer if buffer.name && !MRU.used?(buffer)
      end

      # Combine all most recently used buffers and all unused buffers, and
      # return all listed buffer paths.
      (unused_buffers + MRU.stack).map do |buffer|
        if buffer && buffer.name
          relative_path_under_working_directory buffer.name
        end
      end.compact.reverse
    end
  end # class MRUBufferScanner
end # module CommandT
ruby/command-t/scanner/tag_scanner.rb	[[[1
49
# Copyright 2011-2012 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'
require 'command-t/scanner'

module CommandT
  class TagScanner < Scanner
    attr_reader :include_filenames

    def initialize options = {}
      @include_filenames = options[:include_filenames] || false
    end

    def paths
      taglist.map do |tag|
        path = tag['name']
        path << ":#{tag['filename']}" if @include_filenames
        path
      end.uniq.sort
    end

  private

    def taglist
      ::VIM::evaluate 'taglist(".")'
    end
  end # class TagScanner
end # module CommandT
ruby/command-t/scanner.rb	[[[1
28
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'

module CommandT
  class Scanner; end
end # module CommandT
ruby/command-t/settings.rb	[[[1
128
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  # Convenience class for saving and restoring global settings.
  class Settings
    # Settings which apply globally and so must be manually saved and restored
    GLOBAL_SETTINGS = %w[
      equalalways
      hlsearch
      insertmode
      report
      showcmd
      sidescroll
      sidescrolloff
      timeout
      timeoutlen
      updatetime
    ]

    # Settings which can be made locally to the Command-T buffer or window
    LOCAL_SETTINGS = %w[
      bufhidden
      buflisted
      buftype
      colorcolumn
      concealcursor
      conceallevel
      cursorline
      foldcolumn
      foldlevel
      list
      modifiable
      number
      relativenumber
      spell
      swapfile
      synmaxcol
      textwidth
      wrap
    ]

    KNOWN_SETTINGS = GLOBAL_SETTINGS + LOCAL_SETTINGS

    def initialize
      @settings = []
    end

    def set(setting, value)
      raise "Unknown setting #{setting}" unless KNOWN_SETTINGS.include?(setting)

      case value
      when TrueClass, FalseClass
        @settings.push([setting, get_bool(setting)]) if global?(setting)
        set_bool setting, value
      when Numeric
        @settings.push([setting, get_number(setting)]) if global?(setting)
        set_number setting, value
      when String
        @settings.push([setting, get_string(setting)]) if global?(setting)
        set_string setting, value
      end
    end

    def restore
      @settings.each do |setting, value|
        case value
        when TrueClass, FalseClass
          set_bool setting, value
        when Numeric
          set_number setting, value
        when String
          set_string setting, value
        end
      end
    end

  private

    def global?(setting)
      GLOBAL_SETTINGS.include?(setting)
    end

    def get_bool(setting)
      ::VIM::evaluate("&#{setting}").to_i == 1
    end

    def get_number(setting)
      ::VIM::evaluate("&#{setting}").to_i
    end

    def get_string(name)
      ::VIM::evaluate("&#{name}").to_s
    end

    def set_bool(setting, value)
      command = global?(setting) ? 'set' : 'setlocal'
      setting = value ? setting : "no#{setting}"
      ::VIM::command "#{command} #{setting}"
    end

    def set_number(setting, value)
      command = global?(setting) ? 'set' : 'setlocal'
      ::VIM::command "#{command} #{setting}=#{value}"
    end
    alias set_string set_number
  end # class Settings
end # module CommandT
ruby/command-t/stub.rb	[[[1
50
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  class Stub
    @@load_error = ['command-t.vim could not load the C extension',
                    'Please see INSTALLATION and TROUBLE-SHOOTING in the help',
                    "Vim Ruby version: #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
                    'For more information type:    :help command-t']

    [
      :flush,
      :show_buffer_finder,
      :show_file_finder,
      :show_jump_finder,
      :show_mru_finder,
      :show_tag_finder
    ].each do |method|
      define_method(method) { warn *@@load_error }
    end

  private

    def warn *msg
      ::VIM::command 'echohl WarningMsg'
      msg.each { |m| ::VIM::command "echo '#{m}'" }
      ::VIM::command 'echohl none'
    end
  end # class Stub
end # module CommandT
ruby/command-t/util.rb	[[[1
114
# Copyright 2013-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'rbconfig'

module CommandT
  module Util
    class << self
      def processor_count
        @processor_count ||= begin
          count = processor_count!
          count = 1 if count < 1   # sanity check
          count = 32 if count > 32 # sanity check
          count
        end
      end

    private

      # This method derived from:
      #
      #   https://github.com/grosser/parallel/blob/d11e4a3c8c1a/lib/parallel.rb
      #
      # Number of processors seen by the OS and used for process scheduling.
      #
      # * AIX: /usr/sbin/pmcycles (AIX 5+), /usr/sbin/lsdev
      # * BSD: /sbin/sysctl
      # * Cygwin: /proc/cpuinfo
      # * Darwin: /usr/bin/hwprefs, /usr/sbin/sysctl
      # * HP-UX: /usr/sbin/ioscan
      # * IRIX: /usr/sbin/sysconf
      # * Linux: /proc/cpuinfo
      # * Minix 3+: /proc/cpuinfo
      # * Solaris: /usr/sbin/psrinfo
      # * Tru64 UNIX: /usr/sbin/psrinfo
      # * UnixWare: /usr/sbin/psrinfo
      #
      # Copyright (C) 2013 Michael Grosser <michael@grosser.it>
      #
      # Permission is hereby granted, free of charge, to any person obtaining
      # a copy of this software and associated documentation files (the
      # "Software"), to deal in the Software without restriction, including
      # without limitation the rights to use, copy, modify, merge, publish,
      # distribute, sublicense, and/or sell copies of the Software, and to
      # permit persons to whom the Software is furnished to do so, subject to
      # the following conditions:
      #
      # The above copyright notice and this permission notice shall be
      # included in all copies or substantial portions of the Software.
      #
      # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
      # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
      # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
      # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
      # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
      # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
      #
      def processor_count!
        os_name = RbConfig::CONFIG['target_os']
        if os_name =~ /mingw|mswin/
          require 'win32ole'
          result = WIN32OLE.connect('winmgmts://').ExecQuery(
              'select NumberOfLogicalProcessors from Win32_Processor')
          result.to_enum.collect(&:NumberOfLogicalProcessors).reduce(:+)
        elsif File.readable?('/proc/cpuinfo')
          IO.read('/proc/cpuinfo').scan(/^processor/).size
        elsif File.executable?('/usr/bin/hwprefs')
          IO.popen(%w[/usr/bin/hwprefs thread_count]).read.to_i
        elsif File.executable?('/usr/sbin/psrinfo')
          IO.popen('/usr/sbin/psrinfo').read.scan(/^.*on-*line/).size
        elsif File.executable?('/usr/sbin/ioscan')
          IO.popen(%w[/usr/sbin/ioscan -kC processor]) do |out|
            out.read.scan(/^.*processor/).size
          end
        elsif File.executable?('/usr/sbin/pmcycles')
          IO.popen(%w[/usr/sbin/pmcycles -m]).read.count("\n")
        elsif File.executable?('/usr/sbin/lsdev')
          IO.popen(%w[/usr/sbin/lsdev -Cc processor -S 1]).read.count("\n")
        elsif File.executable?('/usr/sbin/sysconf') and os_name =~ /irix/i
          IO.popen(%w[/usr/sbin/sysconf NPROC_ONLN]).read.to_i
        elsif File.executable?('/usr/sbin/sysctl')
          IO.popen(%w[/usr/sbin/sysctl -n hw.ncpu]).read.to_i
        elsif File.executable?('/sbin/sysctl')
          IO.popen(%w[/sbin/sysctl -n hw.ncpu]).read.to_i
        else # unknown platform
          1
        end
      rescue
        1
      end
    end
  end # module Util
end # module CommandT
ruby/command-t/vim/path_utilities.rb	[[[1
40
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'

module CommandT
  module VIM
    module PathUtilities

    private

      def relative_path_under_working_directory path
        # any path under the working directory will be specified as a relative
        # path to improve the readability of the buffer list etc
        pwd = File.expand_path(VIM::pwd) + '/'
        path.index(pwd) == 0 ? path[pwd.length..-1] : path
      end
    end # module PathUtilities
  end # module VIM
end # module CommandT
ruby/command-t/vim/screen.rb	[[[1
32
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  module VIM
    module Screen
      def self.lines
        ::VIM::evaluate('&lines').to_i
      end
    end # module Screen
  end # module VIM
end # module CommandT
ruby/command-t/vim/window.rb	[[[1
38
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  module VIM
    class Window
      def self.select window
        return true if $curwin == window
        initial = $curwin
        while true do
          ::VIM::command 'wincmd w'           # cycle through windows
          return true if $curwin == window    # have selected desired window
          return false if $curwin == initial  # have already looped through all
        end
      end
    end # class Window
  end # module VIM
end # module CommandT
ruby/command-t/vim.rb	[[[1
63
# Copyright 2010-2013 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim/screen'
require 'command-t/vim/window'

module CommandT
  module VIM
    def self.has_syntax?
      ::VIM::evaluate('has("syntax")').to_i != 0
    end

    def self.exists? str
      ::VIM::evaluate(%{exists("#{str}")}).to_i != 0
    end

    def self.has_conceal?
      ::VIM::evaluate('has("conceal")').to_i != 0
    end

    def self.pwd
      ::VIM::evaluate 'getcwd()'
    end

    def self.wild_ignore
      exists?('&wildignore') && ::VIM::evaluate('&wildignore').to_s
    end

    # Execute cmd, capturing the output into a variable and returning it.
    def self.capture cmd
      ::VIM::command 'silent redir => g:command_t_captured_output'
      ::VIM::command cmd
      ::VIM::command 'silent redir END'
      ::VIM::evaluate 'g:command_t_captured_output'
    end

    # Escape a string for safe inclusion in a Vim single-quoted string
    # (single quotes escaped by doubling, everything else is literal)
    def self.escape_for_single_quotes str
      str.gsub "'", "''"
    end
  end # module VIM
end # module CommandT
ruby/command-t/ext.c	[[[1
60
// Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include "matcher.h"
#include "watchman.h"

VALUE mCommandT              = 0; // module CommandT
VALUE cCommandTMatcher       = 0; // class CommandT::Matcher
VALUE mCommandTWatchman      = 0; // module CommandT::Watchman
VALUE mCommandTWatchmanUtils = 0; // module CommandT::Watchman::Utils

VALUE CommandT_option_from_hash(const char *option, VALUE hash)
{
    VALUE key;
    if (NIL_P(hash))
        return Qnil;
    key = ID2SYM(rb_intern(option));
    if (rb_funcall(hash, rb_intern("has_key?"), 1, key) == Qtrue)
        return rb_hash_aref(hash, key);
    else
        return Qnil;
}

void Init_ext()
{
    // module CommandT
    mCommandT = rb_define_module("CommandT");

    // class CommandT::Matcher
    cCommandTMatcher = rb_define_class_under(mCommandT, "Matcher", rb_cObject);
    rb_define_method(cCommandTMatcher, "initialize", CommandTMatcher_initialize, -1);
    rb_define_method(cCommandTMatcher, "sorted_matches_for", CommandTMatcher_sorted_matches_for, -1);

    // module CommandT::Watchman::Utils
    mCommandTWatchman = rb_define_module_under(mCommandT, "Watchman");
    mCommandTWatchmanUtils = rb_define_module_under(mCommandTWatchman, "Utils");
    rb_define_singleton_method(mCommandTWatchmanUtils, "load", CommandTWatchmanUtils_load, 1);
    rb_define_singleton_method(mCommandTWatchmanUtils, "dump", CommandTWatchmanUtils_dump, 1);
    rb_define_singleton_method(mCommandTWatchmanUtils, "query", CommandTWatchmanUtils_query, 2);
}
ruby/command-t/match.c	[[[1
201
// Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <float.h> /* for DBL_MAX */
#include "match.h"
#include "ext.h"
#include "ruby_compat.h"

// use a struct to make passing params during recursion easier
typedef struct {
    char    *haystack_p;            // pointer to the path string to be searched
    long    haystack_len;           // length of same
    char    *needle_p;              // pointer to search string (needle)
    long    needle_len;             // length of same
    double  max_score_per_char;
    int     dot_file;               // boolean: true if str is a dot-file
    int     always_show_dot_files;  // boolean
    int     never_show_dot_files;   // boolean
    double  *memo;                  // memoization
} matchinfo_t;

double recursive_match(matchinfo_t *m,    // sharable meta-data
                       long haystack_idx, // where in the path string to start
                       long needle_idx,   // where in the needle string to start
                       long last_idx,     // location of last matched character
                       double score)      // cumulative score so far
{
    double seen_score = 0;  // remember best score seen via recursion
    int dot_file_match = 0; // true if needle matches a dot-file
    int dot_search = 0;     // true if searching for a dot
    long i, j, distance;
    int found;
    double score_for_char;
    long memo_idx = haystack_idx;

    // do we have a memoized result we can return?
    double memoized = m->memo[needle_idx * m->needle_len + memo_idx];
    if (memoized != DBL_MAX)
        return memoized;

    // bail early if not enough room (left) in haystack for (rest of) needle
    if (m->haystack_len - haystack_idx < m->needle_len - needle_idx) {
        score = 0.0;
        goto memoize;
    }

    for (i = needle_idx; i < m->needle_len; i++) {
        char c = m->needle_p[i];
        if (c == '.')
            dot_search = 1;
        found = 0;

        // similar to above, we'll stop iterating when we know we're too close
        // to the end of the string to possibly match
        for (j = haystack_idx;
             j <= m->haystack_len - (m->needle_len - i);
             j++, haystack_idx++) {
            char d = m->haystack_p[j];
            if (d == '.') {
                if (j == 0 || m->haystack_p[j - 1] == '/') {
                    m->dot_file = 1;        // this is a dot-file
                    if (dot_search)         // and we are searching for a dot
                        dot_file_match = 1; // so this must be a match
                }
            } else if (d >= 'A' && d <= 'Z') {
                d += 'a' - 'A'; // add 32 to downcase
            }

            if (c == d) {
                found = 1;
                dot_search = 0;

                // calculate score
                score_for_char = m->max_score_per_char;
                distance = j - last_idx;

                if (distance > 1) {
                    double factor = 1.0;
                    char last = m->haystack_p[j - 1];
                    char curr = m->haystack_p[j]; // case matters, so get again
                    if (last == '/')
                        factor = 0.9;
                    else if (last == '-' ||
                            last == '_' ||
                            last == ' ' ||
                            (last >= '0' && last <= '9'))
                        factor = 0.8;
                    else if (last >= 'a' && last <= 'z' &&
                            curr >= 'A' && curr <= 'Z')
                        factor = 0.8;
                    else if (last == '.')
                        factor = 0.7;
                    else
                        // if no "special" chars behind char, factor diminishes
                        // as distance from last matched char increases
                        factor = (1.0 / distance) * 0.75;
                    score_for_char *= factor;
                }

                if (++j < m->haystack_len) {
                    // bump cursor one char to the right and
                    // use recursion to try and find a better match
                    double sub_score = recursive_match(m, j, i, last_idx, score);
                    if (sub_score > seen_score)
                        seen_score = sub_score;
                }

                score += score_for_char;
                last_idx = haystack_idx++;
                break;
            }
        }
        if (!found) {
            score = 0.0;
            goto memoize;
        }
    }

    if (m->dot_file &&
        (m->never_show_dot_files ||
         (!dot_file_match && !m->always_show_dot_files))) {
        score = 0.0;
        goto memoize;
    }
    score = score > seen_score ? score : seen_score;

memoize:
    m->memo[needle_idx * m->needle_len + memo_idx] = score;
    return score;
}

void calculate_match(VALUE str,
                     VALUE needle,
                     VALUE always_show_dot_files,
                     VALUE never_show_dot_files,
                     match_t *out)
{
    long i, max;
    double score;
    matchinfo_t m;
    m.haystack_p            = RSTRING_PTR(str);
    m.haystack_len          = RSTRING_LEN(str);
    m.needle_p              = RSTRING_PTR(needle);
    m.needle_len            = RSTRING_LEN(needle);
    m.max_score_per_char    = (1.0 / m.haystack_len + 1.0 / m.needle_len) / 2;
    m.dot_file              = 0;
    m.always_show_dot_files = always_show_dot_files == Qtrue;
    m.never_show_dot_files  = never_show_dot_files == Qtrue;

    // calculate score
    score = 1.0;

    // special case for zero-length search string
    if (m.needle_len == 0) {

        // filter out dot files
        if (!m.always_show_dot_files) {
            for (i = 0; i < m.haystack_len; i++) {
                char c = m.haystack_p[i];

                if (c == '.' && (i == 0 || m.haystack_p[i - 1] == '/')) {
                    score = 0.0;
                    break;
                }
            }
        }
    } else if (m.haystack_len > 0) { // normal case

        // prepare for memoization
        double memo[m.haystack_len * m.needle_len];
        for (i = 0, max = m.haystack_len * m.needle_len; i < max; i++)
            memo[i] = DBL_MAX;
        m.memo = memo;

        score = recursive_match(&m, 0, 0, 0, 0.0);
    }

    // final book-keeping
    out->path  = str;
    out->score = score;
}
ruby/command-t/matcher.c	[[[1
246
// Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <stdlib.h>  /* for qsort() */
#include <string.h>  /* for strncmp() */
#include "matcher.h"
#include "match.h"
#include "ext.h"
#include "ruby_compat.h"

// order matters; we want this to be evaluated only after ruby.h
#ifdef HAVE_PTHREAD_H
#include <pthread.h> /* for pthread_create, pthread_join etc */
#endif

// comparison function for use with qsort
int cmp_alpha(const void *a, const void *b)
{
    match_t a_match = *(match_t *)a;
    match_t b_match = *(match_t *)b;
    VALUE   a_str   = a_match.path;
    VALUE   b_str   = b_match.path;
    char    *a_p    = RSTRING_PTR(a_str);
    long    a_len   = RSTRING_LEN(a_str);
    char    *b_p    = RSTRING_PTR(b_str);
    long    b_len   = RSTRING_LEN(b_str);
    int     order   = 0;

    if (a_len > b_len) {
        order = strncmp(a_p, b_p, b_len);
        if (order == 0)
            order = 1; // shorter string (b) wins
    } else if (a_len < b_len) {
        order = strncmp(a_p, b_p, a_len);
        if (order == 0)
            order = -1; // shorter string (a) wins
    } else {
        order = strncmp(a_p, b_p, a_len);
    }

    return order;
}

// comparison function for use with qsort
int cmp_score(const void *a, const void *b)
{
    match_t a_match = *(match_t *)a;
    match_t b_match = *(match_t *)b;

    if (a_match.score > b_match.score)
        return -1; // a scores higher, a should appear sooner
    else if (a_match.score < b_match.score)
        return 1;  // b scores higher, a should appear later
    else
        return cmp_alpha(a, b);
}

VALUE CommandTMatcher_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE always_show_dot_files;
    VALUE never_show_dot_files;
    VALUE options;
    VALUE scanner;

    // process arguments: 1 mandatory, 1 optional
    if (rb_scan_args(argc, argv, "11", &scanner, &options) == 1)
        options = Qnil;
    if (NIL_P(scanner))
        rb_raise(rb_eArgError, "nil scanner");

    rb_iv_set(self, "@scanner", scanner);

    // check optional options hash for overrides
    always_show_dot_files = CommandT_option_from_hash("always_show_dot_files", options);
    never_show_dot_files = CommandT_option_from_hash("never_show_dot_files", options);

    rb_iv_set(self, "@always_show_dot_files", always_show_dot_files);
    rb_iv_set(self, "@never_show_dot_files", never_show_dot_files);

    return Qnil;
}

typedef struct {
    int thread_count;
    int thread_index;
    match_t *matches;
    long path_count;
    VALUE paths;
    VALUE abbrev;
    VALUE always_show_dot_files;
    VALUE never_show_dot_files;
} thread_args_t;

void *match_thread(void *thread_args)
{
    long i;
    thread_args_t *args = (thread_args_t *)thread_args;
    for (i = args->thread_index; i < args->path_count; i += args->thread_count) {
        VALUE path = RARRAY_PTR(args->paths)[i];
        calculate_match(path,
                        args->abbrev,
                        args->always_show_dot_files,
                        args->never_show_dot_files,
                        &args->matches[i]);
    }

    return NULL;
}

VALUE CommandTMatcher_sorted_matches_for(int argc, VALUE *argv, VALUE self)
{
    long i, limit, path_count, thread_count;
#ifdef HAVE_PTHREAD_H
    long err;
    pthread_t *threads;
#endif
    match_t *matches;
    thread_args_t *thread_args;
    VALUE abbrev;
    VALUE always_show_dot_files;
    VALUE limit_option;
    VALUE never_show_dot_files;
    VALUE options;
    VALUE paths;
    VALUE results;
    VALUE scanner;
    VALUE sort_option;
    VALUE threads_option;

    // process arguments: 1 mandatory, 1 optional
    if (rb_scan_args(argc, argv, "11", &abbrev, &options) == 1)
        options = Qnil;
    if (NIL_P(abbrev))
        rb_raise(rb_eArgError, "nil abbrev");

    abbrev = StringValue(abbrev);
    abbrev = rb_funcall(abbrev, rb_intern("downcase"), 0);

    // check optional options has for overrides
    limit_option = CommandT_option_from_hash("limit", options);
    threads_option = CommandT_option_from_hash("threads", options);
    sort_option = CommandT_option_from_hash("sort", options);

    // get unsorted matches
    scanner = rb_iv_get(self, "@scanner");
    paths = rb_funcall(scanner, rb_intern("paths"), 0);
    always_show_dot_files = rb_iv_get(self, "@always_show_dot_files");
    never_show_dot_files = rb_iv_get(self, "@never_show_dot_files");

    path_count = RARRAY_LEN(paths);
    matches = malloc(path_count * sizeof(match_t));
    if (!matches)
        rb_raise(rb_eNoMemError, "memory allocation failed");

    thread_count = NIL_P(threads_option) ? 1 : NUM2LONG(threads_option);

#ifdef HAVE_PTHREAD_H
#define THREAD_THRESHOLD 1000 /* avoid the overhead of threading when search space is small */
    if (path_count < THREAD_THRESHOLD)
        thread_count = 1;
    threads = malloc(sizeof(pthread_t) * thread_count);
    if (!threads)
        rb_raise(rb_eNoMemError, "memory allocation failed");
#endif

    thread_args = malloc(sizeof(thread_args_t) * thread_count);
    if (!thread_args)
        rb_raise(rb_eNoMemError, "memory allocation failed");
    for (i = 0; i < thread_count; i++) {
        thread_args[i].thread_count = thread_count;
        thread_args[i].thread_index = i;
        thread_args[i].matches = matches;
        thread_args[i].path_count = path_count;
        thread_args[i].paths = paths;
        thread_args[i].abbrev = abbrev;
        thread_args[i].always_show_dot_files = always_show_dot_files;
        thread_args[i].never_show_dot_files = never_show_dot_files;

#ifdef HAVE_PTHREAD_H
        if (i == thread_count - 1) {
#endif
            // for the last "worker", we'll just use the main thread
            (void)match_thread(&thread_args[i]);
#ifdef HAVE_PTHREAD_H
        } else {
            err = pthread_create(&threads[i], NULL, match_thread, (void *)&thread_args[i]);
            if (err != 0)
                rb_raise(rb_eSystemCallError, "pthread_create() failure (%d)", (int)err);
        }
#endif
    }

#ifdef HAVE_PTHREAD_H
    for (i = 0; i < thread_count - 1; i++) {
        err = pthread_join(threads[i], NULL);
        if (err != 0)
            rb_raise(rb_eSystemCallError, "pthread_join() failure (%d)", (int)err);
    }
    free(threads);
#endif

    if (NIL_P(sort_option) || sort_option == Qtrue) {
        if (RSTRING_LEN(abbrev) == 0 ||
            (RSTRING_LEN(abbrev) == 1 && RSTRING_PTR(abbrev)[0] == '.'))
            // alphabetic order if search string is only "" or "."
            qsort(matches, path_count, sizeof(match_t), cmp_alpha);
        else
            // for all other non-empty search strings, sort by score
            qsort(matches, path_count, sizeof(match_t), cmp_score);
    }

    results = rb_ary_new();

    limit = NIL_P(limit_option) ? 0 : NUM2LONG(limit_option);
    if (limit == 0)
        limit = path_count;
    for (i = 0; i < path_count && limit > 0; i++) {
        if (matches[i].score > 0.0) {
            rb_funcall(results, rb_intern("push"), 1, matches[i].path);
            limit--;
        }
    }

    free(matches);
    return results;
}
ruby/command-t/watchman.c	[[[1
694
// Copyright 2014 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include "watchman.h"

#ifdef WATCHMAN_BUILD

#if defined(HAVE_RUBY_ST_H)
#include <ruby/st.h>
#elif defined(HAVE_ST_H)
#include <st.h>
#else
#error no st.h header found
#endif

#include <fcntl.h>      /* for fcntl() */
#include <sys/errno.h>  /* for errno */
#include <sys/socket.h> /* for recv(), MSG_PEEK */

typedef struct {
    uint8_t *data;  // payload
    size_t cap;     // total capacity
    size_t len;     // current length
} watchman_t;

// Forward declarations:
VALUE watchman_load(char **ptr, char *end);
void watchman_dump(watchman_t *w, VALUE serializable);

/**
 * Inspect a ruby object (debugging aid)
 */
#define ruby_inspect(obj) rb_funcall(rb_mKernel, rb_intern("p"), 1, obj)

/**
 * Print `count` bytes of memory at `address` (debugging aid)
 */
#define dump(address, count) \
    do { \
        for (int i = 0; i < count; i++) { \
            printf("%02x ", ((unsigned char *)address)[i]); printf("\n"); \
        } \
    } while(0)

#define WATCHMAN_DEFAULT_STORAGE 4096

#define WATCHMAN_BINARY_MARKER   "\x00\x01"
#define WATCHMAN_ARRAY_MARKER    0x00
#define WATCHMAN_HASH_MARKER     0x01
#define WATCHMAN_STRING_MARKER   0x02
#define WATCHMAN_INT8_MARKER     0x03
#define WATCHMAN_INT16_MARKER    0x04
#define WATCHMAN_INT32_MARKER    0x05
#define WATCHMAN_INT64_MARKER    0x06
#define WATCHMAN_FLOAT_MARKER    0x07
#define WATCHMAN_TRUE            0x08
#define WATCHMAN_FALSE           0x09
#define WATCHMAN_NIL             0x0a
#define WATCHMAN_TEMPLATE_MARKER 0x0b
#define WATCHMAN_SKIP_MARKER     0x0c

#define WATCHMAN_HEADER \
        WATCHMAN_BINARY_MARKER \
        "\x06" \
        "\x00\x00\x00\x00\x00\x00\x00\x00"

static const char watchman_array_marker  = WATCHMAN_ARRAY_MARKER;
static const char watchman_hash_marker   = WATCHMAN_HASH_MARKER;
static const char watchman_string_marker = WATCHMAN_STRING_MARKER;
static const char watchman_true          = WATCHMAN_TRUE;
static const char watchman_false         = WATCHMAN_FALSE;
static const char watchman_nil           = WATCHMAN_NIL;

/**
 * Appends `len` bytes, starting at `data`, to the watchman_t struct `w`
 *
 * Will attempt to reallocate the underlying storage if it is not sufficient.
 */
void watchman_append(watchman_t *w, const char *data, size_t len) {
    if (w->len + len > w->cap) {
        w->cap += w->len + WATCHMAN_DEFAULT_STORAGE;
        REALLOC_N(w->data, uint8_t, w->cap);
    }
    memcpy(w->data + w->len, data, len);
    w->len += len;
}

/**
 * Allocate a new watchman_t struct
 *
 * The struct has a small amount of extra capacity preallocated, and a blank
 * header that can be filled in later to describe the PDU.
 */
watchman_t *watchman_init() {
    watchman_t *w = ALLOC(watchman_t);
    w->cap = WATCHMAN_DEFAULT_STORAGE;
    w->len = 0;
    w->data = ALLOC_N(uint8_t, WATCHMAN_DEFAULT_STORAGE);

    watchman_append(w, WATCHMAN_HEADER, sizeof(WATCHMAN_HEADER) - 1);
    return w;
}

/**
 * Free a watchman_t struct `w` that was previously allocated with
 * `watchman_init`
 */
void watchman_free(watchman_t *w) {
    xfree(w->data);
    xfree(w);
}

/**
 * Encodes and appends the integer `num` to `w`
 */
void watchman_dump_int(watchman_t *w, int64_t num) {
    char encoded[1 + sizeof(int64_t)];

    if (num == (int8_t)num) {
        encoded[0] = WATCHMAN_INT8_MARKER;
        encoded[1] = (int8_t)num;
        watchman_append(w, encoded, 1 + sizeof(int8_t));
    } else if (num == (int16_t)num) {
        encoded[0] = WATCHMAN_INT16_MARKER;
        *(int16_t *)(encoded + 1) = (int16_t)num;
        watchman_append(w, encoded, 1 + sizeof(int16_t));
    } else if (num == (int32_t)num) {
        encoded[0] = WATCHMAN_INT32_MARKER;
        *(int32_t *)(encoded + 1) = (int32_t)num;
        watchman_append(w, encoded, 1 + sizeof(int32_t));
    } else {
        encoded[0] = WATCHMAN_INT64_MARKER;
        *(int64_t *)(encoded + 1) = (int64_t)num;
        watchman_append(w, encoded, 1 + sizeof(int64_t));
    }
}

/**
 * Encodes and appends the string `string` to `w`
 */
void watchman_dump_string(watchman_t *w, VALUE string) {
    watchman_append(w, &watchman_string_marker, sizeof(watchman_string_marker));
    watchman_dump_int(w, RSTRING_LEN(string));
    watchman_append(w, RSTRING_PTR(string), RSTRING_LEN(string));
}

/**
 * Encodes and appends the double `num` to `w`
 */
void watchman_dump_double(watchman_t *w, double num) {
    char encoded[1 + sizeof(double)];
    encoded[0] = WATCHMAN_FLOAT_MARKER;
    *(double *)(encoded + 1) = num;
    watchman_append(w, encoded, sizeof(encoded));
}

/**
 * Encodes and appends the array `array` to `w`
 */
void watchman_dump_array(watchman_t *w, VALUE array) {
    long i;
    watchman_append(w, &watchman_array_marker, sizeof(watchman_array_marker));
    watchman_dump_int(w, RARRAY_LEN(array));
    for (i = 0; i < RARRAY_LEN(array); i++) {
        watchman_dump(w, rb_ary_entry(array, i));
    }
}

/**
 * Helper method that encodes and appends a key/value pair (`key`, `value`) from
 * a hash to the watchman_t struct passed in via `data`
 */
int watchman_dump_hash_iterator(VALUE key, VALUE value, VALUE data) {
    watchman_t *w = (watchman_t *)data;
    watchman_dump_string(w, StringValue(key));
    watchman_dump(w, value);
    return ST_CONTINUE;
}

/**
 * Encodes and appends the hash `hash` to `w`
 */
void watchman_dump_hash(watchman_t *w, VALUE hash) {
    watchman_append(w, &watchman_hash_marker, sizeof(watchman_hash_marker));
    watchman_dump_int(w, RHASH_SIZE(hash));
    rb_hash_foreach(hash, watchman_dump_hash_iterator, (VALUE)w);
}

/**
 * Encodes and appends the serialized Ruby object `serializable` to `w`
 *
 * Examples of serializable objects include arrays, hashes, strings, numbers
 * (integers, floats), booleans, and nil.
 */
void watchman_dump(watchman_t *w, VALUE serializable) {
    switch (TYPE(serializable)) {
        case T_ARRAY:
            return watchman_dump_array(w, serializable);
        case T_HASH:
            return watchman_dump_hash(w, serializable);
        case T_STRING:
            return watchman_dump_string(w, serializable);
        case T_FIXNUM: // up to 63 bits
            return watchman_dump_int(w, FIX2LONG(serializable));
        case T_BIGNUM:
            return watchman_dump_int(w, NUM2LL(serializable));
        case T_FLOAT:
            return watchman_dump_double(w, NUM2DBL(serializable));
        case T_TRUE:
            return watchman_append(w, &watchman_true, sizeof(watchman_true));
        case T_FALSE:
            return watchman_append(w, &watchman_false, sizeof(watchman_false));
        case T_NIL:
            return watchman_append(w, &watchman_nil, sizeof(watchman_nil));
        default:
            rb_raise(rb_eTypeError, "unsupported type");
    }
}

/**
 * Extract and return the int encoded at `ptr`
 *
 * Moves `ptr` past the extracted int.
 *
 * Will raise an ArgumentError if extracting the int would take us beyond the
 * end of the buffer indicated by `end`, or if there is no int encoded at `ptr`.
 *
 * @returns The extracted int
 */
int64_t watchman_load_int(char **ptr, char *end) {
    char *val_ptr = *ptr + sizeof(int8_t);
    int64_t val = 0;

    if (val_ptr >= end) {
        rb_raise(rb_eArgError, "insufficient int storage");
    }

    switch (*ptr[0]) {
        case WATCHMAN_INT8_MARKER:
            if (val_ptr + sizeof(int8_t) > end) {
                rb_raise(rb_eArgError, "overrun extracting int8_t");
            }
            val = *(int8_t *)val_ptr;
            *ptr = val_ptr + sizeof(int8_t);
            break;
        case WATCHMAN_INT16_MARKER:
            if (val_ptr + sizeof(int16_t) > end) {
                rb_raise(rb_eArgError, "overrun extracting int16_t");
            }
            val = *(int16_t *)val_ptr;
            *ptr = val_ptr + sizeof(int16_t);
            break;
        case WATCHMAN_INT32_MARKER:
            if (val_ptr + sizeof(int32_t) > end) {
                rb_raise(rb_eArgError, "overrun extracting int32_t");
            }
            val = *(int32_t *)val_ptr;
            *ptr = val_ptr + sizeof(int32_t);
            break;
        case WATCHMAN_INT64_MARKER:
            if (val_ptr + sizeof(int64_t) > end) {
                rb_raise(rb_eArgError, "overrun extracting int64_t");
            }
            val = *(int64_t *)val_ptr;
            *ptr = val_ptr + sizeof(int64_t);
            break;
        default:
            rb_raise(rb_eArgError, "bad integer marker 0x%02x", (unsigned int)*ptr[0]);
            break;
    }

    return val;
}

/**
 * Reads and returns a string encoded in the Watchman binary protocol format,
 * starting at `ptr` and finishing at or before `end`
 */
VALUE watchman_load_string(char **ptr, char *end) {
    int64_t len;
    VALUE string;
    if (*ptr >= end) {
        rb_raise(rb_eArgError, "unexpected end of input");
    }

    if (*ptr[0] != WATCHMAN_STRING_MARKER) {
        rb_raise(rb_eArgError, "not a number");
    }

    *ptr += sizeof(int8_t);
    if (*ptr >= end) {
        rb_raise(rb_eArgError, "invalid string header");
    }

    len = watchman_load_int(ptr, end);
    if (len == 0) { // special case for zero-length strings
        return rb_str_new2("");
    } else if (*ptr + len > end) {
        rb_raise(rb_eArgError, "insufficient string storage");
    }

    string = rb_str_new(*ptr, len);
    *ptr += len;
    return string;
}

/**
 * Reads and returns a double encoded in the Watchman binary protocol format,
 * starting at `ptr` and finishing at or before `end`
 */
double watchman_load_double(char **ptr, char *end) {
    double val;
    *ptr += sizeof(int8_t); // caller has already verified the marker
    if (*ptr + sizeof(double) > end) {
        rb_raise(rb_eArgError, "insufficient double storage");
    }
    val = *(double *)*ptr;
    *ptr += sizeof(double);
    return val;
}

/**
 * Helper method which returns length of the array encoded in the Watchman
 * binary protocol format, starting at `ptr` and finishing at or before `end`
 */
int64_t watchman_load_array_header(char **ptr, char *end) {
    if (*ptr >= end) {
        rb_raise(rb_eArgError, "unexpected end of input");
    }

    // verify and consume marker
    if (*ptr[0] != WATCHMAN_ARRAY_MARKER) {
        rb_raise(rb_eArgError, "not an array");
    }
    *ptr += sizeof(int8_t);

    // expect a count
    if (*ptr + sizeof(int8_t) * 2 > end) {
        rb_raise(rb_eArgError, "incomplete array header");
    }
    return watchman_load_int(ptr, end);
}

/**
 * Reads and returns an array encoded in the Watchman binary protocol format,
 * starting at `ptr` and finishing at or before `end`
 */
VALUE watchman_load_array(char **ptr, char *end) {
    int64_t count, i;
    VALUE array;

    count = watchman_load_array_header(ptr, end);
    array = rb_ary_new2(count);

    for (i = 0; i < count; i++) {
        rb_ary_push(array, watchman_load(ptr, end));
    }

    return array;
}

/**
 * Reads and returns a hash encoded in the Watchman binary protocol format,
 * starting at `ptr` and finishing at or before `end`
 */
VALUE watchman_load_hash(char **ptr, char *end) {
    int64_t count, i;
    VALUE hash, key, value;

    *ptr += sizeof(int8_t); // caller has already verified the marker

    // expect a count
    if (*ptr + sizeof(int8_t) * 2 > end) {
        rb_raise(rb_eArgError, "incomplete hash header");
    }
    count = watchman_load_int(ptr, end);

    hash = rb_hash_new();

    for (i = 0; i < count; i++) {
        key = watchman_load_string(ptr, end);
        value = watchman_load(ptr, end);
        rb_hash_aset(hash, key, value);
    }

    return hash;
}

/**
 * Reads and returns a templated array encoded in the Watchman binary protocol
 * format, starting at `ptr` and finishing at or before `end`
 *
 * Templated arrays are arrays of hashes which have repetitive key information
 * pulled out into a separate "headers" prefix.
 *
 * @see https://github.com/facebook/watchman/blob/master/BSER.markdown
 */
VALUE watchman_load_template(char **ptr, char *end) {
    int64_t header_items_count, i, row_count;
    VALUE array, hash, header, key, value;

    *ptr += sizeof(int8_t); // caller has already verified the marker

    // process template header array
    header_items_count = watchman_load_array_header(ptr, end);
    header = rb_ary_new2(header_items_count);
    for (i = 0; i < header_items_count; i++) {
        rb_ary_push(header, watchman_load_string(ptr, end));
    }

    // process row items
    row_count = watchman_load_int(ptr, end);
    array = rb_ary_new2(header_items_count);
    while (row_count--) {
        hash = rb_hash_new();
        for (i = 0; i < header_items_count; i++) {
            if (*ptr >= end) {
                rb_raise(rb_eArgError, "unexpected end of input");
            }

            if (*ptr[0] == WATCHMAN_SKIP_MARKER) {
                *ptr += sizeof(uint8_t);
            } else {
                value = watchman_load(ptr, end);
                key = rb_ary_entry(header, i);
                rb_hash_aset(hash, key, value);
            }
        }
        rb_ary_push(array, hash);
    }
    return array;
}

/**
 * Reads and returns an object encoded in the Watchman binary protocol format,
 * starting at `ptr` and finishing at or before `end`
 */
VALUE watchman_load(char **ptr, char *end) {
    if (*ptr >= end) {
        rb_raise(rb_eArgError, "unexpected end of input");
    }

    switch (*ptr[0]) {
        case WATCHMAN_ARRAY_MARKER:
            return watchman_load_array(ptr, end);
        case WATCHMAN_HASH_MARKER:
            return watchman_load_hash(ptr, end);
        case WATCHMAN_STRING_MARKER:
            return watchman_load_string(ptr, end);
        case WATCHMAN_INT8_MARKER:
        case WATCHMAN_INT16_MARKER:
        case WATCHMAN_INT32_MARKER:
        case WATCHMAN_INT64_MARKER:
            return LL2NUM(watchman_load_int(ptr, end));
        case WATCHMAN_FLOAT_MARKER:
            return rb_float_new(watchman_load_double(ptr, end));
        case WATCHMAN_TRUE:
            *ptr += 1;
            return Qtrue;
        case WATCHMAN_FALSE:
            *ptr += 1;
            return Qfalse;
        case WATCHMAN_NIL:
            *ptr += 1;
            return Qnil;
        case WATCHMAN_TEMPLATE_MARKER:
            return watchman_load_template(ptr, end);
        default:
            rb_raise(rb_eTypeError, "unsupported type");
    }

    return Qnil; // keep the compiler happy
}

/**
 * CommandT::Watchman::Utils.load(serialized)
 *
 * Converts the binary object, `serialized`, from the Watchman binary protocol
 * format into a normal Ruby object.
 */
VALUE CommandTWatchmanUtils_load(VALUE self, VALUE serialized) {
    char *ptr, *end;
    long len;
    uint64_t payload_size;
    VALUE loaded;
    serialized = StringValue(serialized);
    len = RSTRING_LEN(serialized);
    ptr = RSTRING_PTR(serialized);
    end = ptr + len;

    // expect at least the binary marker and a int8_t length counter
    if ((size_t)len < sizeof(WATCHMAN_BINARY_MARKER) - 1 + sizeof(int8_t) * 2) {
        rb_raise(rb_eArgError, "undersized header");
    }

    if (memcmp(ptr, WATCHMAN_BINARY_MARKER, sizeof(WATCHMAN_BINARY_MARKER) - 1)) {
        rb_raise(rb_eArgError, "missing binary marker");
    }

    // get size marker
    ptr += sizeof(WATCHMAN_BINARY_MARKER) - 1;
    payload_size = watchman_load_int(&ptr, end);
    if (!payload_size) {
        rb_raise(rb_eArgError, "empty payload");
    }

    // sanity check length
    if (ptr + payload_size != end) {
        rb_raise(
            rb_eArgError,
            "payload size mismatch (%lu)",
            (unsigned long)(end - (ptr + payload_size))
        );
    }

    loaded = watchman_load(&ptr, end);

    // one more sanity check
    if (ptr != end) {
        rb_raise(
            rb_eArgError,
            "payload termination mismatch (%lu)",
            (unsigned long)(end - ptr)
        );
    }

    return loaded;
}

/**
 * CommandT::Watchman::Utils.dump(serializable)
 *
 * Converts the Ruby object, `serializable`, into a binary string in the
 * Watchman binary protocol format.
 *
 * Examples of serializable objects include arrays, hashes, strings, numbers
 * (integers, floats), booleans, and nil.
 */
VALUE CommandTWatchmanUtils_dump(VALUE self, VALUE serializable) {
    uint64_t *len;
    VALUE serialized;
    watchman_t *w = watchman_init();
    watchman_dump(w, serializable);

    // update header with final length information
    len = (uint64_t *)(w->data + sizeof(WATCHMAN_HEADER) - sizeof(uint64_t) - 1);
    *len = w->len - sizeof(WATCHMAN_HEADER) + 1;

    // prepare final return value
    serialized = rb_str_buf_new(w->len);
    rb_str_buf_cat(serialized, (const char*)w->data, w->len);
    watchman_free(w);
    return serialized;
}

/**
 * Helper method for raising a SystemCallError wrapping a lower-level error code
 * coming from the `errno` global variable.
 */
void watchman_raise_system_call_error(int number) {
    VALUE error = INT2FIX(number);
    rb_exc_raise(rb_class_new_instance(1, &error, rb_eSystemCallError));
}

// How far we have to look to figure out the size of the PDU header
#define WATCHMAN_SNIFF_BUFFER_SIZE sizeof(WATCHMAN_BINARY_MARKER) - 1 + sizeof(int8_t)

// How far we have to peek, at most, to figure out the size of the PDU itself
#define WATCHMAN_PEEK_BUFFER_SIZE \
    sizeof(WATCHMAN_BINARY_MARKER) - 1 + \
    sizeof(WATCHMAN_INT64_MARKER) + \
    sizeof(int64_t)

/**
 * CommandT::Watchman::Utils.query(query, socket)
 *
 * Converts `query`, a Watchman query comprising Ruby objects, into the Watchman
 * binary protocol format, transmits it over socket, and unserializes and
 * returns the result.
 */
VALUE CommandTWatchmanUtils_query(VALUE self, VALUE query, VALUE socket) {
    char *payload;
    int fileno, flags;
    int8_t peek[WATCHMAN_PEEK_BUFFER_SIZE];
    int8_t sizes[] = { 0, 0, 0, 1, 2, 4, 8 };
    int8_t sizes_idx;
    int8_t *pdu_size_ptr;
    int64_t payload_size;
    long query_len;
    ssize_t peek_size, sent, received;
    void *buffer;
    VALUE loaded, serialized;
    fileno = NUM2INT(rb_funcall(socket, rb_intern("fileno"), 0));

    // do blocking I/O to simplify the following logic
    flags = fcntl(fileno, F_GETFL);
    if (fcntl(fileno, F_SETFL, flags & ~O_NONBLOCK) == -1) {
        rb_raise(rb_eRuntimeError, "unable to clear O_NONBLOCK flag");
    }

    // send the message
    serialized = CommandTWatchmanUtils_dump(self, query);
    query_len = RSTRING_LEN(serialized);
    sent = send(fileno, RSTRING_PTR(serialized), query_len, 0);
    if (sent == -1) {
        watchman_raise_system_call_error(errno);
    } else if (sent != query_len) {
        rb_raise(rb_eRuntimeError, "expected to send %ld bytes but sent %ld",
            query_len, sent);
    }

    // sniff to see how large the header is
    received = recv(fileno, peek, WATCHMAN_SNIFF_BUFFER_SIZE, MSG_PEEK | MSG_WAITALL);
    if (received == -1) {
        watchman_raise_system_call_error(errno);
    } else if (received != WATCHMAN_SNIFF_BUFFER_SIZE) {
        rb_raise(rb_eRuntimeError, "failed to sniff PDU header");
    }

    // peek at size of PDU
    sizes_idx = peek[sizeof(WATCHMAN_BINARY_MARKER) - 1];
    if (sizes_idx < WATCHMAN_INT8_MARKER || sizes_idx > WATCHMAN_INT64_MARKER) {
        rb_raise(rb_eRuntimeError, "bad PDU size marker");
    }
    peek_size = sizeof(WATCHMAN_BINARY_MARKER) - 1 + sizeof(int8_t) +
        sizes[sizes_idx];

    received = recv(fileno, peek, peek_size, MSG_PEEK);
    if (received == -1) {
        watchman_raise_system_call_error(errno);
    } else if (received != peek_size) {
        rb_raise(rb_eRuntimeError, "failed to peek at PDU header");
    }
    pdu_size_ptr = peek + sizeof(WATCHMAN_BINARY_MARKER) - sizeof(int8_t);
    payload_size =
        peek_size +
        watchman_load_int((char **)&pdu_size_ptr, (char *)peek + peek_size);

    // actually read the PDU
    buffer = xmalloc(payload_size);
    if (!buffer) {
        rb_raise(
            rb_eNoMemError,
            "failed to allocate %lld bytes",
            (long long int)payload_size
        );
    }
    received = recv(fileno, buffer, payload_size, MSG_WAITALL);
    if (received == -1) {
        watchman_raise_system_call_error(errno);
    } else if (received != payload_size) {
        rb_raise(rb_eRuntimeError, "failed to load PDU");
    }
    payload = (char *)buffer + peek_size;
    loaded = watchman_load(&payload, payload + payload_size);
    free(buffer);
    return loaded;
}

#else /* don't build Watchman utils; supply stubs only*/

VALUE CommandTWatchmanUtils_load(VALUE self, VALUE serialized) {
    rb_raise(rb_eRuntimeError, "unsupported operation");
}

VALUE CommandTWatchmanUtils_dump(VALUE self, VALUE serializable) {
    rb_raise(rb_eRuntimeError, "unsupported operation");
}

VALUE CommandTWatchmanUtils_query(VALUE self, VALUE query, VALUE socket) {
    rb_raise(rb_eRuntimeError, "unsupported operation");
}

#endif
ruby/command-t/ext.h	[[[1
37
// Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

extern VALUE mCommandT;              // module CommandT
extern VALUE cCommandTMatcher;       // class CommandT::Matcher
extern VALUE mCommandTWatchman;      // module CommandT::Watchman
extern VALUE mCommandTWatchmanUtils; // module CommandT::Watchman::Utils

// Encapsulates common pattern of checking for an option in an optional
// options hash. The hash itself may be nil, but an exception will be
// raised if it is not nil and not a hash.
VALUE CommandT_option_from_hash(const char *option, VALUE hash);

// Debugging macro.
#define ruby_inspect(obj) rb_funcall(rb_mKernel, rb_intern("p"), 1, obj)
ruby/command-t/match.h	[[[1
36
// Copyright 2010-2013 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

// struct for representing an individual match
typedef struct {
    VALUE   path;
    double  score;
} match_t;

extern void calculate_match(VALUE str,
                            VALUE needle,
                            VALUE always_show_dot_files,
                            VALUE never_show_dot_files,
                            match_t *out);
ruby/command-t/matcher.h	[[[1
27
// Copyright 2010-2013 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

extern VALUE CommandTMatcher_initialize(int argc, VALUE *argv, VALUE self);
extern VALUE CommandTMatcher_sorted_matches_for(int argc, VALUE *argv, VALUE self);
ruby/command-t/ruby_compat.h	[[[1
49
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

// for compatibility with older versions of Ruby which don't declare RSTRING_PTR
#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif

// for compatibility with older versions of Ruby which don't declare RSTRING_LEN
#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif

// for compatibility with older versions of Ruby which don't declare RARRAY_PTR
#ifndef RARRAY_PTR
#define RARRAY_PTR(a) (RARRAY(a)->ptr)
#endif

// for compatibility with older versions of Ruby which don't declare RARRAY_LEN
#ifndef RARRAY_LEN
#define RARRAY_LEN(a) (RARRAY(a)->len)
#endif

// for compatibility with older versions of Ruby which don't declare RFLOAT_VALUE
#ifndef RFLOAT_VALUE
#define RFLOAT_VALUE(f) (RFLOAT(f)->value)
#endif
ruby/command-t/watchman.h	[[[1
52
// Copyright 2014 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

/**
 * @module CommandT::Watchman::Utils
 *
 * Methods for working with the Watchman binary protocol
 *
 * @see https://github.com/facebook/watchman/blob/master/BSER.markdown
 */

/**
 * Convert an object serialized using the Watchman binary protocol[0] into an
 * unpacked Ruby object
 */
extern VALUE CommandTWatchmanUtils_load(VALUE self, VALUE serialized);

/**
 * Serialize a Ruby object into the Watchman binary protocol format
 */
extern VALUE CommandTWatchmanUtils_dump(VALUE self, VALUE serializable);

/**
 * Issue `query` to the Watchman instance listening on `socket` (a `UNIXSocket`
 * instance) and return the result
 *
 * The query is serialized following the Watchman binary protocol and the
 * result is converted to native Ruby objects before returning to the caller.
 */
extern VALUE CommandTWatchmanUtils_query(VALUE self, VALUE query, VALUE socket);
ruby/command-t/depend	[[[1
24
# Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

CFLAGS += -Wall -Wextra -Wno-unused-parameter
doc/command-t.txt	[[[1
1226
*command-t.txt* Command-T plug-in for Vim         *command-t*

CONTENTS                                        *command-t-contents*

 1. Introduction            |command-t-intro|
 2. Requirements            |command-t-requirements|
 3. Installation            |command-t-installation|
 3. Managing using Pathogen |command-t-pathogen|
 4. Trouble-shooting        |command-t-trouble-shooting|
 5. Usage                   |command-t-usage|
 6. Commands                |command-t-commands|
 7. Mappings                |command-t-mappings|
 8. Options                 |command-t-options|
 9. FAQ                     |command-t-faq|
10. Tips                    |command-t-tips|
11. Authors                 |command-t-authors|
12. Development             |command-t-development|
13. Website                 |command-t-website|
14. Donations               |command-t-donations|
15. License                 |command-t-license|
16. History                 |command-t-history|


INTRODUCTION                                    *command-t-intro*

The Command-T plug-in provides an extremely fast, intuitive mechanism for
opening files and buffers with a minimal number of keystrokes. It's named
"Command-T" because it is inspired by the "Go to File" window bound to
Command-T in TextMate.

Files are selected by typing characters that appear in their paths, and are
ordered by an algorithm which knows that characters that appear in certain
locations (for example, immediately after a path separator) should be given
more weight.

To search efficiently, especially in large projects, you should adopt a
"path-centric" rather than a "filename-centric" mentality. That is you should
think more about where the desired file is found rather than what it is
called. This means narrowing your search down by including some characters
from the upper path components rather than just entering characters from the
filename itself.

Screencasts demonstrating the plug-in can be viewed at:

  https://wincent.com/products/command-t


REQUIREMENTS                                    *command-t-requirements*

The plug-in requires Vim compiled with Ruby support, a compatible Ruby
installation at the operating system level, and a C compiler to build
the Ruby extension.


1. Vim compiled with Ruby support ~

You can check for Ruby support by launching Vim with the --version switch:

  vim --version

If "+ruby" appears in the version information then your version of Vim has
Ruby support.

Another way to check is to simply try using the :ruby command from within Vim
itself:

  :ruby 1

If your Vim lacks support you'll see an error message like this:

  E319: Sorry, the command is not available in this version

The version of Vim distributed with OS X may not include Ruby support (for
example, Snow Leopard, which was the current version of OS X when Command-T
was first released, did not support Ruby in the system Vim, but the current
version of OS X at the time of writing, Mavericks, does). All recent versions
of MacVim come with Ruby support; it is available from:

  http://github.com/b4winckler/macvim/downloads

For Windows users, the Vim 7.2 executable available from www.vim.org does
include Ruby support, and is recommended over version 7.3 (which links against
Ruby 1.9, but apparently has some bugs that need to be resolved).


2. Ruby ~

In addition to having Ruby support in Vim, your system itself must have a
compatible Ruby install. "Compatible" means the same version as Vim itself
links against. If you use a different version then Command-T is unlikely
to work (see |command-t-trouble-shooting| below).

On OS X Snow Leopard, Lion and Mountain Lion, the system comes with Ruby 1.8.7
and all recent versions of MacVim (the 7.2 snapshots and 7.3) are linked
against it.

On OS X Mavericks, the default system ruby is 2.0, but MacVim continues to
link against 1.8.7, which is also present on the system at:

  /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby

On Linux and similar platforms, the linked version of Ruby will depend on
your distribution. You can usually find this out by examining the
compilation and linking flags displayed by the |:version| command in Vim, and
by looking at the output of:

  :ruby puts "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"

A suitable Ruby environment for Windows can be installed using the Ruby
1.8.7-p299 RubyInstaller available at:

  http://rubyinstaller.org/downloads/archives

If using RubyInstaller be sure to download the installer executable, not the
7-zip archive. When installing mark the checkbox "Add Ruby executables to your
PATH" so that Vim can find them.


3. C compiler ~

Part of Command-T is implemented in C as a Ruby extension for speed, allowing
it to work responsively even on directory hierarchies containing enormous
numbers of files. As such, a C compiler is required in order to build the
extension and complete the installation.

On OS X, this can be obtained by installing the Xcode Tools from the App
Store.

On Windows, the RubyInstaller Development Kit can be used to conveniently
install the necessary tool chain:

  http://rubyinstaller.org/downloads/archives

At the time of writing, the appropriate development kit for use with Ruby
1.8.7 is DevKit-3.4.5r3-20091110.

To use the Development Kit extract the archive contents to your C:\Ruby
folder.


INSTALLATION                                    *command-t-installation*

You can install Command-T by obtaining the source files and building the C
extension. The recommended way to get the source is by using a plug-in
management system such as Pathogen (see |command-t-pathogen|).

Command-T is also distributed as a "vimball" which means that it can be
installed by opening it in Vim and then sourcing it:

  :e command-t.vba
  :so %

The files will be installed in your |'runtimepath'|. To check where this is
you can issue:

  :echo &rtp

The C extension must then be built, which can be done from the shell. If you
use a typical |'runtimepath'| then the files were installed inside ~/.vim and
you can build the extension with:

  cd ~/.vim/ruby/command-t
  ruby extconf.rb
  make

Note: If you are an RVM or rbenv user, you must perform the build using the
same version of Ruby that Vim itself is linked against. This will often be the
system Ruby, which can be selected before issuing the "make" command with one
of the following commands:

  rvm use system
  rbenv local system

Note: If you are on OS X Mavericks and compiling against MacVim, the default
system Ruby is 2.0 but MacVim still links against the older 1.8.7 Ruby that is
also bundled with the system; in this case the build command becomes:

  cd ~/.vim/ruby/command-t
  /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby extconf.rb
  make

Note: Make sure you compile targeting the same architecture Vim was built for.
For instance, MacVim binaries are built for i386, but sometimes GCC compiles
for x86_64. First you have to check the platform Vim was built for:

  vim --version
  ...
  Compilation: gcc ... -arch i386 ...
  ...

and make sure you use the correct ARCHFLAGS during compilation:

  export ARCHFLAGS="-arch i386"
  make

Note: If you are on Fedora 17+, you can install Command-T from the system
repository with:

  su -c 'yum install vim-command-t'

MANAGING USING PATHOGEN                         *command-t-pathogen*

Pathogen is a plugin that allows you to maintain plugin installations in
separate, isolated subdirectories under the "bundle" directory in your
|'runtimepath'|. The following examples assume that you already have
Pathogen installed and configured, and that you are installing into
~/.vim/bundle. For more information about Pathogen, see:

  http://www.vim.org/scripts/script.php?script_id=2332

If you manage your entire ~/.vim folder using Git then you can add the
Command-T repository as a submodule:

  cd ~/.vim
  git submodule add git://git.wincent.com/command-t.git bundle/command-t
  git submodule init

Or if you just wish to do a simple clone instead of using submodules:

  cd ~/.vim
  git clone git://git.wincent.com/command-t.git bundle/command-t

Once you have a local copy of the repository you can update it at any time
with:

  cd ~/.vim/bundle/command-t
  git pull

Or you can switch to a specific release with:

  cd ~/.vim/bundle/command-t
  git checkout 0.8b

After installing or updating you must build the extension:

  cd ~/.vim/bundle/command-t/ruby/command-t
  ruby extconf.rb
  make

While the Vimball installation automatically generates the help tags, under
Pathogen it is necessary to do so explicitly from inside Vim:

  :call pathogen#helptags()


TROUBLE-SHOOTING                                *command-t-trouble-shooting*

Most installation problems are caused by a mismatch between the version of
Ruby on the host operating system, and the version of Ruby that Vim itself
linked against at compile time. For example, if one is 32-bit and the other is
64-bit, or one is from the Ruby 1.9 series and the other is from the 1.8
series, then the plug-in is not likely to work.

As such, on OS X, I recommend using the standard Ruby that comes with the
system (currently 1.8.7) along with the latest version of MacVim (currently
version 7.3). If you wish to use custom builds of Ruby or of MacVim (not
recommmended) then you will have to take extra care to ensure that the exact
same Ruby environment is in effect when building Ruby, Vim and the Command-T
extension.

For Windows, the following combination is known to work:

  - Vim 7.2 from http://www.vim.org/download.php:
      ftp://ftp.vim.org/pub/vim/pc/gvim72.exe
  - Ruby 1.8.7-p299 from http://rubyinstaller.org/downloads/archives:
      http://rubyforge.org/frs/download.php/71492/rubyinstaller-1.8.7-p299.exe
  - DevKit 3.4.5r3-20091110 from http://rubyinstaller.org/downloads/archives:
      http://rubyforge.org/frs/download.php/66888/devkit-3.4.5r3-20091110.7z

If a problem occurs the first thing you should do is inspect the output of:

  ruby extconf.rb
  make

During the installation, and:

  vim --version

And compare the compilation and linker flags that were passed to the
extension and to Vim itself when they were built. If the Ruby-related
flags or architecture flags are different then it is likely that something
has changed in your Ruby environment and the extension may not work until
you eliminate the discrepancy.


USAGE                                           *command-t-usage*

Bring up the Command-T file window by typing:

  <Leader>t

This mapping is set up automatically for you, provided you do not already have
a mapping for <Leader>t or |:CommandT|. You can also bring up the file window
by issuing the command:

  :CommandT

A prompt will appear at the bottom of the screen along with a file window
showing all of the files in the current directory (as returned by the
|:pwd| command).

For the most efficient file navigation within a project it's recommended that
you |:cd| into the root directory of your project when starting to work on it.
If you wish to open a file from outside of the project folder you can pass in
an optional path argument (relative or absolute) to |:CommandT|:

  :CommandT ../path/to/other/files

Type letters in the prompt to narrow down the selection, showing only the
files whose paths contain those letters in the specified order. Letters do not
need to appear consecutively in a path in order for it to be classified as a
match.

Once the desired file has been selected it can be opened by pressing <CR>.
(By default files are opened in the current window, but there are other
mappings that you can use to open in a vertical or horizontal split, or in
a new tab.) Note that if you have |'nohidden'| set and there are unsaved
changes in the current window when you press <CR> then opening in the current
window would fail; in this case Command-T will open the file in a new split.

The following mappings are active when the prompt has focus:

    <BS>        delete the character to the left of the cursor
    <Del>       delete the character at the cursor
    <Left>      move the cursor one character to the left
    <C-h>       move the cursor one character to the left
    <Right>     move the cursor one character to the right
    <C-l>       move the cursor one character to the right
    <C-a>       move the cursor to the start (left)
    <C-e>       move the cursor to the end (right)
    <C-u>       clear the contents of the prompt
    <Tab>       change focus to the file listing

The following mappings are active when the file listing has focus:

    <Tab>       change focus to the prompt

The following mappings are active when either the prompt or the file listing
has focus:

    <CR>        open the selected file
    <C-CR>      open the selected file in a new split window
    <C-s>       open the selected file in a new split window
    <C-v>       open the selected file in a new vertical split window
    <C-t>       open the selected file in a new tab
    <C-j>       select next file in the file listing
    <C-n>       select next file in the file listing
    <Down>      select next file in the file listing
    <C-k>       select previous file in the file listing
    <C-p>       select previous file in the file listing
    <Up>        select previous file in the file listing
    <C-f>       flush the cache (see |:CommandTFlush| for details)
    <C-q>       place the current matches in the quickfix window
    <C-c>       cancel (dismisses file listing)

The following is also available on terminals which support it:

    <Esc>       cancel (dismisses file listing)

Note that the default mappings can be overriden by setting options in your
~/.vimrc file (see the OPTIONS section for a full list of available options).

In addition, when the file listing has focus, typing a character will cause
the selection to jump to the first path which begins with that character.
Typing multiple characters consecutively can be used to distinguish between
paths which begin with the same prefix.


COMMANDS                                        *command-t-commands*

                                                *:CommandT*
|:CommandT|       Brings up the Command-T file window, starting in the
                current working directory as returned by the|:pwd|
                command.

                                                *:CommandTBuffer*
|:CommandTBuffer| Brings up the Command-T buffer window.
                This works exactly like the standard file window,
                except that the selection is limited to files that
                you already have open in buffers.

                                                *:CommandTMRU*
|:CommandTMRU|    Brings up the Command-T buffer window, except that matches
                are shown in MRU (most recently used) order. If you prefer to
                use this over the normal buffer finder, I suggest overwriting
                the standard mapping with a command like:

                    :nnoremap <silent> <leader>b :CommandTMRU<CR>

                Note that Command-T only starts recording most recently used
                buffers when you first use a Command-T command or mapping;
                this is an optimization to improve startup time.

                                                *:CommandTJumps*
|:CommandTJump|   Brings up the Command-T jumplist window.
                This works exactly like the standard file window,
                except that the selection is limited to files that
                you already have in the jumplist. Note that jumps
                can persist across Vim sessions (see Vim's |jumplist|
                documentation for more info).

                                                *:CommandTTag*
|:CommandTTag|    Brings up the Command-T window tags window, which can
                be used to select from the tags, if any, returned by
                Vim's |taglist()| function. See Vim's |tag| documentation
                for general info on tags.

                                                *:CommandTFlush*
|:CommandTFlush|  Instructs the plug-in to flush its path cache, causing
                the directory to be rescanned for new or deleted paths
                the next time the file window is shown (pressing <C-f> when
                a match listing is visible flushes the cache immediately; this
                mapping is configurable via the |g:CommandTRefreshMap|
                setting). In addition, all configuration settings are
                re-evaluated, causing any changes made to settings via the
                |:let| command to be picked up.


MAPPINGS                                        *command-t-mappings*

By default Command-T comes with only two mappings:

  <Leader>t     bring up the Command-T file window
  <Leader>b     bring up the Command-T buffer window

However, Command-T won't overwrite a pre-existing mapping so if you prefer
to define different mappings use lines like these in your ~/.vimrc:

  nnoremap <silent> <Leader>t :CommandT<CR>
  nnoremap <silent> <Leader>b :CommandTBuffer<CR>

Replacing "<Leader>t" or "<Leader>b" with your mapping of choice.

Note that in the case of MacVim you actually can map to Command-T (written
as <D-t> in Vim) in your ~/.gvimrc file if you first unmap the existing menu
binding of Command-T to "New Tab":

  if has("gui_macvim")
    macmenu &File.New\ Tab key=<nop>
    map <D-t> :CommandT<CR>
  endif

When the Command-T window is active a number of other additional mappings
become available for doing things like moving between and selecting matches.
These are fully described above in the USAGE section, and settings for
overriding the mappings are listed below under OPTIONS.


OPTIONS                                         *command-t-options*

A number of options may be set in your ~/.vimrc to influence the behaviour of
the plug-in. To set an option, you include a line like this in your ~/.vimrc:

    let g:CommandTMaxFiles=20000

To have Command-T pick up new settings immediately (that is, without having
to restart Vim) you can issue the |:CommandTFlush| command after making
changes via |:let|.

Following is a list of all available options:

                                               *g:CommandTMaxFiles*
  |g:CommandTMaxFiles|                           number (default 30000)

      The maximum number of files that will be considered when scanning the
      current directory. Upon reaching this number scanning stops. This
      limit applies only to file listings and is ignored for buffer
      listings.

                                               *g:CommandTMaxDepth*
  |g:CommandTMaxDepth|                           number (default 15)

      The maximum depth (levels of recursion) to be explored when scanning the
      current directory. Any directories at levels beyond this depth will be
      skipped.

                                               *g:CommandTMaxCachedDirectories*
  |g:CommandTMaxCachedDirectories|               number (default 1)

      The maximum number of directories whose contents should be cached when
      recursively scanning. With the default value of 1, each time you change
      directories the cache will be emptied and Command-T will have to
      rescan. Higher values will make Command-T hold more directories in the
      cache, bringing performance at the cost of memory usage. If set to 0,
      there is no limit on the number of cached directories.

                                               *g:CommandTMaxHeight*
  |g:CommandTMaxHeight|                          number (default: 0)

      The maximum height in lines the match window is allowed to expand to.
      If set to 0, the window will occupy as much of the available space as
      needed to show matching entries.

                                               *g:CommandTInputDebounce*
  |g:CommandTInputDebounce|                      number (default: 50)

      The number of milliseconds to wait before updating the match listing
      following a key-press. This can be used to avoid wasteful recomputation
      when making a rapid series of key-presses in a directory with many tens
      (or hundreds) of thousands of files.

                                               *g:CommandTFileScanner*
  |g:CommandTFileScanner|                        string (default: 'ruby')

      The underlying scanner implementation that should be used to explore the
      filesystem. Possible values are:

      - "ruby": uses built-in Ruby and should work everywhere, albeit slowly
        on large (many tens of thousands of files) hierarchies.

      - "find": uses the command-line tool of the same name, which can be much
        faster on large projects because it is written in pure C, but may not
        work on systems without the tool or with an incompatible version of
        the tool.

      - "watchman": uses Watchman (https://github.com/facebook/watchman) if
        available; otherwise falls back to "find". Note that this scanner is
        intended for use with very large hierarchies (hundreds of thousands of
        files) and so the task of deciding which files should be included is
        entirely delegated to Watchman; this means that settings which
        Command-T would usually consult, such as 'wildignore' and
        |g:CommandTScanDotDirectories| are ignored.

                                               *g:CommandTMinHeight*
  |g:CommandTMinHeight|                          number (default: 0)

      The minimum height in lines the match window is allowed to shrink to.
      If set to 0, will default to a single line. If set above the max height,
      will default to |g:CommandTMaxHeight|.

                                               *g:CommandTAlwaysShowDotFiles*
  |g:CommandTAlwaysShowDotFiles|                 boolean (default: 0)

      When showing the file listing Command-T will by default show dot-files
      only if the entered search string contains a dot that could cause a
      dot-file to match. When set to a non-zero value, this setting instructs
      Command-T to always include matching dot-files in the match list
      regardless of whether the search string contains a dot. See also
      |g:CommandTNeverShowDotFiles|. Note that this setting only influences
      the file listing; the buffer listing treats dot-files like any other
      file.

                                               *g:CommandTNeverShowDotFiles*
  |g:CommandTNeverShowDotFiles|                  boolean (default: 0)

      In the file listing, Command-T will by default show dot-files if the
      entered search string contains a dot that could cause a dot-file to
      match. When set to a non-zero value, this setting instructs Command-T to
      never show dot-files under any circumstances. Note that it is
      contradictory to set both this setting and
      |g:CommandTAlwaysShowDotFiles| to true, and if you do so Vim will suffer
      from headaches, nervous twitches, and sudden mood swings. This setting
      has no effect in buffer listings, where dot files are treated like any
      other file.

                                               *g:CommandTScanDotDirectories*
  |g:CommandTScanDotDirectories|                 boolean (default: 0)

      Normally Command-T will not recurse into "dot-directories" (directories
      whose names begin with a dot) while performing its initial scan. Set
      this setting to a non-zero value to override this behavior and recurse.
      Note that this setting is completely independent of the
      |g:CommandTAlwaysShowDotFiles| and |g:CommandTNeverShowDotFiles|
      settings; those apply only to the selection and display of matches
      (after scanning has been performed), whereas
      |g:CommandTScanDotDirectories| affects the behaviour at scan-time.

      Note also that even with this setting off you can still use Command-T to
      open files inside a "dot-directory" such as ~/.vim, but you have to use
      the |:cd| command to change into that directory first. For example:

        :cd ~/.vim
        :CommandT

                                               *g:CommandTMatchWindowAtTop*
  |g:CommandTMatchWindowAtTop|                   boolean (default: 0)

      When this setting is off (the default) the match window will appear at
      the bottom so as to keep it near to the prompt. Turning it on causes the
      match window to appear at the top instead. This may be preferable if you
      want the best match (usually the first one) to appear in a fixed location
      on the screen rather than moving as the number of matches changes during
      typing.

                                                *g:CommandTMatchWindowReverse*
  |g:CommandTMatchWindowReverse|                  boolean (default: 0)

      When this setting is off (the default) the matches will appear from
      top to bottom with the topmost being selected. Turning it on causes the
      matches to be reversed so the best match is at the bottom and the
      initially selected match is the bottom most. This may be preferable if
      you want the best match to appear in a fixed location on the screen
      but still be near the prompt at the bottom.

                                                *g:CommandTTagIncludeFilenames*
  |g:CommandTTagIncludeFilenames|                 boolean (default: 0)

      When this setting is off (the default) the matches in the |:CommandTTag|
      listing do not include filenames.

                                                *g:CommandTHighlightColor*
  |g:CommandTHighlightColor|                      string (default: 'PmenuSel')

      Specifies the highlight color that will be used to show the currently
      selected item in the match listing window.

                                                *g:CommandTWildIgnore*
  |g:CommandTWildIgnore|                          string (default: none)

      Optionally override Vim's global |'wildignore'| setting during Command-T
      searches. If you wish to supplement rather than replace the global
      setting, you can use a syntax like:

        let g:CommandTWildIgnore=&wildignore . ",**/bower_components/*"

      See also |command-t-wildignore|.

As well as the basic options listed above, there are a number of settings that
can be used to override the default key mappings used by Command-T. For
example, to set <C-x> as the mapping for cancelling (dismissing) the Command-T
window, you would add the following to your ~/.vimrc:

  let g:CommandTCancelMap='<C-x>'

Multiple, alternative mappings may be specified using list syntax:

  let g:CommandTCancelMap=['<C-x>', '<C-c>']

Following is a list of all map settings and their defaults:

                              Setting   Default mapping(s)

                                      *g:CommandTBackspaceMap*
              |g:CommandTBackspaceMap|  <BS>

                                      *g:CommandTDeleteMap*
                 |g:CommandTDeleteMap|  <Del>

                                      *g:CommandTAcceptSelectionMap*
        |g:CommandTAcceptSelectionMap|  <CR>

                                      *g:CommandTAcceptSelectionSplitMap*
   |g:CommandTAcceptSelectionSplitMap|  <C-CR>
                                      <C-s>

                                      *g:CommandTAcceptSelectionTabMap*
     |g:CommandTAcceptSelectionTabMap|  <C-t>

                                      *g:CommandTAcceptSelectionVSplitMap*
  |g:CommandTAcceptSelectionVSplitMap|  <C-v>

                                      *g:CommandTToggleFocusMap*
            |g:CommandTToggleFocusMap|  <Tab>

                                      *g:CommandTCancelMap*
                 |g:CommandTCancelMap|  <C-c>
                                      <Esc> (not on all terminals)

                                      *g:CommandTSelectNextMap*
             |g:CommandTSelectNextMap|  <C-n>
                                      <C-j>
                                      <Down>

                                      *g:CommandTSelectPrevMap*
             |g:CommandTSelectPrevMap|  <C-p>
                                      <C-k>
                                      <Up>

                                      *g:CommandTClearMap*
                  |g:CommandTClearMap|  <C-u>

                                      *g:CommandTRefreshMap*
                |g:CommandTRefreshMap|  <C-f>

                                      *g:CommandTQuickfixMap*
               |g:CommandTQuickfixMap|  <C-q>

                                      *g:CommandTCursorLeftMap*
             |g:CommandTCursorLeftMap|  <Left>
                                      <C-h>

                                      *g:CommandTCursorRightMap*
            |g:CommandTCursorRightMap|  <Right>
                                      <C-l>

                                      *g:CommandTCursorEndMap*
              |g:CommandTCursorEndMap|  <C-e>

                                      *g:CommandTCursorStartMap*
            |g:CommandTCursorStartMap|  <C-a>

In addition to the options provided by Command-T itself, some of Vim's own
settings can be used to control behavior:

                                               *command-t-wildignore*
  |'wildignore'|                                 string (default: '')

      Vim's |'wildignore'| setting is used to determine which files should be
      excluded from listings. This is a comma-separated list of glob patterns.
      It defaults to the empty string, but common settings include "*.o,*.obj"
      (to exclude object files) or ".git,.svn" (to exclude SCM metadata
      directories). For example:

        :set wildignore+=*.o,*.obj,.git

      A pattern such as "vendor/rails/**" would exclude all files and
      subdirectories inside the "vendor/rails" directory (relative to
      directory Command-T starts in).

      See the |'wildignore'| documentation for more information.

      If you want to influence Command-T's file exclusion behavior without
      changing your global |'wildignore'| setting, you can use the
      |g:CommandTWildIgnore| setting to apply an override that takes effect
      only during Command-T searches.


FAQ                                             *command-t-faq*

Why does my build fail with "unknown argument -multiply_definedsuppress"? ~

You may see this on OS X Mavericks when building with the Clang compiler
against the system Ruby. This is an unfortunate Apple bug that breaks
compilation of many Ruby gems with native extensions on Mavericks. It has been
worked around in the upstream Ruby version, but won't be fixed in OS X until
Apple updates their supplied version of Ruby (most likely this won't be until
the next major release):

  https://bugs.ruby-lang.org/issues/9624

Workarounds include building your own Ruby (and then your own Vim and
Command-T), or more simply, building with the following `ARCHFLAGS` set:

  ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future ruby extconf.rb
  make

Why can't I open in a split with <C-CR> and <C-s> in the terminal? ~

It's likely that <C-CR> won't work in most terminals, because the keycode that
is sent to processes running inside them is identical to <CR>; when you type
<C-CR>, terminal Vim literally "sees" <CR>. Unfortunately, there is no
workaround for this.

If you find that <C-s> also doesn't work the most likely explanation is that
XON/XOFF flow control is enabled; this is the default in many environments.
This means that when you press <C-s> all input to the terminal is suspended
until you release it by hitting <C-q>. While input is suspended you may think
your terminal has frozen, but it hasn't.

To disable flow control, add the following to your `.zshrc` or
`.bash_profile`:

  stty -ixon

See the `stty` man page for more details.

Why doesn't the Escape key close the match listing in terminal Vim? ~

In some terminals such as xterm the Escape key misbehaves, so Command-T
doesn't set up a mapping for it. If you want to try using the escape key
anyway, you can add something like the following to your ~/.vimrc file:

  if &term =~ "xterm" || &term =~ "screen"
    let g:CommandTCancelMap = ['<ESC>', '<C-c>']
  endif

This configuration has worked for me with recent versions of Vim on multiple
platforms (OS X, CentOS etc).


TIPS                                            *command-t-tips*

Working with very large repositories ~

One of the primary motivations for writing Command-T was to get fast, robust
high-quality matches even on large hierarchies. The larger the hierarchy, the
more important having good file navigation becomes. This is why Command-T's
performance-critical sections are written in C. This requires a compilation
step and makes Command-T harder to install than similar plug-ins which are
written in pure Vimscript, and can be a disincentive against use. This is a
conscious trade-off; the goal isn't to have as many users as possible, but
rather to provide the best performance at the highest quality.

The speed of the core is high enough that Command-T can afford to burn a bunch
of extra cycles -- using its recursive matching algorithm -- looking for a
higher-quality, more intuitive ranking of search results. Again, the larger
the hierarchy, the more important the quality of result ranking becomes.

Nevertheless, for extremely large hierarchies (of the order of 500,000 files)
some tuning is required in order to get useful and usable performance levels.
Here are some useful example settings:

    let g:CommandTMaxHeight = 30

You want the match listing window to be large enough that you can get useful
feedback about how your search query is going; in large hierarchies there may
be many, many matches for a given query. At the same time, you don't want Vim
wasting valuable cycles repainting a large portion of the screen area,
especially on a large display. Setting the limit to 30 or similar is a
reasonable compromise.

    let g:CommandTMaxFiles = 500000

The default limit of 30,000 files prevents Command-T from "seeing" many of the
files in a large directory hierarchy so you need to increase this limit.

    let g:CommandTInputDebounce = 200

Wait for 200ms of keyboard inactivity before computing search results. For
example, if you are enter "foobar" quickly (ie. within 1 second), there is
little sense in fetching the results for "f", "fo", "foo", "foob", "fooba" and
finally "foobar". Instead, we can just fetch the results for "foobar". This
setting trades off some immediate responsiveness at the micro level for
better performance (real and perceived) and a better search experience
overall.

    let g:CommandTFileScanner = 'watchman'

On a large hierarchy with of the order of 500,000 files, scanning a directory
tree with a tool like the `find` executable may take literally minutes with a
cold cache. Once the cache is warm, the same `find` run may take only a second
or two. Command-T provides a "find" scanner to leverage this performance, but
there is still massive overhead in passing the results through Vim internal
functions that apply 'wildignore' settings and such, so for truly immense
repos the "watchman" scanner is the tool of choice.

This scanner delegates the task of finding files to Facebook's `watchman` tool
(https://github.com/facebook/watchman), which can return results for a 500,000
file hierarchy within about a second.

Note that Watchman has a range of configuration options that can be applied by
files such as `/etc/watchman.json` or per-direcory `.watchmanconfig` files and
which may affect how Command-T works. For example, if your configuration has a
`root_restrict_files` setting that makes Watchman only work with roots that
look like Git or Mercurial repos, then Command-T will fall back to using the
"find" scanner any time you invoke it on a non-repo directory. For
simplicity's sake, it is probably a good idea to use Vim and Command-T
anchored at the root level of your repository in any case.

    let g:CommandTMaxCachedDirectories = 10

Command-T will internally cache up to 10 different directories, so even if you
|cd| repeatedly, it should only need to scan each directory once.

It's advisable to keep a long-running Vim instance in place and let it cache
the directory listings rather than repeatedly closing and re-opening Vim in
order to edit every file. On those occasions when you do need to flush the
cache (ie. with |CommandTFlush| or <C-f> in the match listing window), use of
the Watchman scanner should make the delay barely noticeable.

As noted in the introduction, Command-T works best when you adopt a
"path-centric" mentality. This is especially true on very large hierarchies.
For example, if you're looking for a file at:

  lib/third-party/adapters/restful-services/foobar/foobar-manager.js

you'll be able to narrow your search results down more narrowly if you search
with a query like "librestfoofooman" than "foobar-manager.js". This evidently
requires that you know where the file you're wanting to open exists, but
again, this is a concious design decision: Command-T is made to enable people
who know what they want to open and where it is to open it as quickly as
possible; other tools such as NERDTree exist for visually exploring an unknown
hierarchy.

Over time, you will get a feel for how economical you can afford to be with
your search queries in a given repo. In the example above, if "foo" is not a
very common pattern in your hierarchy, then you may find that you can find
what you need with a very concise query such as "foomanjs". With time, this
kind of ongoing calibration will come quite naturally.

Finally, it is important to be on a relatively recent version of Command-T to
fully benefit from the available performance enhancements:

- version 1.8 (March 2013) sped up the Watchman file scanner by switching its
  communication from the JSON to the binary Watchman protocol
- version 1.7 (February 2014) added the |g:CommandTInputDebounce| and
  |g:CommandTFileScanner| settings, along with support for the Watchman file
  scanner
- version 1.6 (December 2013) added parallelized search
- version 1.5 (September 2013) added memoization to the matching algorithm,
  improving general performance on large hierarchies, but delivering
  spectacular gains on hierarchies with "pathological" characteristics that
  lead the algorithm to exhibit degenerate behavior

AUTHORS                                         *command-t-authors*

Command-T is written and maintained by Wincent Colaiuta <win@wincent.com>.
Other contributors that have submitted patches include (in alphabetical
order):

  Andy Waite              Nadav Samet             Steven Moazami
  Anthony Panozzo         Nate Kane               Sung Pae
  Daniel Hahler           Nicholas Alpi           Thomas Pelletier
  Felix Tjandrawibawa     Noon Silk               Ton van den Heuvel
  Gary Bernhardt          Paul Jolly              Victor Hugo Borja
  Ivan Ukhov              Pavel Sergeev           Vít Ondruch
  Jeff Kreeftmeijer       Rainux Luo              Woody Peterson
  Lucas de Vries          Roland Puntaier         Yan Pritzker
  Marcus Brito            Ross Lagerwall          Yiding Jia
  Marian Schubert         Scott Bronson           Zak Johnson
  Matthew Todd            Seth Fowler
  Mike Lundy              Shlomi Fish

As this was the first Vim plug-in I had ever written I was heavily influenced
by the design of the LustyExplorer plug-in by Stephen Bach, which I understand
was one of the largest Ruby-based Vim plug-ins at the time.

While the Command-T codebase doesn't contain any code directly copied from
LustyExplorer, I did use it as a reference for answers to basic questions (like
"How do you do 'X' in a Ruby-based Vim plug-in?"), and also copied some basic
architectural decisions (like the division of the code into Prompt, Settings
and MatchWindow classes).

LustyExplorer is available from:

  http://www.vim.org/scripts/script.php?script_id=1890


DEVELOPMENT                                     *command-t-development*

Development in progress can be inspected via the project's Git web-based
repository browser at:

  https://wincent.com/repos/command-t

the clone URL for which is:

  git://git.wincent.com/command-t.git

Mirrors exist on GitHub and Gitorious; these are automatically updated once
per hour from the authoritative repository:

  https://github.com/wincent/command-t
  https://gitorious.org/command-t/command-t

Patches are welcome via the usual mechanisms (pull requests, email, posting to
the project issue tracker etc).

As many users choose to track Command-T using Pathogen, which often means
running a version later than the last official release, the intention is that
the "master" branch should be kept in a stable and reliable state as much as
possible.

Riskier changes are first cooked on the "next" branch for a period before
being merged into master. You can track this branch if you're feeling wild and
experimental, but note that the "next" branch may periodically be rewound
(force-updated) to keep it in sync with the "master" branch after each
official release.


WEBSITE                                         *command-t-website*

The official website for Command-T is:

  https://wincent.com/products/command-t

The latest release will always be available from there.

A copy of each release is also available from the official Vim scripts site
at:

  http://www.vim.org/scripts/script.php?script_id=3025

Bug reports should be submitted to the issue tracker at:

  https://wincent.com/issues


DONATIONS                                       *command-t-donations*

Command-T itself is free software released under the terms of the BSD license.
If you would like to support further development you can make a donation via
PayPal to win@wincent.com:

  https://wincent.com/products/command-t/donations


LICENSE                                         *command-t-license*

Copyright 2010-2014 Wincent Colaiuta. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

HISTORY                                         *command-t-history*

1.9.1 (30 May 2014)

- include the file in the release vimball archive that was missing from the
  1.9 release

1.9 (25 May 2014)

- improved startup time using Vim's autload mechanism (patch from Ross
  Lagerwall)
- added MRU (most-recently-used) buffer finder (patch from Ton van den Heuvel)
- fixed edge case in matching algorithm which could cause spurious matches
  with queries containing repeated characters
- fixed slight positive bias in the match scoring algorithm's weighting of
  matching characters based on distance from last match
- tune memoization in match scoring algorithm, yielding a more than 10% speed
  boost

1.8 (31 March 2014)

- taught Watchman file scanner to use the binary protocol instead of JSON,
  roughly doubling its speed
- build changes to accommodate MinGW (patch from Roland Puntaier)

1.7 (9 March 2014)

- added |g:CommandTInputDebounce|, which can be used to improve responsiveness
  in large file hierarchies (based on patch from Yiding Jia)
- added a potentially faster file scanner which uses the `find` executable
  (based on patch from Yiding Jia)
- added a file scanner that knows how to talk to Watchman
  (https://github.com/facebook/watchman)
- added |g:CommandTFileScanner|, which can be used to switch file scanners
- fix processor count detection on some platforms (patch from Pavel Sergeev)

1.6.1 (22 December 2013)

- defer processor count detection until runtime (makes it possible to sensibly
  build Command-T on one machine and use it on another)

1.6 (16 December 2013)

- on systems with POSIX threads (such as OS X and Linux), Command-T will use
  threads to compute match results in parallel, resulting in a large speed
  boost that is especially noticeable when navigating large projects

1.5.1 (23 September 2013)

- exclude large benchmark fixture file from source exports (patch from Vít
  Ondruch)

1.5 (18 September 2013)

- don't scan "pathological" filesystem structures (ie. circular or
  self-referential symlinks; patch from Marcus Brito)
- gracefully handle files starting with "+" (patch from Ivan Ukhov)
- switch default selection highlight color for better readability (suggestion
  from André Arko), but make it possible to configure via the
  |g:CommandTHighlightColor| setting
- added a mapping to take the current matches and put then in the quickfix
  window
- performance improvements, particularly noticeable with large file
  hierarchies
- added |g:CommandTWildIgnore| setting (patch from Paul Jolly)

1.4 (20 June 2012)

- added |:CommandTTag| command (patches from Noon Silk)
- turn off |'colorcolumn'| and |'relativenumber'| in the match window (patch
  from Jeff Kreeftmeijer)
- documentation update (patch from Nicholas Alpi)
- added |:CommandTMinHeight| option (patch from Nate Kane)
- highlight (by underlining) matched characters in the match listing (requires
  Vim to have been compiled with the +conceal feature, which is available in
  Vim 7.3 or later; patch from Steven Moazami)
- added the ability to flush the cache while the match window is open using
  <C-f>

1.3.1 (18 December 2011)

- fix jumplist navigation under Ruby 1.9.x (patch from Woody Peterson)

1.3 (27 November 2011)

- added the option to maintain multiple caches when changing among
  directories; see the accompanying |g:CommandTMaxCachedDirectories| setting
- added the ability to navigate using the Vim jumplist (patch from Marian
  Schubert)

1.2.1 (30 April 2011)

- Remove duplicate copy of the documentation that was causing "Duplicate tag"
  errors
- Mitigate issue with distracting blinking cursor in non-GUI versions of Vim
  (patch from Steven Moazami)

1.2 (30 April 2011)

- added |g:CommandTMatchWindowReverse| option, to reverse the order of items
  in the match listing (patch from Steven Moazami)

1.1b2 (26 March 2011)

- fix a glitch in the release process; the plugin itself is unchanged since
  1.1b

1.1b (26 March 2011)

- add |:CommandTBuffer| command for quickly selecting among open buffers

1.0.1 (5 January 2011)

- work around bug when mapping |:CommandTFlush|, wherein the default mapping
  for |:CommandT| would not be set up
- clean up when leaving the Command-T buffer via unexpected means (such as
  with <C-W k> or similar)

1.0 (26 November 2010)

- make relative path simplification work on Windows

1.0b (5 November 2010)

- work around platform-specific Vim 7.3 bug seen by some users (wherein
  Vim always falsely reports to Ruby that the buffer numbers is 0)
- re-use the buffer that is used to show the match listing, rather than
  throwing it away and recreating it each time Command-T is shown; this
  stops the buffer numbers from creeping up needlessly

0.9 (8 October 2010)

- use relative paths when opening files inside the current working directory
  in order to keep buffer listings as brief as possible (patch from Matthew
  Todd)

0.8.1 (14 September 2010)

- fix mapping issues for users who have set |'notimeout'| (patch from Sung
  Pae)

0.8 (19 August 2010)

- overrides for the default mappings can now be lists of strings, allowing
  multiple mappings to be defined for any given action
- <Leader>t mapping only set up if no other map for |:CommandT| exists
  (patch from Scott Bronson)
- prevent folds from appearing in the match listing
- tweaks to avoid the likelihood of "Not enough room" errors when trying to
  open files
- watch out for "nil" windows when restoring window dimensions
- optimizations (avoid some repeated downcasing)
- move all Ruby files under the "command-t" subdirectory and avoid polluting
  the "Vim" module namespace

0.8b (11 July 2010)

- large overhaul of the scoring algorithm to make the ordering of returned
  results more intuitive; given the scope of the changes and room for
  optimization of the new algorithm, this release is labelled as "beta"

0.7 (10 June 2010)

- handle more |'wildignore'| patterns by delegating to Vim's own |expand()|
  function; with this change it is now viable to exclude patterns such as
  'vendor/rails/**' in addition to filename-only patterns like '*.o' and
  '.git' (patch from Mike Lundy)
- always sort results alphabetically for empty search strings; this eliminates
  filesystem-specific variations (patch from Mike Lundy)

0.6 (28 April 2010)

- |:CommandT| now accepts an optional parameter to specify the starting
  directory, temporarily overriding the usual default of Vim's |:pwd|
- fix truncated paths when operating from root directory

0.5.1 (11 April 2010)

- fix for Ruby 1.9 compatibility regression introduced in 0.5
- documentation enhancements, specifically targetted at Windows users

0.5 (3 April 2010)

- |:CommandTFlush| now re-evaluates settings, allowing changes made via |let|
  to be picked up without having to restart Vim
- fix premature abort when scanning very deep directory hierarchies
- remove broken |<Esc>| key mapping on vt100 and xterm terminals
- provide settings for overriding default mappings
- minor performance optimization

0.4 (27 March 2010)

- add |g:CommandTMatchWindowAtTop| setting (patch from Zak Johnson)
- documentation fixes and enhancements
- internal refactoring and simplification

0.3 (24 March 2010)

- add |g:CommandTMaxHeight| setting for controlling the maximum height of the
  match window (patch from Lucas de Vries)
- fix bug where |'list'| setting might be inappropriately set after dismissing
  Command-T
- compatibility fix for different behaviour of "autoload" under Ruby 1.9.1
- avoid "highlight group not found" warning when run under a version of Vim
  that does not have syntax highlighting support
- open in split when opening normally would fail due to |'hidden'| and
  |'modified'| values

0.2 (23 March 2010)

- compatibility fixes for compilation under Ruby 1.9 series
- compatibility fixes for compilation under Ruby 1.8.5
- compatibility fixes for Windows and other non-UNIX platforms
- suppress "mapping already exists" message if <Leader>t mapping is already
  defined when plug-in is loaded
- exclude paths based on |'wildignore'| setting rather than a hardcoded
  regular expression

0.1 (22 March 2010)

- initial public release

------------------------------------------------------------------------------
vim:tw=78:ft=help:
autoload/commandt.vim	[[[1
193
" Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice,
"    this list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.

if exists("g:command_t_autoloaded") || &cp
  finish
endif
let g:command_t_autoloaded = 1

function s:CommandTRubyWarning()
  echohl WarningMsg
  echo "command-t.vim requires Vim to be compiled with Ruby support"
  echo "For more information type:  :help command-t"
  echohl none
endfunction

function commandt#CommandTShowBufferFinder()
  if has('ruby')
    ruby $command_t.show_buffer_finder
  else
    call s:CommandTRubyWarning()
  endif
endfunction

function commandt#CommandTShowFileFinder(arg)
  if has('ruby')
    ruby $command_t.show_file_finder
  else
    call s:CommandTRubyWarning()
  endif
endfunction

function commandt#CommandTShowJumpFinder()
  if has('ruby')
    ruby $command_t.show_jump_finder
  else
    call s:CommandTRubyWarning()
  endif
endfunction

function commandt#CommandTShowMRUFinder()
  if has('ruby')
    ruby $command_t.show_mru_finder
  else
    call s:CommandTRubyWarning()
  endif
endfunction

function commandt#CommandTShowTagFinder()
  if has('ruby')
    ruby $command_t.show_tag_finder
  else
    call s:CommandTRubyWarning()
  endif
endfunction

function commandt#CommandTFlush()
  if has('ruby')
    ruby $command_t.flush
  else
    call s:CommandTRubyWarning()
  endif
endfunction

if !has('ruby')
  finish
endif

function CommandTListMatches()
  ruby $command_t.list_matches
endfunction

function CommandTHandleKey(arg)
  ruby $command_t.handle_key
endfunction

function CommandTBackspace()
  ruby $command_t.backspace
endfunction

function CommandTDelete()
  ruby $command_t.delete
endfunction

function CommandTAcceptSelection()
  ruby $command_t.accept_selection
endfunction

function CommandTAcceptSelectionTab()
  ruby $command_t.accept_selection :command => 'tabe'
endfunction

function CommandTAcceptSelectionSplit()
  ruby $command_t.accept_selection :command => 'sp'
endfunction

function CommandTAcceptSelectionVSplit()
  ruby $command_t.accept_selection :command => 'vs'
endfunction

function CommandTQuickfix()
  ruby $command_t.quickfix
endfunction

function CommandTRefresh()
  ruby $command_t.refresh
endfunction

function CommandTToggleFocus()
  ruby $command_t.toggle_focus
endfunction

function CommandTCancel()
  ruby $command_t.cancel
endfunction

function CommandTSelectNext()
  ruby $command_t.select_next
endfunction

function CommandTSelectPrev()
  ruby $command_t.select_prev
endfunction

function CommandTClear()
  ruby $command_t.clear
endfunction

function CommandTCursorLeft()
  ruby $command_t.cursor_left
endfunction

function CommandTCursorRight()
  ruby $command_t.cursor_right
endfunction

function CommandTCursorEnd()
  ruby $command_t.cursor_end
endfunction

function CommandTCursorStart()
  ruby $command_t.cursor_start
endfunction

" note that we only start tracking buffers from first (autoloaded) use of Command-T
augroup CommandTMRUBuffer
  autocmd BufEnter * ruby CommandT::MRU.touch
  autocmd BufDelete * ruby CommandT::MRU.delete
augroup END

ruby << EOF
  # require Ruby files
  begin
    require 'command-t/vim'
    require 'command-t/controller'
    require 'command-t/mru'
    $command_t = CommandT::Controller.new
  rescue LoadError
    load_path_modified = false
    ::VIM::evaluate('&runtimepath').to_s.split(',').each do |path|
      lib = "#{path}/ruby"
      if !$LOAD_PATH.include?(lib) and File.exist?(lib)
        $LOAD_PATH << lib
        load_path_modified = true
      end
    end
    retry if load_path_modified

    # could get here if C extension was not compiled, or was compiled
    # for the wrong architecture or Ruby version
    require 'command-t/stub'
    $command_t = CommandT::Stub.new
  end
EOF
plugin/command-t.vim	[[[1
46
" Copyright 2010-2014 Wincent Colaiuta. All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice,
"    this list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.

if exists("g:command_t_loaded") || &cp
  finish
endif
let g:command_t_loaded = 1

command CommandTBuffer call commandt#CommandTShowBufferFinder()
command CommandTJump call commandt#CommandTShowJumpFinder()
command CommandTMRU call commandt#CommandTShowMRUFinder()
command CommandTTag call commandt#CommandTShowTagFinder()
command -nargs=? -complete=dir CommandT call commandt#CommandTShowFileFinder(<q-args>)
command CommandTFlush call commandt#CommandTFlush()

if !hasmapto(':CommandT<CR>') && maparg('<Leader>t', 'n') == ''
  silent! nnoremap <unique> <silent> <Leader>t :CommandT<CR>
endif

if !hasmapto(':CommandTBuffer<CR>') && maparg('<Leader>b', 'n') == ''
  silent! nnoremap <unique> <silent> <Leader>b :CommandTBuffer<CR>
endif

if !has('ruby')
  finish
endif
