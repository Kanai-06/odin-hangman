require 'rubocop'
require 'rubocop-performance'
require 'colorize'

class Game
  def self.start
    @possible_words = load_possible_words
    @secret_word = set_secret_word(@possible_words)

    nil unless @secret_word
  end

  private

  def load_possible_words
    dictionnary_filepath = 'google-10000-english-no-swears.txt'
    possible_words = []

    File.readlines(dictionnary_filepath).each do |word|
      possible_words.push(word) if word.length in (5..12)
    end

    possible_words
  rescue StandardError
    puts 'Error loading the dictionnary'
    nil
  end

  def set_secret_word(words)
    words[rand(words.length)]
  rescue StandardError
    puts 'Error selecting the secret word'
    nil
  end

  def get_guess
    puts 'What letter are you guessing ?'

    loop do
      begin
        gets.chomp.downcase
      rescue StandardError
        guess = ''
      end

      break if guess.length == 1

      puts 'You must guess only one letter'
    end

    guess
  end
end
