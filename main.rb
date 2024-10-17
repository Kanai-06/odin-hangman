require 'rubocop'
require 'rubocop-performance'
require 'colorize'

class Game
  def start
    setup_game
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

      if guess.length != 1
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
    puts ''

    if @guess_output == @secret_word
      puts "You #{'won'.colorize(mode: :bold)} ! The secret word was #{@secret_word}"
    else
      puts "You #{'lost'.colorize(mode: :bold)} ;-; The secret word was #{@secret_word}"
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
    system 'clear'

    puts "Guess #{@guess_iteration}".colorize(mode: :underline)
    puts "Errors #{@guesses[:wrong].length}/10"
    puts ''
    puts "Word to guess : #{@guess_output.colorize(mode: :bold)}"
    puts ''
    puts "Right guesses : #{@guesses[:right].map { |guess| guess.colorize(color: :green) }.join(', ')}\t
Wrong guesses : #{@guesses[:wrong].map { |guess| guess.colorize(color: :red) }.join(', ')}"
    puts ''
  end

  def game_loop
    while @guesses[:wrong].length <= 10
      print_information

      @guess = get_guess

      set_guess_category

      @guess_output = set_guess_output

      @guess_iteration += 1

      break if game_finished?
    end
  end

  def play_saved_game?
    puts 'Do you want to play your last saved game ? [Y/N]'
    puts ''
    puts "You can save your game at any time by typing #{'save'.colorize(mode: :bold)} instead of a guess"

    begin
      if (user_input = gets.chomp.downcase) == 'y'

      elsif user_input == 'n'

      else
        puts ''
      end
    rescue StandardError
    end
  end
end

Game.new.start
