class FilterController < ApplicationController
  def show
    @name = params[:name]
    # twitter name validator
    # only numerical, alphabets, underscores
    if !(@name =~ /^([a-z0-9_?])+$/i).nil?
      begin
        
        # FIXME: remove client instance
        # used to differentiate the local Twitter module 
        # and Twitter gem class
        @client = client
        
        @user = Twitter.user(@name)
        @user_timeline = Twitter.user_timeline(@name, {contributor_details: true, count: 150})
      rescue Twitter::Error => e
        flash.alert = e.message
        redirect_to :root
      end
    else
      flash.now.alert = "Invalid Username"
    end
  end
  
  def client
    @client ||= Twitter::Client.new
  end
end
