require("csv")
require_relative("word_frequency")
# Permite comparar corpus entre dos personas
module Lexicon
  class Corpus
    # Array con las respuestas por individuo
    attr_accessor :individuos
    
    def initialize
      @individuos=[]
      reset
    end
    # Pone a cero todos las cuentas calculadas al hacer contar_palabra()
    def reset
      @palabras=nil
      @palabras_orden=nil
      @maxima_posicion=0
      @cuenta_por_posicion=[]
    end
    # Crea una matriz de adyacencia, que puede
    # ser dirigida o no dirigida
    # @param directed Si es dirigido (duh)
    # @param base_word Si tiene una palabra base, que antecede a todo
    # @param type_miles El tipo:
    #        :word = cada palabra se une a todos las subsiguientes, en cada individuo
    #        :subject    = cada palabra se une solo a la consecutiva 
    def adjacency_matrix(directed=true,base_word=nil, type_miles=:subject)
      require("matrix")
      contar_palabras
      word_names=@palabras.keys.dup
      word_names.push(base_word) if base_word
      word_names.sort!
      m=word_names.map {|i| [0]*word_names.length}
      @individuos.each do |ind|
        ind2=ind.dup
        
        ind2.unshift base_word  if base_word
        next if ind2.length==1
        # Parte con las palabras en orden
        (0...(ind2.length-1)).each do |i|
          wi=word_names.index(ind2[i])
          # y sigue con todas las demás que siguen hacia adelante, si es :subject
          # o solo a la siguiente, si es :word
          until_word=case type_miles
          when :word # Se unen todas las palabras
            ind2.length-1
          when :subject # Se une solo a la siguiente
            i+1
          end
          ((i+1)..until_word).each do |j|
            wj=word_names.index(ind2[j])
            m[wi][wj] = m[wi][wj]+1
            m[wj][wi] = m[wj][wi]+1 unless directed
          end
        end
      end
      {:matrix=>m,:words=>word_names}
    end
    
    # Agrega las respuestas de un individuo 
    # @param i array con respuestas del individuo
    # @param r boolean resetea la cuenta tras agregar un individuo 
    def agregar_individuos(i,r=true)
      @individuos+=i
      reset if r
    end
    def agregar_individuo(ind,r=true)
      @individuos.push(ind)
      reset if r
    end
    # Entrega un nuevo Corpus, en el cual todas las palabras
    # son transformadas de acuerdo a un Dictionary
    # @param Dictionary
    # @return Corpus un nuevo corpus, con las palabras cambiadas de acuerdo al diccionario
    def transformar_con_diccionario(d)
      raise "No es diccionario" unless d.is_a? Dictionary
      new_individuos=[]
      individuos.each do |ind|
        cache=[]
        new_ind=[]
        ind.each do |word|
          raise "Palabra #{word} no está en diccionario" if d[word].nil?
          nw=d[word]-cache
          #p cache
          next if nw.length==0
          new_ind+=nw
          cache+=nw
        end
        new_individuos.push(new_ind)
      end
      nc=Corpus.new
      nc.individuos=new_individuos
      nc
    end

    # Entrega un hash, donde la clave es la palabra
    # y el valor es un array, con el número de veces que aparece en una determinada posición
    # en el corpus.
    def cuenta_por_posicion
      contar_palabras 
      @cuenta_por_posicion
    end
    # Carga un archivo csv, con un diccionario
    def self.load(file)
      individuos=[]
      csv=CSV.foreach(file) do |linea|
        individuos.push(linea.find_all {|f| !f.nil?})
      end
      c=Corpus.new()
      c.individuos=individuos
      c
    end
    def palabras_orden
      contar_palabras
      @palabras_orden
    end
    def comparar_idl(file)
      idl1=idl(0.9,:lexmath)
      idl2=idl_strass
      
      c=CSV.open(file,mode="w")
      c<<["lopez","strass"]
      idl1.each_pair do |palabra,valor|
        c<<[palabra,valor,idl2[palabra]]
      end
        c.close
    end
    # Crea un array con los indviduos
    # para realizar análisis de supervivencia 
    # del núcleo o de otra palabra
    # con un hash por individuo con 
    # * :cuenta=> numero ocurrencia del fenómeno
    # * :observado=> si se observó en cuenta o está censurado
    # 
    # @param origen= La palabra de origen del análisis. 
    #                Si es nil, se parte desde el origen 
    # el resultado es nil si la palabra nunca es dicha
    def supervivencia(palabra, origen=nil)
      @individuos.map {|individuo|
        total=individuo.length
        final =individuo.rindex(palabra)
        if origen
          inicio=individuo.find_index(origen)
          if inicio.nil? or (final and final-inicio<0)
            nil
          else
            (final.nil? ?  {:cuenta=>total-inicio-1, :observado=>false} : {:cuenta=>(final-inicio), :observado=>true }  ) 
          end
        else
          final.nil?  ?  {:cuenta=>total, :observado=>false} : {:cuenta=>final+1, :observado=>true}
        end
      }  
    end
    # Se genera una matriz de individuos x palabras
    # Cada fila es un individuo
    # y cada columna una palabra. 
    # El número indica el orden en que la palabra aparece en el 
    # individuo
    def matriz_individuo_palabra
      
      base_palabras=palabras.keys.inject({}) {|ac,v| ac[v]=nil;ac}
      @individuos.map {|ind| 
        pp=base_palabras.dup
        ind.each_with_index {|pal,i|
          pp[pal]=i+1
        }
        pp
      }
    end
    def csv_matrix_individuo_palabra(file)
      c=CSV.open(file,mode="w")
      c<<["individuo"]+palabras.keys
      matriz_individuo_palabra.each_with_index do |ind,i|
        c << [i+1]+@palabras.keys.map {|pal|
          ind[pal]
        }
      end
      c.close
    end
    # Escribe el csv para el análisis de supervivencia
    def csv_supervivencia(file) 
      c=CSV.open(file,mode="w")
      c<<["palabra","sujeto","cuenta","observado"]
      palabras.each_key do |palabra|
        supervivencia(palabra).each_with_index do |s,i|
          p s
          if s.nil?
            c << [palabra,i+1,"NA","NA"]
          else
            c << [palabra,i+1,s[:cuenta], s[:observado] ? 1 : 0 ]
          end
        end
      end
      c.close

    end
    
    def contar_palabras
    @palabras_orden={}
    @palabras={}
    @cuenta_por_posicion=[]
    max_i=0
      @individuos.each do |individuo|
        individuo.each_with_index do |palabra,palabra_i|
          @cuenta_por_posicion[palabra_i]||=0
          @cuenta_por_posicion[palabra_i]+=1
          max_i=palabra_i unless palabra_i<=max_i
          @palabras_orden[palabra]||=[]
          @palabras_orden[palabra][palabra_i]||=0
          @palabras_orden[palabra][palabra_i]+=1
          @palabras[palabra]||=0
          @palabras[palabra]+=1
        end
      end
      @maxima_posicion=max_i
      0.upto(max_i) {|i|
        @palabras_orden.each_key {|k|
            @palabras_orden[k][i]||=0
        }
      }
      @palabras
    end
    
    def palabras
      @palabras||=contar_palabras
    end
    def escribir_conteo(file)
      c=CSV.open(file,mode="w")
      c<<["palabra","n"]
      palabras.each do |v|
        c<<[v[0],v[1]]
      end
      c.close
    end
    def save(file)
      c=CSV.open(file,mode="w")
      @individuos.each do |i|
        c << i
      end
      c.close
    end
    
    # Escribe un csv en el cual cada palabra 
    def escribir_grafo(file,antecedente=nil)
      c=CSV.open(file,mode="w")

      @individuos.each do |individuo|
        previa=nil
        individuo.each do |palabra|
          c<<[antecedente,palabra] unless antecedente.nil?
          unless previa.nil?
            c<<[previa,palabra]
          end
            previa=palabra
        end
      end
      c.close
    end
  end
end
