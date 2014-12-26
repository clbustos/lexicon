require_relative("corpus.rb")
require_relative("dictionary.rb")
module Lexicon
  class CorpusSet
    attr_reader :corpus_set
    def initialize
      @corpus_set={}
    end
    def each_pair(&block)
      @corpus_set.each_pair(&block)
    end
    def names
      @corpus_set.keys
    end
    def [](x) 
      @corpus_set[x]
    end
    def add_corpus(nombre,corpus)
      raise "No es corpus" unless corpus.is_a? Corpus
      @corpus_set[nombre]=corpus
    end
    def palabras_unicas()
      corpus_set.map { |k,v|
        v.palabras.keys
      }.flatten.uniq.sort
    end
    def dictionary_raw
      d=Dictionary.new()
      palabras_unicas.each do |pu|
        d.add_definition(pu,pu)
      end
      d
    end
    def save_with_dictionary(d,dir)
      corpus_set.each do |k,corpus|
        corpus.transformar_con_diccionario(d).save("#{dir}/#{k}.csv")
      end
    end
    def idl(*params)
      palabras=[]
      idls={}
      @corpus_set.each do |k,c|  
        idls[k]=WordFrequency.from_corpus(c).idl(*params)
        #p c.palabras
        palabras=palabras+c.palabras.keys
      end
      palabras=palabras.uniq.sort
      
      palabras.inject({}) do |ac,palabra|
        ac[palabra]={}
        idls.each_pair {|co_n,idl|
          ac[palabra][co_n]=idl[palabra]
        }
        ac
      end
    end
    def csv_idl(file,*params)
      out=idl(*params)
      header=['palabra']+@corpus_set.keys
      c=CSV.open(file,mode="w")
      c << header
      out.each_pair do |palabra,idls|
        c<<[palabra]+@corpus_set.keys.map {|m| idls[m]}
      end
      c.close
    end
    
    def common_corpus
      c=Corpus.new
      corpus_set.each do |k,corpus|
        c.agregar_individuos(corpus.individuos)
      end
      c
      
    end
  end
end
