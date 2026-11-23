Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/events", status: 302)

  resource :session, only: [:new, :create, :destroy]

  resources :events, except: :show
  resource :current_day, only: :show, path: "current-day"
  resources :characters, except: :show
  resources :groups, except: :show
  resource :summary, only: :show
  resource :settings, only: [:show, :update]

  # Ids take any text, so that a malformed one gets the API's own error.
  segment = %r{[^/]+}
  scope "/api", module: "api", as: "api", format: false,
                constraints: { id: segment, group_id: segment, character_id: segment } do
    get "settings", to: "settings#show"
    put "settings", to: "settings#update"
    get "summary", to: "summaries#show"

    put "characters/bulk", to: "bulk_characters#update"
    get "characters/placeholders", to: "characters#placeholders"
    get "characters/:id/events", to: "characters#events"
    post "characters/:id/groups", to: "character_groups#create"
    delete "characters/:id/groups/:group_id", to: "character_groups#destroy"
    post "events/:id/characters", to: "event_characters#create"
    delete "events/:id/characters/:character_id", to: "event_characters#destroy"

    %w[groups characters events].each do |name|
      get name, to: "#{name}#index"
      post name, to: "#{name}#create"
      get "#{name}/:id", to: "#{name}#show"
      put "#{name}/:id", to: "#{name}#update"
      delete "#{name}/:id", to: "#{name}#destroy"
    end
  end
end
