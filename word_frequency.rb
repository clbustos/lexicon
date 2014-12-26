module Lexicon
  class WordFrequency
    attr_reader :words
    def initialize(w={})
      @words=w
    end
    def self.load_csv(file)
      words={}
      csv=CSV.foreach(file) do |linea|
        word=linea.shift
        #p linea
        words[word]=linea.map {|f| f.to_i}
      end
      WordFrequency.new(words)
    end
    def self.from_corpus(c)
      WordFrequency.new(c.palabras_orden)
    end
    def replace_words(w)
      @words=w
    end
    # Calculo de IDL normal
    # Metodo:
    # * :lexmath = sum lambda^(i-1)x_pi, donde x_pi=\frac{f_pi}{N_1}
    # * :lopez  =  sum lambda^(i-1)x_pi, donde x_pi=\frac{f_pi}{N_i}
    # * :butron =  sum lambda^(i-1)x_pi, donde x_pi=\frac{f_pi}{N_{i-1}}
    def idl(metodo=:lexmath, lambda=0.9)
      return(idl_strass) if metodo==:strass
      cpp=cuenta_por_posicion
      n=cpp.length # Maxima posicion alcanzada
      if metodo==:lopez
        factor=n.times.map {|i|
            lambda**i / cpp[i]
        }
      elsif metodo==:butron
        factor=n.times.map {|i|
          if i==0
            lambda**i / cpp[0]
          else
            lambda**i / cpp[i-1]
          end
        }
      elsif metodo==:lexmath
        factor=n.times.map {|i|
            lambda**i / cpp[0]
        }
      else
        raise "No existe metodo"
      end
      
      words.inject({}) {|ac,palabra_v|
        palabra=palabra_v[0]
        cuentas=palabra_v[1]
        ac[palabra]=n.times.map {|i|
          p cuentas[i]*factor[i]
          cuentas[i]*factor[i]
        }.inject(0) {|ac,v| ac+v}
        ac
      }
    end
    # Refiere a la cantidad maxima de respuestas que se da en alguna respuesta
    def max_position
      @words.first[1].length
    end
    def word_number
      @words.length
    end
    def people_number
      @words.inject(0) {|ac,v|
        ac+v[1][0]
      }
    end
    def idl_strass(fe=-2.3)
      n=max_position
      pn=people_number
      @words.inject({}) {|ac,v|
        word=v[0]
        count=v[1]
        ac[word] = (0...n).map {|i|
          Math.exp(fe*(i/(n.to_f-1))) * count[i]/pn.to_f
        }.inject(0) {|ac,v2| ac+v2}
        ac
      }
    end
    
    def cuenta_por_posicion
      nd=@words.first[1].length
      cp=Array.new(nd,0)
      
      @words.each do |word,freq|
        (0...nd).each do |i|
          cp[i]=cp[i]+freq[i]
        
        end
      end
      cp
    end
  end
end
