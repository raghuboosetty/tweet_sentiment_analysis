TweetAnalysis::Application.routes.draw do
  root 'welcome#index'
  
  get '/:name' => 'filter#show'
end
