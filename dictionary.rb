# Genera un diccionario de valores
# Los originales se transforman en el conjunto de las palabras que aparecen después.
module Lexicon
  class Dictionary
    attr_reader :words
    def initialize
      @words={}
    end
    def[](w)
      @words[w]
    end
    def add_definition(original,values)
      values=[values] unless values.is_a? Array
      @words[original]=values
    end
    def self.load(file)
      d=Dictionary.new
      csv=CSV.foreach(file) do |linea|
        d.add_definition(linea[0],linea[1,linea.length-1].select {|v| !v.nil?})
      end
      d
    end
    # Add missing words to currect dictionary
    def add_missing!(d)
      (d.words.keys-@words.keys).each do |new_word|
        p new_word
        add_definition(new_word,d.words[new_word])
      end
    end
    def save(file)
      c=CSV.open(file,mode="w")
      @words.sort.each do |k,v|
        c << [k]+v
      end
      c.close
    end
  end
end
