require 'rubocop'
require 'rubocop-performance'
require 'colorize'
require 'json'
require 'openssl'

class String
  def encrypt(key)
    cipher = OpenSSL::Cipher.new('DES-EDE3-CBC').encrypt
    cipher.key = Digest::SHA1.hexdigest(key)[0..23]
    s = cipher.update(self) + cipher.final

    s.unpack1('H*').upcase
  end

  def decrypt(key)
    cipher = OpenSSL::Cipher.new('DES-EDE3-CBC').decrypt
    cipher.key = Digest::SHA1.hexdigest(key)[0..23]
    s = [self].pack('H*').unpack('C*').pack('c*')

    cipher.update(s) + cipher.final
  end
end

class Game
  def start
    if play_saved_game?
      load_saved_game
    else
      setup_game
    end

    game_loop
  end

  private

  def setup_game
    @possible_words = load_possible_words
    @secret_word = set_secret_word
    @guess_output = '_' * @secret_word.length

    return unless @secret_word

    @guesses = { right: [], wrong: [] }
    @guess_iteration = 1
  end

  def load_possible_words
    dictionnary_filepath = 'google-10000-english-no-swears.txt'
    words = []

    File.readlines(dictionnary_filepath).each do |word|
      clean_word = word.delete("\n")
      words.push(clean_word) if clean_word.length in (5..12)
    end

    words
  rescue StandardError
    puts 'Error loading the dictionnary'
    nil
  end

  def set_secret_word
    @possible_words[rand(@possible_words.length)]
  rescue StandardError
    puts 'Error selecting the secret word'
    nil
  end

  def get_guess
    puts 'What letter are you guessing ?'
    guess = ''

    loop do
      begin
        guess = gets.chomp.downcase
      rescue StandardError
        guess = ''
      end

      if guess == 'save'
        save_game
        break
      elsif guess.length != 1
        puts 'Guess must be only one letter'
      elsif @guesses[:right].include?(guess) || @guesses[:wrong].include?(guess)
        puts 'You already guessed this letter'
      else
        break
      end
    end

    guess
  end

  def game_finished?
    if @guess_output == @secret_word
      print_information
      puts ''
      puts "You #{'won'.colorize(mode: :bold)} ! The secret word was #{@secret_word.colorize(mode: :bold)}"
    elsif @guess_output != @secret_word && @guesses[:wrong].length >= 10
      print_information
      puts ''
      puts "You #{'lost'.colorize(mode: :bold)} ;-; The secret word was #{@secret_word.colorize(mode: :bold)}"
    end

    @guess_output == @secret_word
  end

  def set_guess_output
    @secret_word.chars.map { |char| @guesses[:right].include?(char) ? char : '_' }.join
  end

  def set_guess_category
    if @secret_word.include?(@guess)
      @guesses[:right].push(@guess)
    else
      @guesses[:wrong].push(@guess)
    end
  end

  def print_information
    puts "Guess #{@guess_iteration}".colorize(mode: :underline)

    puts ''
    puts "Word to guess : #{@guess_output.colorize(mode: :bold)}"
    puts ''
    puts "Right guesses : #{@guesses[:right].map { |guess| guess.colorize(color: :green) }.join(', ')}\t
Wrong guesses : #{@guesses[:wrong].map { |guess| guess.colorize(color: :red) }.join(', ')}"
    puts ''
    puts "Errors #{"#{@guesses[:wrong].length}/10".colorize(mode: :bold)}"
    puts ''
  end

  def game_loop
    while @guesses[:wrong].length < 10
      print_information

      @guess = get_guess

      break if @saved_game

      set_guess_category

      @guess_output = set_guess_output

      @guess_iteration += 1

      system 'clear'

      break if game_finished?
    end
  end

  def play_saved_game?
    system 'clear'

    puts "You can save your game at any time by typing #{'save'.colorize(mode: :bold)} instead of a guess"
    puts ''
    puts 'Do you want to play your last saved game ? [Y/N]'
    user_input = ''

    loop do
      begin
        user_input = gets.chomp.downcase
      rescue StandardError
        user_input = ''
      end

      break if %w[y n].include?(user_input)

      puts 'Input must be Y or N'
    end

    if user_input == 'y' && !File.exist?('saved_game.json')
      puts 'No existing saved game file'

      delay = Time.now + 5
      while Time.now < delay
      end
    end

    system 'clear'

    user_input == 'y' && File.exist?('saved_game.json')
  end

  def load_saved_game
    saved_game_file = File.read('saved_game.json')
    data = JSON.parse(saved_game_file)

    @secret_word = data['secret_word'].decrypt('8morts6blesses')
    @guesses = {}
    @guesses[:right] = data['guesses']['right']
    @guesses[:wrong] = data['guesses']['wrong']
    @guess_iteration = data['guess_iteration']
    @guess_output = data['guess_output']
  end

  def save_game
    data = JSON.dump({
                       secret_word: @secret_word.encrypt('8morts6blesses'),
                       guesses: @guesses,
                       guess_iteration: @guess_iteration,
                       guess_output: @guess_output
                     })

    File.write('saved_game.json', data)
    puts 'Game saved'
    @saved_game = true
  end
end

Game.new.start
