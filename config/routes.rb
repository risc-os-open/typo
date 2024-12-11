Rails.application.routes.draw do

  root 'articles#index'

  # Typo is a Rails 1 application with a lot of bespoke, non-RESTful routes
  # with an original routing file that just used "action" placeholders for an
  # allow-all. That's been a bad idea for a very long time, so this is a fully
  # rebuilt routing table created by (painful!) inspection of each and every
  # exposed action method in every controller, along with finding where and how
  # all of them are used (in particular, with respect to HTTP method).

  get  'accounts/signup', to: 'accounts#signuip' # For first-time setup initial user only
  post 'accounts/signup', to: 'accounts#signuip' #  "
  get  'accounts/login',  to: 'accounts#login'
  post 'accounts/login',  to: 'accounts#login'
  get  'accounts/logout', to: 'accounts#logout'

  namespace 'admin' do
    root 'general#index'
    get  'general/redirect', to: 'general#redirect'
    post 'general/update',   to: 'general#update'

    resources :blacklist

    resources :categories
    get 'categories/order',                to: 'categories#order'
    get 'categories/reorder',              to: 'categories#reorder'
    get 'categories/asort',                to: 'categories#asort'
    get 'categories/categories_container', to: 'categories#categories_container'

    resources :content
    post 'content/category_add',       to: 'content#category_add'
    post 'content/category_remove',    to: 'content#category_remove'
    post 'content/preview',            to: 'content#preview'
    post 'content/attachment_box_add', to: 'content#attachment_box_add'
    post 'content/attachment_save',    to: 'content#attachment_save'

    resources :feedback, only: [:index, :destroy]
    post 'feedback/bulkops', to: 'feedback#bulkops'

    resources :pages
    post 'page/preview', to: 'post#preview'

    resources :themes, only: [:index]
    get 'themes/preview/:id',  to: 'themes#preview'
    get 'themes/switchto/:id', to: 'themes#switchto'

    resources :resources, except: [:show, :create, :edit]
    put  'upload',                 to: 'resources#upload'
    post 'set_mime',               to: 'resources#set_mime'
    post 'update',                 to: 'resources#update'
    post 'upload_status',          to: 'resources#upload_status'
    post 'upload_status',          to: 'resources#upload_status'
    get  'remove_itunes_metadata', to: 'resources#remove_itunes_metadata'

    resources :sidebar, only: [:index]
    get  'sidebar/set_active', to: 'sidebar#set_active'
    get  'sidebar/remove',     to: 'sidebar#remove'
    post 'sidebar/publish',    to: 'sidebar#publish'

    resources :textfilters
    get  'textfilters/show_help' , to: 'textfilters#show_help'
    get  'textfilters/macro_help', to: 'textfilters#macro_help'
    post 'textfilters/preview',    to: 'textfilters#preview'

    resources :themes, only: [:index]
    get 'themes/preview',  to: 'themes#preview'
    get 'themes/switchto', to: 'themes#switchto'

    resources :users

    # Some admin resources only work when given an owning article ID.
    #
    resources :articles, only: [] do
      resources :comments
      resources :trackbacks
    end
  end


#   # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
#
#   # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
#   # Can be used by load balancers and uptime monitors to verify that the app is live.
#   get "up" => "rails/health#show", as: :rails_health_check
#
#   # Render dynamic PWA files from app/views/pwa/*
#   get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
#   get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
#
#   # Defines the root path route ("/")
#   # root "posts#index"
end
