# -*- coding: utf-8 -*-

require "curses"
require 'logger'
require 'facter'
require "sys/cpu"


#
# +--------- y
# |
# |
# |
# |
# x
#
class CursesWrapper

  def self.init
    @@logger = Logger::new("./test.log")
    @@logger.level = Logger::DEBUG
    
    @@default_color = Curses::COLOR_GREEN

    #Curses.crmode
    Curses.init_screen
    Curses.start_color
    Curses.curs_set(0)

    @@color_pairs = [
      Curses::COLOR_BLUE,
      Curses::COLOR_CYAN,
      Curses::COLOR_GREEN,
      Curses::COLOR_MAGENTA,
      Curses::COLOR_RED,
      Curses::COLOR_WHITE,
      Curses::COLOR_YELLOW
    ]

    @@color_pairs.each do |color|
      Curses.init_pair(color, color, Curses::COLOR_BLACK) 
    end

    @@width = Curses.cols
    @@height = Curses.lines - 1


    self.init_ascii_text
  end

  def self.draw_step(step)
    case step
    when 0
    when 1
      self.title_page
      #self.summary
    when 2
      self.show_hello
    when 3
      self.what_is_curses
    when 4
      self.what_is_curses2
    when 5
      self.kuma
    when 6
      self.animation
    when 7
      self.animation2
    when 8
      self.dashboard
    when 9
      self.summary
    when 10
      self.last_slide
    else
      self.blank
    end
  end


  # ----------------------------------------------------------------------
  # ステップ毎の処理
  # ----------------------------------------------------------------------

  def self.blank
    self.draw_text2(30, "No Slide Exists!", {place: :center})
  end

  def self.title_page
    self.draw_text2(10, "Creator's Night", {place: :center, color: Curses::COLOR_BLUE})
    self.draw_text2(30, "2012/05/25", {place: :center})
    self.draw_text2(40, "Hiroyuki Kato", {place: :center})
  end

  def self.show_hello
    self.draw_text2(5, "Today's Theme is ...", {place: :center})
    self.draw_text2(28, "Hello From curses!", {place: :center})
    self.draw_text2(50, "\(^o^)/\(^o^)/\(^o^)/", {place: :center})
  end

  def self.what_is_curses
    self.draw_text2(5, "What is curses?", {place: :center})
    self.draw_text2(30, "terminal control library", {place: :center})
    self.draw_text2(40, "    for Unix-like system.", {place: :center})
  end

  def self.what_is_curses2
    self.draw_text2(5, "What is curses?", {place: :center})
    self.draw_text2(20, "It enables", {place: :center})
    self.draw_text2(30, "the construction of", {place: :center})
    self.draw_text2(40, "text user interface (TUI)", {place: :center})
    self.draw_text2(50, "applications", {place: :center})
  end

  def self.kuma
    self.draw_ascii_art(5, 0, open('./aa/kuma.txt', 'r').read)
    self.draw_text2(50, "Ascii Art!", {place: :center})
  end

  def self.animation
    self.draw_text2(30, "(-_-)", {place: :center})

    # キー入力まで待機
    Curses.getch

    self.draw_text2(40, "Let it animate!", {place: :center})

    Curses.getch

    1.upto(100) do |i|
      Curses.attron(Curses.color_pair(@@color_pairs.sample) | Curses::A_NORMAL) {
        x = 1 + rand * (@@height - 2)
        y = 1 + rand * (@@width - 2)
        
        # 横のライン
        Curses.setpos(x, y)
        Curses.addstr("(-_-)")

        sleep 0.01
        Curses.refresh
      }
    end
  end

  def self.animation2
    1.upto(50) do |i|
      self.clear

      self.draw_ascii_art(10, 20 + i, "(- _ -)", Curses::COLOR_RED)
      self.draw_ascii_art(30, 70 - i, "(^ o ^)", Curses::COLOR_BLUE)
      self.draw_ascii_art(62 - i, 10 + i, "(・∀・) < ｲｲ!", Curses::COLOR_CYAN)
      self.draw_ascii_art(62 - i * rand, @@width - 10 - i * 2 * rand, "(´・ω・`)", Curses::COLOR_YELLOW)
      self.draw_ascii_art(30 + i * rand, @@width / 2 + i * rand, "( ´ー｀)y-~~", Curses::COLOR_RED)

      Curses.refresh

      sleep 0.1
    end
  end

  def self.dashboard
    1.upto(10) do |i|
      self.draw_text2(2, "System Dashboard", {place: :center})

      # vm_stat
      self.draw_ascii_art(12, 4, "Memory Actvity(vm_stat)", Curses::COLOR_YELLOW)
      IO.popen("vm_stat") do |io|
        io.readlines.each_with_index do |l, j|
          self.draw_ascii_art(14 + j, 4, l)
        end
      end

      # iostat
      self.draw_ascii_art(12, 64, "Disk Activity(iostat)", Curses::COLOR_YELLOW)
      IO.popen("iostat") do |io|
        io.readlines.each_with_index do |l, j|
          self.draw_ascii_art(14 + j, 64, l)
        end
      end

      # system info
      self.draw_ascii_art(12, 114, "System Information", Curses::COLOR_YELLOW)
      [
        '',
        :architecture, :kernel, :kernelrelease, :sp_os_version, :sp_machine_model,
        '',
        :sp_cpu_type, :sp_cpu_interconnect_speed, :sp_current_processor_speed,
        :sp_number_processors, :processorcount,
        :sp_l2_cache_core, :sp_l3_cache,
        '',
        :sp_physical_memory, :memorytotal, :memorysize, :memoryfree,
        :swapencrypted, :swapsize, :swapfree,
        '',
        :hostname, :fqdn,
        :sp_user_name,
        ''
      ].each_with_index do |key, j|
        if key == ''
          self.draw_ascii_art(13 + j, 114, " " * 65)
        else
          self.draw_ascii_art(13 + j, 114, sprintf("%-30s : %s", key.to_s, Facter.value(key)))
        end
      end

      # interfaces
      self.draw_ascii_art(41, 114, "Network Interfaces", Curses::COLOR_YELLOW)

      Facter.value(:interfaces).split(/,/).reject{|i|
        Facter.value(:"ipaddress_#{i}").nil?
      }.each.with_index do |interface, i|
        ip_mask = %!#{Facter.value(:"ipaddress_#{interface}")} / #{Facter.value(:"netmask_#{interface}")}!
        self.draw_ascii_art(43 + i, 114, sprintf("%10s : %s", "[#{interface}]", ip_mask))
      end

      # ----------------------------------------------------------------------

      # netstat
      self.draw_ascii_art(29, 4, "Network Activity(netstat)", Curses::COLOR_YELLOW)
      IO.popen("lsof -i | grep LISTEN ") do |io|
        io.readlines.each_with_index do |l, j|
          self.draw_ascii_art(31 + j, 4, l.strip)
        end
      end

      # CPU info
      self.draw_ascii_art(41, 4, "CPU Activity", Curses::COLOR_YELLOW)

      self.draw_ascii_art(43, 4, "Model:        " + Sys::CPU.model)
      self.draw_ascii_art(44, 4, "Version:      " + Sys::CPU::VERSION)
      self.draw_ascii_art(45, 4, "Architecture: " + Sys::CPU.architecture)
      self.draw_ascii_art(46, 4, "Machine:      " + Sys::CPU.machine)
      self.draw_ascii_art(47, 4, "Load:         " + Sys::CPU.load_avg.join(", "))

      Curses.refresh
      sleep 0.5
    end
  end

  def self.summary
    self.draw_text2(5, "Summary", {place: :center, color: Curses::COLOR_YELLOW})
    self.draw_text2(20, "- less resource", {place: :left})
    self.draw_text2(30, "- you can use variety of", {place: :left})
    self.draw_text2(40, "    ruby libraries!", {place: :left})
    self.draw_text2(50, "- write once, run anywhere", {place: :left})
  end

  def self.last_slide
    self.draw_text2(20, "\ (^ o ^) /", {place: :center, color: Curses::COLOR_YELLOW})
    self.draw_text2(30, "Thanks!", {place: :center})
  end

  def self.clear
    Curses.clear
    CursesWrapper.draw_frame
  end

  # ----------------------------------------------------------------------
  # /ステップ毎の処理
  # ----------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # 横線の描写
  # ----------------------------------------------------------------------
  def self.draw_line(x, y, width = @@width, color = @@default_color)
    Curses.attron(Curses.color_pair(color) | Curses::A_NORMAL) {
      Curses.setpos(x, y)
      Curses.addstr("-" * width)
    }
  end

  # ----------------------------------------------------------------------
  # ウィンドウのフレームの描写
  # ----------------------------------------------------------------------
  def self.draw_frame(color = @@default_color)
    Curses.attron(Curses.color_pair(color) | Curses::A_NORMAL) {
      
      # 横のライン
      Curses.setpos(0, 0)
      Curses.addstr("-" * @@width)

      Curses.setpos(@@height - 1, 0)
      Curses.addstr("-" * @@width)

      # 縦のライン
      #0.upto(@@height - 1) do |i|
      #  Curses.setpos(i, 0)
      #  Curses.addstr("|")

      #  Curses.setpos(i, @@width - 1)
      #  Curses.addstr("|")
      #end

      # 四つ角
      Curses.setpos(0, 0)
      Curses.addstr("+")

      Curses.setpos(0, @@width - 1)
      Curses.addstr("+")

      Curses.setpos(@@height - 1, 0)
      Curses.addstr("+")

      Curses.setpos(@@height - 1, @@width - 1)
      Curses.addstr("+")
    }
  end

  # ----------------------------------------------------------------------
  # 徐々に消える（全部消えないというオチ）
  # ----------------------------------------------------------------------
  def self.dissolve
    1.upto(100) do |i|
      Curses.setpos(rand * @@height, rand * @@width)
      Curses.addstr ' '
      #sleep 0.1
    end
  end

  # ----------------------------------------------------------------------
  # テキストをAAを使って描写（半角英数字に限る）
  # ----------------------------------------------------------------------
  def self.draw_text2(x, str, options)
    color = options[:color] || @@default_color

    str_len = 0
    str.each_char.with_index do |c, i|
      str_len += @@ascii[c.bytes.to_a[0]][:width]
    end

    placement = options[:place] || :center

    y = case placement
        when :center
          (@@width - str_len) / 2
        when :left
          2
        when :right
          (@@width - str_len) - 2
        end
    self.draw_text_innner(x, y, str, color)
  end

  # ----------------------------------------------------------------------
  # 終了処理
  # ----------------------------------------------------------------------
  def self.finish
    Curses.getch
    Curses.close_screen
  end

  # ----------------------------------------------------------------------
  # ウィンドウの幅を取得
  # ----------------------------------------------------------------------
  def self.width
    @@width
  end

  # ----------------------------------------------------------------------
  # ウィンドウの高さを取得
  # ----------------------------------------------------------------------
  def self.height
    @@height
  end


  private


  # ----------------------------------------------------------------------
  # アスキーアートをそのまま出力
  # 左右のマージンは一行目がずれるのでテキストデータ自体に入れること
  # ----------------------------------------------------------------------
  def self.draw_ascii_art(x, y, str, color = @@default_color)
    Curses.attron(Curses.color_pair(color) | Curses::A_NORMAL) {
      Curses.setpos(x, y)
      Curses.addstr(str)
    }
  end

  # ----------------------------------------------------------------------
  # 各半角英数字用のデータから文字列を1つずつ描写
  # ----------------------------------------------------------------------
  def self.draw_text_innner(x, y, str, color)
    cur_y = y

    Curses.attron(Curses.color_pair(color) | Curses::A_NORMAL) {
      str.each_char.with_index do |c, i|
        txt = @@ascii[c.bytes.to_a[0]]
        txt[:text].each.with_index do |l, i|
          Curses.setpos(x + i, cur_y)
          Curses.addstr(l)
        end

        cur_y += txt[:width]
      end
    }
  end

  # ----------------------------------------------------------------------
  # 半角文字列とAA文字列のマッピングデータの初期化
  # ----------------------------------------------------------------------
  def self.init_ascii_text
    lines = []

    # 空白文字はデータに入っていないので自分で作る
    @@ascii = {
      32 => {
        text: ["   \n"] * 8,
        width: 3
      }
    }
    pos = 0
    ascii_code = 31
    
    open('./aa/ascii.txt', 'r').each do |l|
      lines << l
    end
    
    lines[0].each_char.with_index do |c, i|
      if lines.map{|l| l[i] == ' '}.inject(true) {|res, v| res &&= v}
        ascii_code += 1
        txt_width = i - pos + 1

        unless ascii_code == 32
          @@ascii[ascii_code] = {
            text: lines.map{|l| l[pos .. i] },
            width: txt_width
          }
        end

        pos = i
      end
    end
  end
end


CursesWrapper.init

i = 0
step = 0


# ----------------------------------------------------------------------
# メインルーチン
# ----------------------------------------------------------------------
while c = Curses::stdscr.getch
  Curses.clear

  # 入力キー毎に処理
  case c
  when 127  # Backspace
    step -= 1
  when 10   # Enter
    step += 1
  when 32   # Space
  when 27   # ESC
    exit
  else
  end

  # デバッグ用の入力キーとステップ番号を出力
  #CursesWrapper.draw_text2(56, "Key: #{c}, Step: #{step}", {place: :right})
  #CursesWrapper.draw_text2(56, "step: #{step}", {place: :right})

  # 最後にウィンドウのフレームを出力
  CursesWrapper.draw_frame

  # ステップ毎の描写用関数を呼び出し
  CursesWrapper.draw_step(step)
end

# 終了処理
CursesWrapper.finish

