Rails.application.routes.draw do

  root 'articles#index'

  # Typo is a Rails 1 application with a lot of bespoke, non-RESTful routes
  # with an original routing file that just used "action" placeholders for an
  # allow-all. That's been a bad idea for a very long time, so this is a fully
  # rebuilt routing table created by (painful!) inspection of each and every
  # exposed action method in every controller, along with finding where and how
  # all of them are used (in particular, with respect to HTTP method).

  get  'accounts/signup', to: 'accounts#signup' # For first-time setup initial user only
  post 'accounts/signup', to: 'accounts#signup' #  "
  get  'accounts/login',  to: 'accounts#login'
  post 'accounts/login',  to: 'accounts#login'
  get  'accounts/logout', to: 'accounts#logout'

  namespace 'admin' do
    root 'general#index'
    get  'general/redirect', to: 'general#redirect'
    post 'general/update',   to: 'general#update'

    resources :blacklist

    get 'categories/order',                to: 'categories#order'
    get 'categories/reorder',              to: 'categories#reorder'
    get 'categories/asort',                to: 'categories#asort'
    get 'categories/categories_container', to: 'categories#categories_container'
    resources :categories

    post 'content/category_add',       to: 'content#category_add'
    post 'content/category_remove',    to: 'content#category_remove'
    post 'content/attachment_box_add', to: 'content#attachment_box_add'
    post 'content/attachment_save',    to: 'content#attachment_save'
    put  'content/preview',            to: 'content#preview'
    resources :content

    post 'feedback/bulkops', to: 'feedback#bulkops'
    resources :feedback, only: [:index, :destroy]

    post 'page/preview', to: 'post#preview'
    resources :pages

    get 'themes/preview/:id',  to: 'themes#preview'
    get 'themes/switchto/:id', to: 'themes#switchto'
    resources :themes, only: [:index]

    put  'resources/upload',                 to: 'resources#upload'
    post 'resources/set_mime',               to: 'resources#set_mime'
    post 'resources/update',                 to: 'resources#update'
    post 'resources/upload_status',          to: 'resources#upload_status'
    post 'resources/upload_status',          to: 'resources#upload_status'
    get  'resources/remove_itunes_metadata', to: 'resources#remove_itunes_metadata'
    resources :resources, except: [:show, :create, :edit]

    get  'sidebar/set_active', to: 'sidebar#set_active'
    get  'sidebar/remove',     to: 'sidebar#remove'
    post 'sidebar/publish',    to: 'sidebar#publish'
    resources :sidebar, only: [:index]

    get  'textfilters/show_help' , to: 'textfilters#show_help'
    get  'textfilters/macro_help', to: 'textfilters#macro_help'
    post 'textfilters/preview',    to: 'textfilters#preview'
    resources :textfilters

    get 'themes/preview',  to: 'themes#preview'
    get 'themes/switchto', to: 'themes#switchto'
    resources :themes, only: [:index]

    resources :users

    # Some admin resources only work when given an owning article ID.
    #
    resources :articles, only: [:index] do
      resources :comments
      resources :trackbacks
    end
  end

  # get  'articles/:year/:month/:day/:title',     to: 'articles#permalink', as: 'article_permalink'
  # get  'articles/:year/:month/:day/page/:page', to: 'articles#find_by_date'
  # get  'articles/:year/:month/page/:page',      to: 'articles#find_by_date'
  # get  'articles/:year/page/:page',             to: 'articles#find_by_date'
  # get  'articles/:year/:month/:day',            to: 'articles#find_by_date'
  # get  'articles/:year/:month',                 to: 'articles#find_by_date'
  # get  'articles/:year',                        to: 'articles#find_by_date'
  #
  get  'articles/archives',                     to: 'articles#archives'
  get  'articles/search',                       to: 'articles#search'
  get  'articles/author(/:id)',                 to: 'articles#author'
  get  'articles/category(/:id)',               to: 'articles#category'
  get  'articles/tag(/:id)',                    to: 'articles#tag'
  get  'articles/read/:id',                     to: 'articles#read'
  get  'articles/read_and_comment/:id',         to: 'articles#read_and_comment'
  get  'articles/markup_help/:id',              to: 'articles#markup_help'
  get  'articles/trackback/:id',                to: 'articles#trackback'
  #
  get  'pages/:name',                           to: 'articles#view_page' # (sic.)
  #
  post 'articles/comment_preview',              to: 'articles#comment_preview'
  post 'articles/comment',                      to: 'articles#comment'
  post 'articles/nuke_comment',                 to: 'articles#nuke_comment'
  post 'articles/nuke_trackback',               to: 'articles#nuke_trackback'
  #
  resources :articles, only: [:index]

  get 'live#search', to: 'live#search'

  get 'plugins/filters/:filter/:public_action', to: 'textfilter#public_action'

  get 'sitemap.xml', to: 'xml#feel', defaults: { type: 'sitemap', format: 'googlesitemap' }

  get 'stylesheets/theme/:filename', to: 'stylesheets#theme'

  get 'xml/:format/:type/:id/feed.xml', to: 'xml#feed'
  get 'xml/:format/:type/feed.xml',     to: 'xml#feed'
  get 'xml/:format/feed.xml',           to: 'xml#feed', defaults: { type: 'feed' }
  get 'xml/rss',                        to: 'xml#feed', defaults: { type: 'feed', format: 'rss' }
  get 'xml/rsd',                        to: 'xml#rsd',  defaults: { type: 'application/rsd+xml', format: 'xml' }
  get 'xml/articlerss/:id/feed.xml',    to: 'xml#articlerss'
  get 'xml/commentrss/feed.xml',        to: 'xml#commentrss'
  get 'xml/trackbackrss/feed.xml',      to: 'xml#trackbackrss'
  get 'xml/itunes/feed.xml',            to: 'xml#itunes'
end
