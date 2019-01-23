class WelcomeController < ApplicationController
  def index
    # Stop after collecting 10 statuses
    @statuses = []
    # stream_client.sample do |status, client|
    #   @statuses << status
    #   client.stop if @statuses.size >= 10
    # end    
    # stream_client.filter({follow: ["18215980","92445633","71282191"]}) do |status, client|
    #   @statuses << status
    #   client.stop if @statuses.size >= 5
    # end
  end
  
  def stream_client
    @stream_client = TweetStream::Client.new
  end  
end
