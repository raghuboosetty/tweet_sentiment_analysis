module SentimentData
  extend self
  
  FILE_PATH = "#{Rails.root}/config/sentiment"
  STOP_WORDS = %w(a d i w an at be do if in is it me my on of rt so to and for its the was you does that this your there)

  def slanghash
    @shash ||= load_senti_txt_file("#{FILE_PATH}/slang.txt")
  end

  def wordhash
    @whash ||= load_senti_txt_file("#{FILE_PATH}/words.txt")
  end
  
  def twittersentihash
    @tsentihash ||= load_senti_csv_file("#{FILE_PATH}/twitter_list.csv")
  end
  
  def load_senti_txt_file (filename)
    sentihash = {}
    # load the word file
    file = File.new(filename)
    while (line = file.gets)
      parsedline = line.chomp.split("\t")
      sentiscore = parsedline[0]
      text = parsedline[1]
      sentihash[text] = sentiscore.to_f
    end
    file.close
    sentihash
  end
  
  def load_senti_csv_file(filename)
    happy_log_prob = {}
    sad_log_prob = {}
    # load the word file
    file = File.new(filename)
    while (line = file.gets)
      tokens = line.chomp.split(",")
      happy_log_prob[tokens[0]] = tokens[1].to_f
      sad_log_prob[tokens[0]] = tokens[2].to_f      
    end
    file.close
    [happy_log_prob, sad_log_prob]
  end

end  